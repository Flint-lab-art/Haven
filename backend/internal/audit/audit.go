// Package audit 负责写审计事件。
//
// 依据 docs/backend/audit.md：
//   - 只追加，不修改不删除；
//   - 写入发生在业务成功之后、响应返回之前；
//   - 写入失败只打错误日志，不影响业务结果（第五节）。
package audit

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"
)

// 事件类型，取值必须与 audit_events.event_type 的 CHECK 约束一致（audit.md 第三节）。
const (
	EventLoginSuccess        = "login_success"
	EventLoginFailure        = "login_failure"
	EventLogout              = "logout"
	EventTotpBound           = "totp_bound"
	EventTotpDisabled        = "totp_disabled"
	EventPasswordChanged     = "password_changed"
	EventSessionRevoked      = "session_revoked"
	EventTrustedDeviceAdded  = "trusted_device_added"
	EventTrustedDeviceRevoke = "trusted_device_revoked"
	EventTokenCreated        = "token_created"
	EventTokenRevoked        = "token_revoked"
	EventNotePublished       = "note_published"
	EventNoteUnpublished     = "note_unpublished"
)

// target_type 取值（audit.md 第三节说明）。'null' 是字符串字面量，表示无对象。
const (
	TargetNull          = "null"
	TargetUser          = "user"
	TargetSession       = "session"
	TargetTrustedDevice = "trusted_device"
	TargetToken         = "token"
	TargetNote          = "note"
)

// login_failure 的 reason 取值（audit.md 第三节）。
const (
	ReasonBadPassword = "bad_password"
	ReasonBadTotp     = "bad_totp"
	ReasonNoSuchUser  = "no_such_user"
)

// Event 是一条待写入的审计事件。
type Event struct {
	// ActorUserID 可为空（登录失败且用户名不存在时）。
	ActorUserID string
	// ActorUsername 是用户名快照，用户被删除后仍保留。
	ActorUsername string
	EventType     string
	// TargetType 为空时写入 'null'。
	TargetType string
	TargetID   string
	Metadata   map[string]any
	IP         string
	UserAgent  string
}

// Writer 写审计事件。
type Writer struct {
	db *sql.DB
}

// NewWriter 构造 Writer。
func NewWriter(db *sql.DB) *Writer {
	return &Writer{db: db}
}

// Record 写入一条审计事件。
//
// 依据 audit.md 第五节：失败只打错误日志，不返回错误、不影响业务结果。
// 因此本方法故意不返回 error。
func (w *Writer) Record(ctx context.Context, e Event) {
	if err := w.record(ctx, e); err != nil {
		// 事件内容进日志便于人工补录（audit.md 5.1），但经 Redact 过滤敏感键，
		// 且不记录请求体（architecture.md 5.7）
		slog.Error("写审计事件失败", "event", Redact(e), "err", err)
	}
}

func (w *Writer) record(ctx context.Context, e Event) error {
	if w == nil || w.db == nil {
		return fmt.Errorf("audit writer 未初始化")
	}

	// 先按 audit.md 第三节清单校验形状：键名写错、target_type 不符、
	// 混入敏感字段都在这里被拦住，而不是等数据库 CHECK 报错
	if err := Validate(e); err != nil {
		return err
	}

	targetType := e.TargetType
	if targetType == "" {
		targetType = TargetNull
	}

	meta := e.Metadata
	if meta == nil {
		meta = map[string]any{}
	}
	rawMeta, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("序列化审计 metadata 失败: %w", err)
	}

	var actorUserID any
	if e.ActorUserID != "" {
		actorUserID = e.ActorUserID
	}
	var targetID any
	if e.TargetID != "" {
		targetID = e.TargetID
	}

	const q = `
		INSERT INTO audit_events
			(actor_user_id, actor_username, event_type, target_type, target_id, metadata, ip, user_agent, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`

	if _, err := w.db.ExecContext(ctx, q,
		actorUserID, e.ActorUsername, e.EventType, targetType, targetID,
		rawMeta, e.IP, e.UserAgent, time.Now()); err != nil {
		return fmt.Errorf("写入审计事件失败: %w", err)
	}
	return nil
}
