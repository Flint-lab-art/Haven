package main

import (
	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"
)

// newRouter 组装 Gin 路由。
//
// 依据 docs/architecture.md 5.3：中间件顺序为 日志 → 鉴权 → 领域 handler。
// 本期接入认证相关路由（api.md 第二、三、四、五、十一节）。
func newRouter(h *auth.Handler, store auth.Store) *gin.Engine {
	// 鉴权中间件通过回调使用统一错误响应，避免 auth ↔ httpx 包循环
	httpx.InstallAuthErrorHandlers()
	auth.SetErrorCallbacks(
		httpx.FailBadRequest,
		httpx.FailValidation,
		httpx.FailInternal,
		httpx.FailNotFound,
		httpx.FailConflict,
		httpx.FailUnauthorizedWith,
		httpx.FailUnprocessable,
	)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(auth.Authenticate(store))

	r.GET("/api/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	auth.RegisterMeRoute(r, h)
	auth.RegisterRoutes(r, h)
	auth.RegisterManageRoutes(r, h)

	return r
}
