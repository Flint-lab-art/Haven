package httpx

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
)

func contains(s, sub string) bool { return strings.Contains(s, sub) }

func init() { gin.SetMode(gin.TestMode) }

func run(fn func(c *gin.Context)) *httptest.ResponseRecorder {
	r := gin.New()
	r.GET("/x", fn)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/x", nil))
	return w
}

func TestFailMapping(t *testing.T) {
	cases := []struct {
		name     string
		err      error
		wantCode int
		wantBody string
	}{
		{name: "凭据错误", err: auth.ErrInvalidCredentials, wantCode: 401, wantBody: "unauthorized"},
		{name: "临时token过期", err: auth.ErrPendingExpired, wantCode: 401, wantBody: "unauthorized"},
		{name: "动态码错误", err: auth.ErrBadTotp, wantCode: 401, wantBody: "unauthorized"},
		{name: "TOTP已启用", err: auth.ErrTotpAlreadyEnabled, wantCode: 409, wantBody: "conflict"},
		{name: "TOTP未启用", err: auth.ErrTotpNotEnabled, wantCode: 422, wantBody: "validation_failed"},
		{name: "找不到", err: auth.ErrNotFound, wantCode: 404, wantBody: "not_found"},
		{name: "未知错误", err: errors.New("boom"), wantCode: 500, wantBody: "internal_error"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			w := run(func(c *gin.Context) { Fail(c, tc.err) })
			if w.Code != tc.wantCode {
				t.Errorf("状态码 = %d，期望 %d", w.Code, tc.wantCode)
			}
			if body := w.Body.String(); !contains(body, tc.wantBody) {
				t.Errorf("响应体应含 %q，实际 %s", tc.wantBody, body)
			}
			// 内部错误细节不能泄漏给客户端
			if tc.wantCode == 500 && contains(w.Body.String(), "boom") {
				t.Error("500 响应不应包含内部错误细节")
			}
		})
	}
}

func TestFailValidationFields(t *testing.T) {
	w := run(func(c *gin.Context) {
		FailValidation(c, map[string]string{"title": "不能为空"})
	})
	if w.Code != http.StatusUnprocessableEntity {
		t.Errorf("状态码 = %d", w.Code)
	}
	if body := w.Body.String(); !contains(body, `"fields":{"title":"不能为空"}`) {
		t.Errorf("应带 fields，实际 %s", body)
	}
}

func TestInstallAuthErrorHandlers(t *testing.T) {
	InstallAuthErrorHandlers()

	// 用 RequireLogin 触发 401，不需要数据库
	r := gin.New()
	r.Use(auth.Authenticate(nil), auth.RequireLogin())
	r.GET("/p", func(c *gin.Context) { c.Status(http.StatusOK) })

	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/p", nil))

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("状态码 = %d", w.Code)
	}
	if body := w.Body.String(); !contains(body, `"error":"unauthorized"`) {
		t.Errorf("应走 httpx 的统一错误体，实际 %s", body)
	}
}
