package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

// 静态托管（docs/architecture.md 第七节 / api.md）：
//   - /assets/* 由后端直接返回；
//   - 其余非 /api 路径回 index.html，交给 Vue Router；
//   - /api/* 未命中必须是 JSON 404，不能被 SPA 兜底吞掉。

func newStaticRouter(t *testing.T, dir string) *gin.Engine {
	t.Helper()
	gin.SetMode(gin.TestMode)
	r := gin.New()
	mountStatic(r, dir)
	return r
}

// fakeDist 造一个最小的前端构建产物目录。
func fakeDist(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, "assets"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "index.html"), []byte("<!doctype html><div id=app></div>"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "assets", "index-abc123.js"), []byte("console.log(1)"), 0o644); err != nil {
		t.Fatal(err)
	}
	return dir
}

func serve(r *gin.Engine, path string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, path, nil))
	return w
}

func TestStaticServesAssetsAndSPA(t *testing.T) {
	dir := fakeDist(t)
	r := newStaticRouter(t, dir)

	t.Run("静态资源", func(t *testing.T) {
		w := serve(r, "/assets/index-abc123.js")
		if w.Code != http.StatusOK {
			t.Fatalf("状态码 = %d", w.Code)
		}
		if body := w.Body.String(); body != "console.log(1)" {
			t.Errorf("内容不符: %q", body)
		}
	})

	t.Run("SPA 路由回 index.html", func(t *testing.T) {
		for _, path := range []string{"/", "/notes/abc", "/settings/tokens", "/search"} {
			w := serve(r, path)
			if w.Code != http.StatusOK {
				t.Errorf("%s 状态码 = %d，期望 200", path, w.Code)
				continue
			}
			if !strings.Contains(w.Body.String(), "id=app") {
				t.Errorf("%s 应返回 index.html，实际 %q", path, w.Body.String())
			}
		}
	})

	t.Run("未知 API 返回 JSON 404 而非 index.html", func(t *testing.T) {
		for _, path := range []string{"/api/nope", "/api", "/api/notes/x/y/z"} {
			w := serve(r, path)
			if w.Code != http.StatusNotFound {
				t.Errorf("%s 状态码 = %d，期望 404", path, w.Code)
				continue
			}
			if strings.Contains(w.Body.String(), "id=app") {
				t.Errorf("%s 被 SPA 兜底吞掉了（应返回 JSON 404）", path)
			}
			if !strings.Contains(w.Body.String(), "not_found") {
				t.Errorf("%s 应返回统一错误体，实际 %q", path, w.Body.String())
			}
		}
	})
}

func TestStaticDisabledWithoutFrontendDir(t *testing.T) {
	// HAVEN_FRONTEND_DIR 为空时（测试环境）不应注册兜底路由
	r := newStaticRouter(t, "")
	if w := serve(r, "/"); w.Code != http.StatusNotFound {
		t.Errorf("未配置前端目录时根路径应 404，实际 %d", w.Code)
	}
}

func TestStaticDoesNotShadowHealth(t *testing.T) {
	// 真实路由优先于 NoRoute，health 仍可访问
	dir := fakeDist(t)
	r := newStaticRouter(t, dir)
	r.GET("/api/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ok"}) })

	if w := serve(r, "/api/health"); w.Code != http.StatusOK || !strings.Contains(w.Body.String(), "ok") {
		t.Errorf("健康检查被静态兜底影响: %d %s", w.Code, w.Body.String())
	}
}
