package auth

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// 会话、授信设备、Token 的 handler，对照 docs/api.md 第三、四、五节。
// 这三个资源都只允许会话身份操作（Token 一律 403），在路由层挂 RequireSession。

type listResponse struct {
	Items any `json:"items"`
	Total int `json:"total"`
}

// ListSessions 实现 GET /api/sessions（api.md 3.1）。
func (h *Handler) ListSessions(c *gin.Context) {
	items, err := h.svc.ListSessions(c.Request.Context(), UserID(c), SessionID(c))
	if err != nil {
		InternalError(c, err)
		return
	}
	c.JSON(http.StatusOK, listResponse{Items: items, Total: len(items)})
}

// DeleteSession 实现 DELETE /api/sessions/:id（api.md 3.2）。
func (h *Handler) DeleteSession(c *gin.Context) {
	id := c.Param("id")

	createdAt, err := h.svc.FindSessionOwner(c.Request.Context(), UserID(c), id)
	if err != nil {
		if errors.Is(err, ErrSessionNotFound) {
			NotFound(c)
			return
		}
		InternalError(c, err)
		return
	}

	err = h.svc.RevokeSession(c.Request.Context(), UserID(c), id, SessionID(c))
	if err != nil {
		switch {
		case errors.Is(err, ErrCannotRevokeCurrentSession):
			ValidationFailed(c, map[string]string{"id": ErrCannotRevokeCurrentSession.Error()})
		case errors.Is(err, ErrSessionNotFound):
			NotFound(c)
		default:
			InternalError(c, err)
		}
		return
	}

	if h.OnSessionRevoked != nil {
		h.OnSessionRevoked(c, h.auditContext(c), id, createdAt.Format(time.RFC3339))
	}
	c.Status(http.StatusNoContent)
}

// ListTrustedDevices 实现 GET /api/trusted-devices（api.md 4.1）。
func (h *Handler) ListTrustedDevices(c *gin.Context) {
	items, err := h.svc.ListTrustedDevices(c.Request.Context(), UserID(c))
	if err != nil {
		InternalError(c, err)
		return
	}
	c.JSON(http.StatusOK, listResponse{Items: items, Total: len(items)})
}

// DeleteTrustedDevice 实现 DELETE /api/trusted-devices/:id（api.md 4.2）。
func (h *Handler) DeleteTrustedDevice(c *gin.Context) {
	id := c.Param("id")

	device, err := h.svc.FindTrustedDevice(c.Request.Context(), UserID(c), id)
	if err != nil {
		if errors.Is(err, ErrTrustedDeviceNotFound) {
			NotFound(c)
			return
		}
		InternalError(c, err)
		return
	}

	if err := h.svc.RevokeTrustedDevice(c.Request.Context(), UserID(c), id); err != nil {
		if errors.Is(err, ErrTrustedDeviceNotFound) {
			NotFound(c)
			return
		}
		InternalError(c, err)
		return
	}

	if h.OnDeviceRevoked != nil {
		h.OnDeviceRevoked(c, h.auditContext(c), device.ID, device.DeviceName)
	}
	c.Status(http.StatusNoContent)
}

// ListTokens 实现 GET /api/tokens（api.md 5.1）。
func (h *Handler) ListTokens(c *gin.Context) {
	items, err := h.svc.ListAPITokens(c.Request.Context(), UserID(c))
	if err != nil {
		InternalError(c, err)
		return
	}
	c.JSON(http.StatusOK, listResponse{Items: items, Total: len(items)})
}

type createTokenRequest struct {
	Name      string     `json:"name" binding:"required"`
	Scope     string     `json:"scope" binding:"required"`
	ExpiresAt *time.Time `json:"expires_at"`
}

// CreateToken 实现 POST /api/tokens（api.md 5.2）。
func (h *Handler) CreateToken(c *gin.Context) {
	var req createTokenRequest
	if !bind(c, &req) {
		return
	}
	if err := ValidateScope(req.Scope); err != nil {
		ValidationFailed(c, map[string]string{"scope": err.Error()})
		return
	}

	created, err := h.svc.CreateAPIToken(c.Request.Context(), UserID(c), req.Name, req.Scope, req.ExpiresAt)
	if err != nil {
		InternalError(c, err)
		return
	}

	if h.OnTokenCreated != nil {
		h.OnTokenCreated(c, h.auditContext(c), created.ID, created.Name, created.Scope, created.TokenPrefix)
	}

	// 明文只在这里返回一次（api.md 5.2 / auth.md 第五节规则 1）
	c.JSON(http.StatusCreated, created)
}

// DeleteToken 实现 DELETE /api/tokens/:id（api.md 5.3）。
func (h *Handler) DeleteToken(c *gin.Context) {
	id := c.Param("id")

	token, err := h.svc.RevokeAPIToken(c.Request.Context(), UserID(c), id)
	if err != nil {
		switch {
		case errors.Is(err, ErrTokenNotFound):
			NotFound(c)
		case errors.Is(err, ErrTokenAlreadyRevoked):
			ValidationFailed(c, map[string]string{"id": ErrTokenAlreadyRevoked.Error()})
		default:
			InternalError(c, err)
		}
		return
	}

	if h.OnTokenRevoked != nil {
		h.OnTokenRevoked(c, h.auditContext(c), token.ID, token.Name, token.TokenPrefix)
	}
	c.Status(http.StatusNoContent)
}
