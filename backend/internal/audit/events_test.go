package audit

import (
	"strings"
	"testing"
)

func TestEventTypesMatchCheckConstraint(t *testing.T) {
	// audit.md 第三节共 13 个事件类型
	want := []string{
		"login_success", "login_failure", "logout",
		"totp_bound", "totp_disabled", "password_changed",
		"session_revoked", "trusted_device_added", "trusted_device_revoked",
		"token_created", "token_revoked", "note_published", "note_unpublished",
	}
	got := EventTypes()
	if len(got) != len(want) {
		t.Fatalf("事件类型数量 = %d，期望 %d", len(got), len(want))
	}
	for _, w := range want {
		if _, ok := specs[w]; !ok {
			t.Errorf("缺少事件类型 %q", w)
		}
	}
}

func TestValidateAcceptsDocumentedShape(t *testing.T) {
	cases := []struct {
		name string
		e    Event
	}{
		{"login_success via totp", Event{
			EventType: EventLoginSuccess,
			Metadata:  map[string]any{"via": "password+totp"},
		}},
		{"login_failure no_such_user", Event{
			EventType: EventLoginFailure,
			Metadata:  map[string]any{"reason": "no_such_user"},
		}},
		{"logout", Event{EventType: EventLogout}},
		{"totp_bound", Event{EventType: EventTotpBound, TargetType: TargetUser, TargetID: "u1"}},
		{"session_revoked", Event{
			EventType:  EventSessionRevoked,
			TargetType: TargetSession,
			TargetID:   "s1",
			Metadata:   map[string]any{"session_created_at": "2026-10-28T00:00:00Z"},
		}},
		{"trusted_device_added", Event{
			EventType:  EventTrustedDeviceAdded,
			TargetType: TargetTrustedDevice,
			TargetID:   "d1",
			Metadata:   map[string]any{"device_name": "家里台式机"},
		}},
		{"token_created", Event{
			EventType:  EventTokenCreated,
			TargetType: TargetToken,
			TargetID:   "t1",
			Metadata:   map[string]any{"name": "cli", "scope": "read_write", "token_prefix": "haven_ro"},
		}},
		{"note_published", Event{
			EventType:  EventNotePublished,
			TargetType: TargetNote,
			TargetID:   "n1",
			Metadata:   map[string]any{"title": "标题"},
		}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := Validate(tc.e); err != nil {
				t.Errorf("应通过校验，实际 %v", err)
			}
		})
	}
}

func TestValidateRejectsBadShapes(t *testing.T) {
	cases := []struct {
		name string
		e    Event
		want string
	}{
		{"未定义事件", Event{EventType: "bogus"}, "未定义"},
		{"target_type 不符", Event{
			EventType:  EventLoginSuccess,
			TargetType: TargetUser,
			TargetID:   "u1",
			Metadata:   map[string]any{"via": "password+totp"},
		}, "target_type"},
		{"多余 metadata 键", Event{
			EventType: EventLogout,
			Metadata:  map[string]any{"reason": "x"},
		}, "不允许"},
		{"敏感键混入", Event{
			EventType:  EventTokenCreated,
			TargetType: TargetToken,
			TargetID:   "t1",
			Metadata:   map[string]any{"name": "cli", "scope": "read", "token": "haven_ro_secret"},
		}, "token"},
		{"非法 via", Event{
			EventType: EventLoginSuccess,
			Metadata:  map[string]any{"via": "password"},
		}, "via"},
		{"非法 reason", Event{
			EventType: EventLoginFailure,
			Metadata:  map[string]any{"reason": "whatever"},
		}, "reason"},
		{"非法 scope", Event{
			EventType:  EventTokenCreated,
			TargetType: TargetToken,
			TargetID:   "t1",
			Metadata:   map[string]any{"name": "x", "scope": "admin", "token_prefix": "p"},
		}, "scope"},
		{"缺 target_id", Event{
			EventType:  EventNotePublished,
			TargetType: TargetNote,
			Metadata:   map[string]any{"title": "t"},
		}, "target_id"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := Validate(tc.e)
			if err == nil {
				t.Fatal("应被拒绝")
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Errorf("错误信息应含 %q，实际 %v", tc.want, err)
			}
		})
	}
}

func TestRedactHidesSensitiveValues(t *testing.T) {
	e := Event{
		EventType:     EventTokenCreated,
		ActorUsername: "kairo",
		TargetType:    TargetToken,
		TargetID:      "t1",
		Metadata: map[string]any{
			"name":   "cli",
			"token":  "haven_ro_plaintextsecret",
			"secret": "totp-secret",
		},
	}

	out := Redact(e)
	for _, leak := range []string{"plaintextsecret", "totp-secret"} {
		if strings.Contains(out, leak) {
			t.Errorf("日志不应包含敏感值 %q，实际 %q", leak, out)
		}
	}
	if !strings.Contains(out, "<redacted>") {
		t.Errorf("敏感键应被标记，实际 %q", out)
	}
	if !strings.Contains(out, "cli") {
		t.Errorf("非敏感值应保留，实际 %q", out)
	}
}
