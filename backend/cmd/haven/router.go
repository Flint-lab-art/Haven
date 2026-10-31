package main

import (
	"context"
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

	// usernameByID 供笔记审计填充 actor_username 快照（audit.md 2 规则 3）。
	// 为 nil 时审计里的用户名留空（测试装配可用）。
	usernameByID func(ctx context.Context, id string) (string, error)

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

	// 笔记 publish/unpublish 的审计要带用户名快照；auth 与 audit 不能互相 import，
	// 因此由这里注入一个只读查询函数（笔记包不感知 auth 的 Store 接口）。
	if d.usernameByID != nil && d.notesHandler != nil {
		d.notesHandler.SetUsernameLookup(d.usernameByID)
	}

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

	// /assets 下的文件名都带内容 hash，可以放心长缓存；
	// gin 的 Static 只会回 Last-Modified，因此包一层补 Cache-Control（architecture.md 第七节）。
	assets := http.Dir(filepath.Join(dir, "assets"))
	r.GET("/assets/*filepath", func(c *gin.Context) {
		c.Header("Cache-Control", "public, max-age=31536000, immutable")
		c.FileFromFS(c.Param("filepath"), assets)
	})
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
