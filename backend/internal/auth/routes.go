package auth

import (
	"github.com/gin-gonic/gin"
)

// Routes 注册认证相关路由。
//
// 鉴权归属见 api.md 第二节：
//   - /login、/login/totp：匿名；
//   - /logout、/totp/setup、/totp/verify：登录（Token 不可用，凭证管理只允许会话）；
//   - /totp/disable、/password：登录 + TOTP（api.md 2.6、2.7）。
//
// base 提供 Authenticate 中间件已经注入的身份与可见性，本函数只负责权限档位。
func RegisterRoutes(r gin.IRouter, h *Handler) {
	r.POST("/api/auth/login", h.Login)
	r.POST("/api/auth/login/totp", h.LoginTotp)

	sessionOnly := r.Group("/api/auth", RequireSession())
	sessionOnly.POST("/logout", h.Logout)
	sessionOnly.POST("/totp/setup", h.SetupTotp)
	sessionOnly.POST("/totp/verify", h.VerifyTotp)

	totpOnly := r.Group("/api/auth", RequireSession(), RequireTotpVerified())
	totpOnly.POST("/totp/disable", h.DisableTotp)
	totpOnly.POST("/password", h.ChangePassword)
}

// RegisterManageRoutes 注册会话 / 授信设备 / Token 路由（api.md 第三、四、五节）。
//
// 全部要求会话身份：
//   - 会话与授信设备的列表/撤销：会话即可；
//   - Token 的增删查：会话 + TOTP（api.md 5.1–5.3）。
func RegisterManageRoutes(r gin.IRouter, h *Handler) {
	s := r.Group("/api/sessions", RequireSession())
	s.GET("", h.ListSessions)
	s.DELETE("/:id", h.DeleteSession)

	d := r.Group("/api/trusted-devices", RequireSession())
	d.GET("", h.ListTrustedDevices)
	d.DELETE("/:id", h.DeleteTrustedDevice)

	t := r.Group("/api/tokens", RequireSession(), RequireTotpVerified())
	t.GET("", h.ListTokens)
	t.POST("", h.CreateToken)
	t.DELETE("/:id", h.DeleteToken)
}

// RegisterMeRoute 注册 GET /api/me（api.md 11.1），匿名可访问。
func RegisterMeRoute(r gin.IRouter, h *Handler) {
	r.GET("/api/me", h.Me)
}
