package main

import (
	"net/http"
	"strings"
	"testing"
)

// 标签名长度边界（api.md 8.2，tags.MaxNameRunes = 64）。
//
// 长度校验内联在 tags.Service.Create 里且依赖数据库，这里通过 POST /api/tags 验证边界。

// TestTagNameLength 覆盖 63 / 64 / 65 rune 与 trim 后为空。
func TestTagNameLength(t *testing.T) {
	e, cookie := newUserEnv(t)

	cases := []struct {
		name     string
		input    string
		wantCode int
	}{
		{"63 个 ASCII", strings.Repeat("a", 63), http.StatusCreated},
		{"64 个 ASCII 边界允许", strings.Repeat("b", 64), http.StatusCreated},
		{"65 个 ASCII 拒绝", strings.Repeat("c", 65), http.StatusUnprocessableEntity},
		{"64 个中文按 rune 允许", strings.Repeat("标", 64), http.StatusCreated},
		{"65 个中文按 rune 拒绝", strings.Repeat("签", 65), http.StatusUnprocessableEntity},
		{"64 个 Emoji 按 rune 允许", strings.Repeat("🏷", 64), http.StatusCreated},
		{"65 个 Emoji 按 rune 拒绝", strings.Repeat("🎯", 65), http.StatusUnprocessableEntity},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": tc.input}, cookie)
			if w.Code != tc.wantCode {
				t.Errorf("%d rune 应返回 %d，实际 %d: %s",
					len([]rune(tc.input)), tc.wantCode, w.Code, w.Body.String())
			}
		})
	}
}

// TestTagNameTrimEmpty 覆盖首尾空白：trim 后为空必须 422，trim 后合法必须成功。
func TestTagNameTrimEmpty(t *testing.T) {
	e, cookie := newUserEnv(t)

	if w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "   "}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("纯空白应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	if w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": ""}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("空串应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 长度刚好超限但 trim 后合法：先 trim 再计长度
	padded := "  " + strings.Repeat("x", 64) + "  "
	if w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": padded}, cookie); w.Code != http.StatusCreated {
		t.Errorf("trim 后 64 rune 应成功，实际 %d: %s", w.Code, w.Body.String())
	}
}
