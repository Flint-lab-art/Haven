package auth

import (
	"context"
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
)

// 认证接口的 handler 实现，对照 docs/api.md 第二节。

// bind 解析 JSON 请求体。
func bind(c *gin.Context, dst any) bool {
	if err := c.ShouldBindJSON(dst); err != nil {
		BadRequest(c, err)
		return false
	}
	return true
}

// Login 实现 POST /api/auth/login（api.md 2.1）。
func (h *Handler) Login(c *gin.Context) {
	var req loginRequest
	if !bind(c, &req) {
		return
	}

	deviceCookie, _ := c.Cookie(CookieTrustedDevice)

	res, err := h.svc.Login(c.Request.Context(), req.Username, req.Password,
		req.TrustDevice, deviceCookie, c.Request.UserAgent())
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidCredentials):
			// 失败审计（audit.md 第三节）
			h.failLogin(c, req.Username, ReasonBadPassword)
			Unauthorized(c, ErrInvalidCredentials.Error())
		default:
			InternalError(c, err)
		}
		return
	}

	if res.TotpRequired {
		c.JSON(http.StatusOK, loginResponse{
			User:         userBriefResponse{ID: res.User.ID, Username: res.User.Username},
			TotpRequired: true,
			TempToken:    res.TempToken,
		})
		return
	}

	h.succeedLogin(c, res)
}

// LoginTotp 实现 POST /api/auth/login/totp（api.md 2.2）。
func (h *Handler) LoginTotp(c *gin.Context) {
	var req loginTotpRequest
	if !bind(c, &req) {
		return
	}

	res, err := h.svc.LoginTotp(c.Request.Context(), req.TempToken, req.Code, c.Request.UserAgent())
	if err != nil {
		switch {
		case errors.Is(err, ErrPendingExpired):
			Unauthorized(c, ErrPendingExpired.Error())
		case errors.Is(err, ErrBadTotp):
			h.failLogin(c, h.usernameFromPending(c.Request.Context(), req.TempToken), ReasonBadTotp)
			Unauthorized(c, ErrBadTotp.Error())
		default:
			InternalError(c, err)
		}
		return
	}

	h.succeedLogin(c, res)
}

// succeedLogin 下发 cookie 并写 login_success 审计。
func (h *Handler) succeedLogin(c *gin.Context, res LoginResult) {
	setSessionCookie(c, h.CookieDomain, h.CookieSecure, res.SessionToken)
	if res.DeviceToken != "" {
		setTrustedDeviceCookie(c, h.CookieDomain, h.CookieSecure, res.DeviceToken)
	}

	if h.OnLoginSuccess != nil {
		h.OnLoginSuccess(c, LoginAudit{UserID: res.User.ID, Username: res.User.Username, Via: res.AuditVia})
	}
	if res.DeviceToken != "" && h.OnTrustedDeviceAdd != nil {
		h.OnTrustedDeviceAdd(c, AuditContext{UserID: res.User.ID, Username: res.User.Username,
			IP: c.ClientIP(), UA: c.Request.UserAgent()}, res.DeviceName)
	}

	c.JSON(http.StatusOK, loginResponse{
		User:         userBriefResponse{ID: res.User.ID, Username: res.User.Username},
		TotpRequired: false,
	})
}

func (h *Handler) failLogin(c *gin.Context, username, reason string) {
	if h.OnLoginFailure != nil {
		h.OnLoginFailure(c, username, reason)
	}
}

// Logout 实现 POST /api/auth/logout（api.md 2.3）。
func (h *Handler) Logout(c *gin.Context) {
	ac := h.auditContext(c)

	if err := h.svc.Logout(c.Request.Context(), SessionID(c)); err != nil {
		InternalError(c, err)
		return
	}
	clearSessionCookie(c, h.CookieDomain, h.CookieSecure)
	// 授信设备 cookie 保留（api.md 2.3）

	if SessionID(c) != "" && h.OnLogout != nil {
		h.OnLogout(c, ac)
	}
	c.Status(http.StatusNoContent)
}

// SetupTotp 实现 POST /api/auth/totp/setup（api.md 2.4）。
func (h *Handler) SetupTotp(c *gin.Context) {
	userID := UserID(c)

	secret, uri, err := h.svc.SetupTotp(userID, h.issuer)
	if err != nil {
		switch {
		case errors.Is(err, ErrTotpAlreadyEnabled):
			Conflict(c, ErrTotpAlreadyEnabled.Error())
		default:
			InternalError(c, err)
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"secret": secret, "otpauth_uri": uri})
}

// VerifyTotp 实现 POST /api/auth/totp/verify（api.md 2.5）。
func (h *Handler) VerifyTotp(c *gin.Context) {
	var req totpVerifyRequest
	if !bind(c, &req) {
		return
	}

	err := h.svc.VerifyTotp(c.Request.Context(), UserID(c), req.Secret, req.Code)
	if err != nil {
		switch {
		case errors.Is(err, ErrBadTotp):
			ValidationFailed(c, map[string]string{"code": ErrBadTotp.Error()})
		case errors.Is(err, ErrTotpAlreadyEnabled):
			Conflict(c, ErrTotpAlreadyEnabled.Error())
		default:
			InternalError(c, err)
		}
		return
	}

	if h.OnTotpBound != nil {
		h.OnTotpBound(c, h.auditContext(c))
	}
	c.JSON(http.StatusOK, gin.H{"totp_enabled": true})
}

// DisableTotp 实现 POST /api/auth/totp/disable（api.md 2.6）。
func (h *Handler) DisableTotp(c *gin.Context) {
	var req totpDisableRequest
	if !bind(c, &req) {
		return
	}

	err := h.svc.DisableTotp(c.Request.Context(), UserID(c), req.Code)
	if err != nil {
		switch {
		case errors.Is(err, ErrBadTotp):
			Unauthorized(c, ErrBadTotp.Error())
		case errors.Is(err, ErrTotpNotEnabled):
			ValidationFailed(c, map[string]string{"code": ErrTotpNotEnabled.Error()})
		default:
			InternalError(c, err)
		}
		return
	}

	if h.OnTotpDisabled != nil {
		h.OnTotpDisabled(c, h.auditContext(c))
	}
	c.JSON(http.StatusOK, gin.H{"totp_enabled": false})
}

// ChangePassword 实现 POST /api/auth/password（api.md 2.7）。
func (h *Handler) ChangePassword(c *gin.Context) {
	var req passwordChangeRequest
	if !bind(c, &req) {
		return
	}

	ac := h.auditContext(c)
	err := h.svc.ChangePassword(c.Request.Context(), UserID(c), req.OldPassword, req.NewPassword, req.TotpCode)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidCredentials):
			Unauthorized(c, ErrInvalidCredentials.Error())
		case errors.Is(err, ErrBadTotp):
			Unauthorized(c, ErrBadTotp.Error())
		case IsPasswordPolicyError(err):
			ValidationFailed(c, map[string]string{"new_password": err.Error()})
		default:
			InternalError(c, err)
		}
		return
	}

	if h.OnPasswordChanged != nil {
		h.OnPasswordChanged(c, ac)
	}
	// 当前会话也被删除，客户端需要重新登录（api.md 2.7 备注）
	clearSessionCookie(c, h.CookieDomain, h.CookieSecure)
	c.Status(http.StatusNoContent)
}

// Me 实现 GET /api/me（api.md 11.1）。
func (h *Handler) Me(c *gin.Context) {
	id := CurrentIdentity(c)
	if !id.IsLoggedIn() {
		c.JSON(http.StatusOK, meResponse{Anonymous: true})
		return
	}

	user, err := h.store.GetUser(c.Request.Context(), id.UserID)
	if err != nil {
		InternalError(c, err)
		return
	}

	c.JSON(http.StatusOK, meResponse{
		Anonymous: false,
		AuthType:  id.String(),
		Scope:     id.Scope,
		User:      &userBriefResponse{ID: user.ID, Username: user.Username},
	})
}

// usernameFromPending 用临时 token 反查用户名，供 login_failure 审计使用。
// 查不到时返回空串（audit_events.actor_username 允许空串）。
func (h *Handler) usernameFromPending(ctx context.Context, tempToken string) string {
	base, _ := splitPendingToken(tempToken)
	username, err := h.svc.pendingUsername(ctx, HashToken(base))
	if err != nil {
		return ""
	}
	return username
}
