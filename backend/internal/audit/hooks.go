package audit

import (
	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
)

// UseAuthHooks 把审计写入器接到认证包的 handler 钩子上。
//
// 时机：业务成功后、响应前（audit.md 第四节）。钩子内部只调 Record，
// 而 Record 不返回错误、失败只打日志（audit.md 第五节），因此审计故障
// 永远不会改变接口响应。
//
// 各事件的 target_id 与 metadata 严格按 audit.md 第三节表格填。
func UseAuthHooks(h *auth.Handler, w *Writer) {
	if w == nil || h == nil {
		return
	}

	record := func(c *gin.Context, e Event) {
		w.Record(c.Request.Context(), e)
	}

	h.OnLoginSuccess = func(c *gin.Context, e auth.LoginAudit) {
		record(c, Event{
			ActorUserID:   e.UserID,
			ActorUsername: e.Username,
			EventType:     EventLoginSuccess,
			Metadata:      map[string]any{"via": e.Via},
			IP:            c.ClientIP(),
			UserAgent:     c.Request.UserAgent(),
		})
	}

	h.OnLoginFailure = func(c *gin.Context, username, reason string) {
		// 登录失败时通常无法确定用户（尤其 no_such_user），actor_user_id 留空（audit.md 规则 2）
		record(c, Event{
			ActorUsername: username,
			EventType:     EventLoginFailure,
			Metadata:      map[string]any{"reason": reason},
			IP:            c.ClientIP(),
			UserAgent:     c.Request.UserAgent(),
		})
	}

	h.OnLogout = func(c *gin.Context, ac auth.AuditContext) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventLogout,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTotpBound = func(c *gin.Context, ac auth.AuditContext) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventTotpBound,
			TargetType:    TargetUser,
			TargetID:      ac.UserID,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTotpDisabled = func(c *gin.Context, ac auth.AuditContext) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventTotpDisabled,
			TargetType:    TargetUser,
			TargetID:      ac.UserID,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnPasswordChanged = func(c *gin.Context, ac auth.AuditContext) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventPasswordChanged,
			TargetType:    TargetUser,
			TargetID:      ac.UserID,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTrustedDeviceAdd = func(c *gin.Context, ac auth.AuditContext, deviceID, deviceName string) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventTrustedDeviceAdded,
			TargetType:    TargetTrustedDevice,
			TargetID:      deviceID,
			Metadata:      map[string]any{"device_name": deviceName},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnSessionRevoked = func(c *gin.Context, ac auth.AuditContext, sessionID, createdAt string) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventSessionRevoked,
			TargetType:    TargetSession,
			TargetID:      sessionID,
			Metadata:      map[string]any{"session_created_at": createdAt},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnDeviceRevoked = func(c *gin.Context, ac auth.AuditContext, deviceID, deviceName string) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventTrustedDeviceRevoke,
			TargetType:    TargetTrustedDevice,
			TargetID:      deviceID,
			Metadata:      map[string]any{"device_name": deviceName},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTokenCreated = func(c *gin.Context, ac auth.AuditContext, tokenID, name, scope, prefix string) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventTokenCreated,
			TargetType:    TargetToken,
			TargetID:      tokenID,
			// 不含明文（audit.md 规则 5）
			Metadata:  map[string]any{"name": name, "scope": scope, "token_prefix": prefix},
			IP:        ac.IP,
			UserAgent: ac.UA,
		})
	}

	h.OnTokenRevoked = func(c *gin.Context, ac auth.AuditContext, tokenID, name, prefix string) {
		record(c, Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventTokenRevoked,
			TargetType:    TargetToken,
			TargetID:      tokenID,
			Metadata:      map[string]any{"name": name, "token_prefix": prefix},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}
}
