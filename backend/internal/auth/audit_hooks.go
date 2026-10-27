package auth

import (
	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/audit"
)

// UseAudit 把审计写入器接到 Handler 的各个钩子上。
//
// 依据 docs/backend/audit.md：事件在业务成功后写，失败只记日志，
// 因此这些钩子内部不返回错误、不影响响应。
func UseAudit(h *Handler, w *audit.Writer) {
	if w == nil {
		return
	}

	record := func(c *gin.Context, e audit.Event) {
		w.Record(c.Request.Context(), e)
	}

	h.OnLoginSuccess = func(c *gin.Context, e LoginAudit) {
		record(c, audit.Event{
			ActorUserID:   e.UserID,
			ActorUsername: e.Username,
			EventType:     audit.EventLoginSuccess,
			Metadata:      map[string]any{"via": e.Via},
			IP:            c.ClientIP(),
			UserAgent:     c.Request.UserAgent(),
		})
	}

	h.OnLoginFailure = func(c *gin.Context, username, reason string) {
		record(c, audit.Event{
			ActorUsername: username,
			EventType:     audit.EventLoginFailure,
			Metadata:      map[string]any{"reason": reason},
			IP:            c.ClientIP(),
			UserAgent:     c.Request.UserAgent(),
		})
	}

	h.OnLogout = func(c *gin.Context, ac AuditContext) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventLogout,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTotpBound = func(c *gin.Context, ac AuditContext) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventTotpBound,
			TargetType:    audit.TargetUser,
			TargetID:      ac.UserID,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTotpDisabled = func(c *gin.Context, ac AuditContext) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventTotpDisabled,
			TargetType:    audit.TargetUser,
			TargetID:      ac.UserID,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnPasswordChanged = func(c *gin.Context, ac AuditContext) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventPasswordChanged,
			TargetType:    audit.TargetUser,
			TargetID:      ac.UserID,
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTrustedDeviceAdd = func(c *gin.Context, ac AuditContext, deviceName string) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventTrustedDeviceAdded,
			TargetType:    audit.TargetTrustedDevice,
			Metadata:      map[string]any{"device_name": deviceName},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnSessionRevoked = func(c *gin.Context, ac AuditContext, sessionID, createdAt string) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventSessionRevoked,
			TargetType:    audit.TargetSession,
			TargetID:      sessionID,
			Metadata:      map[string]any{"session_created_at": createdAt},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnDeviceRevoked = func(c *gin.Context, ac AuditContext, deviceName string) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventTrustedDeviceRevoke,
			TargetType:    audit.TargetTrustedDevice,
			Metadata:      map[string]any{"device_name": deviceName},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnTokenCreated = func(c *gin.Context, ac AuditContext, name, scope, prefix string) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventTokenCreated,
			TargetType:    audit.TargetToken,
			// audit.md 第三节：metadata 不含明文
			Metadata:  map[string]any{"name": name, "scope": scope, "token_prefix": prefix},
			IP:        ac.IP,
			UserAgent: ac.UA,
		})
	}

	h.OnTokenRevoked = func(c *gin.Context, ac AuditContext, name, prefix string) {
		record(c, audit.Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     audit.EventTokenRevoked,
			TargetType:    audit.TargetToken,
			Metadata:      map[string]any{"name": name, "token_prefix": prefix},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}
}
