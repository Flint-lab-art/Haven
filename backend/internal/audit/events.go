package audit

import (
	"fmt"
	"strings"
)

// 事件定义表：把 audit.md 第三节的清单变成可校验的结构。
//
// 每个 event_type 只允许一组固定的 target_type 与 metadata 键。
// 写入前用 Validate 校验，避免手写 map 时拼错键名或塞进敏感字段
// （audit.md 第二节规则 5：不记录笔记内容、密码、Token 明文、TOTP secret）。

// targetTypes 是 audit_events.target_type 的合法取值（audit.md 第三节说明）。
var targetTypes = map[string]struct{}{
	TargetNull:          {},
	TargetUser:          {},
	TargetSession:       {},
	TargetTrustedDevice: {},
	TargetToken:         {},
	TargetNote:          {},
}

// eventSpec 描述一个事件类型的合法形状。
type eventSpec struct {
	// targetType 是必须使用的 target_type；为空表示必须是 'null'。
	targetType string
	// metadataKeys 是允许出现的 metadata 键；nil 表示必须为空对象。
	metadataKeys []string
	// requireTargetID 表示 target_id 必须非空。
	requireTargetID bool
}

// specs 与 audit.md 第三节表格逐行对应。
var specs = map[string]eventSpec{
	EventLoginSuccess: {
		targetType:   TargetNull,
		metadataKeys: []string{"via"},
	},
	EventLoginFailure: {
		targetType:   TargetNull,
		metadataKeys: []string{"reason"},
	},
	EventLogout: {
		targetType: TargetNull,
	},
	EventTotpBound: {
		targetType:      TargetUser,
		requireTargetID: true,
	},
	EventTotpDisabled: {
		targetType:      TargetUser,
		requireTargetID: true,
	},
	EventPasswordChanged: {
		targetType:      TargetUser,
		requireTargetID: true,
	},
	EventSessionRevoked: {
		targetType:      TargetSession,
		metadataKeys:    []string{"session_created_at"},
		requireTargetID: true,
	},
	EventTrustedDeviceAdded: {
		targetType:   TargetTrustedDevice,
		metadataKeys: []string{"device_name"},
	},
	EventTrustedDeviceRevoke: {
		targetType:   TargetTrustedDevice,
		metadataKeys: []string{"device_name"},
	},
	EventTokenCreated: {
		targetType:   TargetToken,
		metadataKeys: []string{"name", "scope", "token_prefix"},
	},
	EventTokenRevoked: {
		targetType:   TargetToken,
		metadataKeys: []string{"name", "token_prefix"},
	},
	EventNotePublished: {
		targetType:      TargetNote,
		metadataKeys:    []string{"title"},
		requireTargetID: true,
	},
	EventNoteUnpublished: {
		targetType:      TargetNote,
		metadataKeys:    []string{"title"},
		requireTargetID: true,
	},
}

// 已知的 metadata 取值约束（audit.md 第三节）。
var (
	loginViaValues    = []string{"password+totp", "password+trusted_device"}
	loginReasonValues = []string{ReasonBadPassword, ReasonBadTotp, ReasonNoSuchUser}
	tokenScopeValues  = []string{"read", "read_write"}
)

// EventTypes 返回全部合法事件类型，供测试与自检使用。
func EventTypes() []string {
	out := make([]string, 0, len(specs))
	for k := range specs {
		out = append(out, k)
	}
	return out
}

// Validate 校验一条事件是否符合 audit.md 第三节的清单。
//
// 不校验数据库层能兜住的东西（如 event_type 的 CHECK），而是校验
// 「metadata 键名对不对、target_type 对不对、有没有多余的敏感字段」。
func Validate(e Event) error {
	spec, ok := specs[e.EventType]
	if !ok {
		return fmt.Errorf("未定义的审计事件类型 %q", e.EventType)
	}

	gotTarget := e.TargetType
	if gotTarget == "" {
		gotTarget = TargetNull
	}
	if _, ok := targetTypes[gotTarget]; !ok {
		return fmt.Errorf("事件 %s 的 target_type %q 不合法", e.EventType, gotTarget)
	}
	if gotTarget != spec.targetType {
		return fmt.Errorf("事件 %s 的 target_type 应为 %q，实际 %q", e.EventType, spec.targetType, gotTarget)
	}
	if spec.requireTargetID && e.TargetID == "" {
		return fmt.Errorf("事件 %s 缺少 target_id", e.EventType)
	}

	for k := range e.Metadata {
		if !contains(spec.metadataKeys, k) {
			return fmt.Errorf("事件 %s 不允许 metadata 键 %q", e.EventType, k)
		}
	}

	// 取值约束
	switch e.EventType {
	case EventLoginSuccess:
		if v, _ := e.Metadata["via"].(string); !contains(loginViaValues, v) {
			return fmt.Errorf("login_success 的 via %q 不合法", v)
		}
	case EventLoginFailure:
		if v, _ := e.Metadata["reason"].(string); !contains(loginReasonValues, v) {
			return fmt.Errorf("login_failure 的 reason %q 不合法", v)
		}
	case EventTokenCreated:
		if v, _ := e.Metadata["scope"].(string); !contains(tokenScopeValues, v) {
			return fmt.Errorf("token_created 的 scope %q 不合法", v)
		}
	}

	return nil
}

func contains(list []string, v string) bool {
	for _, item := range list {
		if item == v {
			return true
		}
	}
	return false
}

// Redact 返回适合写进日志的事件描述：把可能敏感的 metadata 值截断，
// 并且绝不包含密码、Token 明文、TOTP secret 等字段（audit.md 5.1 要求日志里
// 记录完整事件内容以便人工补录，但不意味着可以记录敏感值）。
func Redact(e Event) string {
	var b strings.Builder
	fmt.Fprintf(&b, "event_type=%s actor_username=%q target_type=%s target_id=%s",
		e.EventType, e.ActorUsername, e.TargetType, e.TargetID)
	if len(e.Metadata) > 0 {
		b.WriteString(" metadata=")
		for k, v := range e.Metadata {
			switch k {
			case "token", "password", "totp_secret", "secret":
				b.WriteString(k + "=<redacted> ")
			default:
				fmt.Fprintf(&b, "%s=%v ", k, v)
			}
		}
	}
	return b.String()
}
