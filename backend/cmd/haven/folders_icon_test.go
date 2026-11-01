package main

import (
	"net/http"
	"strings"
	"testing"
)

// 文件夹自定义图标（docs/api.md 6.5.1–6.5.3，data-model.md 第七点五节）。

func TestFoldersIcon(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 创建时带 Emoji
	w := e.do(http.MethodPost, "/api/folders",
		map[string]any{"name": "技术", "icon": "📚"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建状态码 = %d: %s", w.Code, w.Body.String())
	}
	created := jsonBody(t, w.Body.Bytes())
	folderID := created["id"].(string)
	if created["icon"] != "📚" {
		t.Errorf("创建后 icon = %v，期望 📚", created["icon"])
	}

	// 列表返回 icon
	w = e.do(http.MethodGet, "/api/folders", nil, cookie)
	items, _ := listBody(t, w.Body.Bytes())
	if len(items) != 1 || items[0]["icon"] != "📚" {
		t.Fatalf("列表 icon 异常: %v", items)
	}

	// 改图标
	w = e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"icon": "💡"}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("改图标状态码 = %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes())["icon"]; got != "💡" {
		t.Errorf("改图标后 icon = %v，期望 💡", got)
	}

	// PATCH 不带 icon：保持不变
	w = e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"name": "Tech"}, cookie)
	if got := jsonBody(t, w.Body.Bytes())["icon"]; got != "💡" {
		t.Errorf("未传 icon 时不应改变，实际 %v", got)
	}

	// 空字符串 = 清除
	w = e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"icon": ""}, cookie)
	if got := jsonBody(t, w.Body.Bytes())["icon"]; got != nil {
		t.Errorf("空字符串应清除 icon，实际 %v", got)
	}

	// 纯空白 = 清除
	w = e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"icon": "  "}, cookie)
	if got := jsonBody(t, w.Body.Bytes())["icon"]; got != nil {
		t.Errorf("纯空白应清除 icon，实际 %v", got)
	}

	// 重新设置后用 null 清除
	if w := e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"icon": "🔥"}, cookie); w.Code != http.StatusOK {
		t.Fatalf("设置图标状态码 = %d: %s", w.Code, w.Body.String())
	}
	w = e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"icon": nil}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("null 清除图标状态码 = %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes())["icon"]; got != nil {
		t.Errorf("null 应清除 icon，实际 %v", got)
	}

	// 超过 256 个 rune → 422（v4 起放宽，见 docs/v4/backend/data-model.md 第一节）
	tooLong := strings.Repeat("a", 257)
	if w := e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"icon": tooLong}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("超长 icon 应 422，实际 %d: %s", w.Code, w.Body.String())
	}
	if w := e.do(http.MethodPost, "/api/folders",
		map[string]any{"name": "超长", "icon": tooLong}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("创建超长 icon 应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 换行 → 422
	if w := e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"icon": "a\nb"}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("换行 icon 应 422，实际 %d: %s", w.Code, w.Body.String())
	}
}
