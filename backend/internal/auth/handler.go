package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// 认证相关的 HTTP handler。
//
// 依据 docs/api.md 第二节。约定（architecture.md 5.2）：
// *gin.Context 只出现在这一层，业务逻辑在本包的 Service 里。

// 注入 context 的键，供审计与 handler 使用。
const (
	ctxKeySessionID = "session_id"
	ctxKeyTokenID   = "token_id"
	ctxKeyClientIP  = "client_ip"
	ctxKeyUserAgent = "user_agent"
)

// Handler 承载认证相关的 HTTP handler。
type Handler struct {
	svc    *Service
	store  Store
	issuer string // HAVEN_TOTP_ISSUER

	// cookie 下发的 Domain / Secure，来自 HAVEN_COOKIE_DOMAIN 与 HAVEN_COOKIE_SECURE。
	CookieDomain string
	CookieSecure bool

	// 下面的钩子由 main 注入，避免本包依赖 audit（审计包反过来要用它的常量）。
	OnLoginSuccess     func(c *gin.Context, e LoginAudit)
	OnLoginFailure     func(c *gin.Context, username, reason string)
	OnLogout           func(c *gin.Context, ac AuditContext)
	OnTotpBound        func(c *gin.Context, ac AuditContext)
	OnTotpDisabled     func(c *gin.Context, ac AuditContext)
	OnPasswordChanged  func(c *gin.Context, ac AuditContext)
	OnTrustedDeviceAdd func(c *gin.Context, ac AuditContext, deviceID, deviceName string)
	OnSessionRevoked   func(c *gin.Context, ac AuditContext, sessionID, sessionCreatedAt string)
	OnDeviceRevoked    func(c *gin.Context, ac AuditContext, deviceID, deviceName string)
	OnTokenCreated     func(c *gin.Context, ac AuditContext, tokenID, name, scope, prefix string)
	OnTokenRevoked     func(c *gin.Context, ac AuditContext, tokenID, name, prefix string)
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service, store Store, issuer, cookieDomain string, cookieSecure bool) *Handler {
	return &Handler{
		svc:          svc,
		store:        store,
		issuer:       issuer,
		CookieDomain: cookieDomain,
		CookieSecure: cookieSecure,
	}
}

// auditContext 是写审计事件所需的调用方信息。
type AuditContext struct {
	UserID   string
	Username string
	IP       string
	UA       string
	// DeviceID / TokenID 只在新建设备或 Token 时填写，用于审计的 target_id。
	DeviceID string
	TokenID  string
}

// LoginAudit 是登录成功时的审计信息。
type LoginAudit struct {
	UserID   string
	Username string
	Via      string
}

// 请求体（api.md 2.1 – 2.7）。

type loginRequest struct {
	Username    string `json:"username" binding:"required"`
	Password    string `json:"password" binding:"required"`
	TrustDevice bool   `json:"trust_device"`
}

type loginTotpRequest struct {
	TempToken string `json:"temp_token" binding:"required"`
	Code      string `json:"code" binding:"required"`
}

type totpVerifyRequest struct {
	Secret string `json:"secret" binding:"required"`
	Code   string `json:"code" binding:"required"`
}

type totpDisableRequest struct {
	Code string `json:"code" binding:"required"`
}

type passwordChangeRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required"`
	TotpCode    string `json:"totp_code"`
}

// 响应体。

type userBriefResponse struct {
	ID       string `json:"id"`
	Username string `json:"username"`
	// TotpEnabled 只用于 GET /api/me（api.md 12.1），login 响应不带该字段。
	// 声明为指针才能在 false 时也序列化出来（bool + omitempty 会把 false 丢掉）。
	TotpEnabled *bool `json:"totp_enabled,omitempty"`
}

type loginResponse struct {
	User         userBriefResponse `json:"user"`
	TotpRequired bool              `json:"totp_required"`
	TempToken    string            `json:"temp_token,omitempty"`
}

type meResponse struct {
	Anonymous bool               `json:"anonymous"`
	AuthType  string             `json:"auth_type,omitempty"`
	Scope     string             `json:"scope,omitempty"`
	User      *userBriefResponse `json:"user,omitempty"`
}

func (h *Handler) auditContext(c *gin.Context) AuditContext {
	id := CurrentIdentity(c)
	ac := AuditContext{IP: c.ClientIP(), UA: c.Request.UserAgent()}
	if id.IsLoggedIn() {
		ac.UserID = id.UserID
		// 用户名只是审计快照，取不到时留空串（audit_events.actor_username 允许空）
		if u, err := h.svc.findUserByID(c.Request.Context(), id.UserID); err == nil {
			ac.Username = u.Username
		}
	}
	return ac
}

// setSessionCookie 下发会话 cookie。属性见 auth.md 第三节规则 2：
// HttpOnly、SameSite=Lax、Domain=配置值；Secure 由 HAVEN_COOKIE_SECURE 决定。
func setSessionCookie(c *gin.Context, domain string, secure bool, token string) {
	http.SetCookie(c.Writer, &http.Cookie{
		Name:     CookieSession,
		Value:    token,
		Path:     "/",
		Domain:   domain,
		MaxAge:   int(SessionTTL.Seconds()),
		HttpOnly: true,
		Secure:   secure,
		SameSite: http.SameSiteLaxMode,
	})
}

func setTrustedDeviceCookie(c *gin.Context, domain string, secure bool, token string) {
	http.SetCookie(c.Writer, &http.Cookie{
		Name:     CookieTrustedDevice,
		Value:    token,
		Path:     "/",
		Domain:   domain,
		MaxAge:   int(TrustedDeviceTTL.Seconds()),
		HttpOnly: true,
		Secure:   secure,
		SameSite: http.SameSiteLaxMode,
	})
}

func clearSessionCookie(c *gin.Context, domain string, secure bool) {
	http.SetCookie(c.Writer, &http.Cookie{
		Name:     CookieSession,
		Value:    "",
		Path:     "/",
		Domain:   domain,
		MaxAge:   -1,
		HttpOnly: true,
		Secure:   secure,
		SameSite: http.SameSiteLaxMode,
	})
}

// SessionID 返回当前请求所用会话的 id；Token 或匿名返回空串。
func SessionID(c *gin.Context) string {
	if v, ok := c.Get(ctxKeySessionID); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

// UserID 返回当前身份的用户 id。
func UserID(c *gin.Context) string {
	return CurrentIdentity(c).UserID
}
