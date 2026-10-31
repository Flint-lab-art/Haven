package main

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/folders"
	"github.com/kairo/haven/internal/notes"
	"github.com/kairo/haven/internal/portfolio"
	"github.com/kairo/haven/internal/search"
	"github.com/kairo/haven/internal/tags"
)

// 本文件是「全量路由鉴权」不变量测试，和 router_test.go / domain_test.go 的逐功能
// 用例互补：
//
//   - 逐功能用例回答「这个场景对不对」；
//   - 本文件回答「有没有哪条 /api 路由忘了上锁」。
//
// 依据 docs/backend/auth.md 6.2（四档权限）与 docs/api.md 1.6（Token 权限矩阵）。
//
// 关键设计是白名单：除显式列出的公开路由外，**默认所有 /api 路由都必须拒绝匿名**。
// 这样新增路由会被自动覆盖，想放行必须改这里的白名单，评审时一眼可见。
//
// 本测试不连库：鉴权中间件在 handler 之前中止，nil 的 *sql.DB 不会被碰到；
// 若哪天漏挂鉴权，handler 会真的执行并失败（非 401），测试同样会红。

// publicAPIRoutes 是允许匿名访问的接口（api.md 二、七、十一节）。
// 新增公开接口时必须同步这里，否则测试会把它当成漏网路由。
var publicAPIRoutes = map[string]bool{
	"GET /api/health":           true,
	"GET /api/me":               true,
	"POST /api/auth/login":      true,
	"POST /api/auth/login/totp": true,
	"GET /api/public/notes":     true,
	"GET /api/public/notes/:id": true,
	"GET /api/public/search":    true,
	"GET /api/public/portfolio": true,
	// docs/v3/api.md 2.2：公开的作品详情，供作品集详情页渲染介绍正文
	"GET /api/public/portfolio/:id": true,
}

// routeAuthStore 只实现鉴权中间件用到的最小接口，供 Token 权限兜底测试使用。
type routeAuthStore struct {
	token auth.APIToken
}

func (s routeAuthStore) FindTokenByHash(context.Context, string) (auth.APIToken, error) {
	return s.token, nil
}

func (s routeAuthStore) TouchToken(context.Context, string, time.Time) error { return nil }

func (s routeAuthStore) FindSessionByHash(context.Context, string) (auth.Session, error) {
	return auth.Session{}, auth.ErrNotFound
}

func (s routeAuthStore) TouchSession(context.Context, string, time.Time) error { return nil }

func (s routeAuthStore) DeleteSession(context.Context, string) error { return nil }

func (s routeAuthStore) GetUser(context.Context, string) (auth.User, error) {
	return auth.User{}, auth.ErrNotFound
}

// newRouteAuthRouter 构造完整路由栈，但业务依赖全部为 nil（不连库）。
func newRouteAuthRouter(store auth.Store) *gin.Engine {
	return newRouter(deps{
		authStore:      store,
		authHandler:    auth.NewHandler(nil, nil, "Haven", "", false),
		notesHandler:   notes.NewHandler(notes.NewService(nil)),
		foldersHandler: folders.NewHandler(folders.NewService(nil)),
		tagsHandler:    tags.NewHandler(tags.NewService(nil)),
		searchHandler:  search.NewHandler(search.NewService(nil)),
		portfolio:      portfolio.NewHandler(portfolio.NewService(nil, "")),
	})
}

// apiRoutes 返回全部 /api 路由（gin 的注册路径，含 :id 这类占位符）。
func apiRoutes(r *gin.Engine) []gin.RouteInfo {
	var routes []gin.RouteInfo
	for _, route := range r.Routes() {
		if strings.HasPrefix(route.Path, "/api/") || route.Path == "/api" {
			routes = append(routes, route)
		}
	}
	return routes
}

// concretePath 把注册路径里的占位符换成合法值，用于真实发请求。
func concretePath(pattern string) string {
	parts := strings.Split(pattern, "/")
	for i, part := range parts {
		if strings.HasPrefix(part, ":") || strings.HasPrefix(part, "*") {
			parts[i] = "00000000-0000-0000-0000-000000000000"
		}
	}
	return strings.Join(parts, "/")
}

// newAPIRequest 发一个空 JSON 请求；鉴权失败会在解析 body 之前返回。
func newAPIRequest(method, path, bearer string) *http.Request {
	req := httptest.NewRequest(method, concretePath(path), bytes.NewReader([]byte("{}")))
	req.Header.Set("Content-Type", "application/json")
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	return req
}

func serveAPI(r *gin.Engine, req *http.Request) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w
}

// TestAPIRoutesRequireAuth 遍历全部 /api 路由：除白名单外，匿名访问必须 401。
func TestAPIRoutesRequireAuth(t *testing.T) {
	r := newRouteAuthRouter(nil)
	routes := apiRoutes(r)
	if len(routes) < 15 {
		t.Fatalf("只枚举到 %d 条 /api 路由，路由装配可能已损坏", len(routes))
	}

	seen := make(map[string]bool, len(routes))
	for _, route := range routes {
		key := route.Method + " " + route.Path
		seen[key] = true

		if publicAPIRoutes[key] {
			continue
		}

		t.Run(strings.ReplaceAll(key, " ", "_"), func(t *testing.T) {
			w := serveAPI(r, newAPIRequest(route.Method, route.Path, ""))
			if w.Code == http.StatusUnauthorized {
				return
			}
			t.Errorf("%s 匿名访问应 401，实际 %d: %s", key, w.Code, w.Body.String())
		})
	}

	// 白名单不能有僵尸条目：接口删了/改了，白名单必须同步，否则会静默放行同名新路由。
	for key := range publicAPIRoutes {
		if !seen[key] {
			t.Errorf("公开路由白名单里的 %q 在路由表中不存在，请同步更新", key)
		}
	}
}

// TestAPIRoutesRejectReadTokenWrites 用 read scope 的 Token 打全部非 GET 私有路由，
// 要求一律 403（api.md 1.6：read Token 不能写；凭证类接口对任何 Token 都 403）。
func TestAPIRoutesRejectReadTokenWrites(t *testing.T) {
	store := routeAuthStore{token: auth.APIToken{
		ID:     "tok-read",
		UserID: "00000000-0000-0000-0000-000000000001",
		Scope:  auth.ScopeRead,
	}}
	r := newRouteAuthRouter(store)

	checked := 0
	for _, route := range apiRoutes(r) {
		if route.Method == http.MethodGet || route.Method == http.MethodHead {
			continue
		}
		key := route.Method + " " + route.Path
		if publicAPIRoutes[key] {
			continue
		}
		checked++

		t.Run(strings.ReplaceAll(key, " ", "_"), func(t *testing.T) {
			w := serveAPI(r, newAPIRequest(route.Method, route.Path, "read-token"))
			if w.Code == http.StatusForbidden {
				return
			}
			t.Errorf("%s 用 read Token 访问应 403，实际 %d: %s", key, w.Code, w.Body.String())
		})
	}

	if checked == 0 {
		t.Fatal("没有枚举到任何非 GET 私有路由，路由装配可能已损坏")
	}
}
