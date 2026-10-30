package main

import (
	"net/http"
	"path/filepath"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/folders"
	"github.com/kairo/haven/internal/httpx"
	"github.com/kairo/haven/internal/notes"
	"github.com/kairo/haven/internal/portfolio"
	"github.com/kairo/haven/internal/search"
	"github.com/kairo/haven/internal/tags"
)

// init 关闭 Gin 的 debug 输出（路由表、模式警告）。
// 必须在 gin.New / gin.Default 之前设置，因此放在包级 init 而不是 newRouter 里：
// 日志统一走 slog（architecture.md 5.7）。
func init() {
	gin.SetMode(gin.ReleaseMode)
}

// deps 汇总路由装配所需的依赖。
type deps struct {
	authStore      auth.Store
	authHandler    *auth.Handler
	notesHandler   *notes.Handler
	foldersHandler *folders.Handler
	tagsHandler    *tags.Handler
	searchHandler  *search.Handler
	portfolio      *portfolio.Handler

	// frontendDir 是 HAVEN_FRONTEND_DIR，用于托管 SPA 构建产物。
	frontendDir string
}

// newRouter 组装 Gin 路由。
//
// 依据 docs/architecture.md 5.3：中间件顺序为 日志 → 鉴权 → 领域 handler。
func newRouter(d deps) *gin.Engine {
	// 鉴权中间件通过回调使用统一错误响应，避免包循环
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

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(auth.Authenticate(d.authStore))

	r.GET("/api/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	auth.RegisterMeRoute(r, d.authHandler)
	auth.RegisterRoutes(r, d.authHandler)
	auth.RegisterManageRoutes(r, d.authHandler)

	notes.RegisterRoutes(r, d.notesHandler)
	folders.RegisterRoutes(r, d.foldersHandler)
	tags.RegisterRoutes(r, d.tagsHandler)
	search.RegisterRoutes(r, d.searchHandler)
	portfolio.RegisterRoutes(r, d.portfolio)

	mountStatic(r, d.frontendDir)
	return r
}

// mountStatic 托管前端构建产物（docs/architecture.md 第七节）。
//
//   - /assets/* 直接返回文件并带长缓存（文件名含 hash）；
//   - 其余非 /api 路径一律回 index.html，交给 Vue Router；
//   - /api/* 未命中时不回退到 SPA，避免把接口 404 变成 200 index.html。
func mountStatic(r *gin.Engine, dir string) {
	if dir == "" {
		return
	}

	r.Static("/assets", filepath.Join(dir, "assets"))
	r.StaticFile("/favicon.svg", filepath.Join(dir, "favicon.svg"))

	index := filepath.Join(dir, "index.html")
	r.NoRoute(func(c *gin.Context) {
		path := c.Request.URL.Path
		if len(path) >= 5 && path[:5] == "/api/" || path == "/api" {
			c.JSON(http.StatusNotFound, httpx.ErrorBody{
				Error:   httpx.CodeNotFound,
				Message: "资源不存在",
			})
			return
		}
		c.File(index)
	})
}
