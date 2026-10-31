package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"
)

// 一期补课的回归测试：文件夹名长度、审计用户名快照、搜索可见性。

// TestFolderNameLength 覆盖 api.md 7.2 / 7.3：文件夹名上限 32 rune。
func TestFolderNameLength(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 32 个 rune（中文）刚好合法
	longest := strings.Repeat("目", 32)
	w := e.do(http.MethodPost, "/api/folders", map[string]any{"name": longest}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("32 rune 应创建成功，实际 %d: %s", w.Code, w.Body.String())
	}
	id := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 33 个 rune 拒绝
	tooLong := strings.Repeat("目", 33)
	w = e.do(http.MethodPost, "/api/folders", map[string]any{"name": tooLong}, cookie)
	if w.Code != http.StatusUnprocessableEntity {
		t.Fatalf("33 rune 应 422，实际 %d: %s", w.Code, w.Body.String())
	}
	if fields, ok := jsonBody(t, w.Body.Bytes())["fields"].(map[string]any); !ok || fields["name"] == nil {
		t.Errorf("422 应在 fields.name 说明原因: %s", w.Body.String())
	}

	// 改名同样受限
	w = e.do(http.MethodPatch, "/api/folders/"+id, map[string]any{"name": tooLong}, cookie)
	if w.Code != http.StatusUnprocessableEntity {
		t.Errorf("改名超长应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// rune 而非字节：16 个汉字 + 16 个 emoji 仍是 32 rune
	mixed := strings.Repeat("字", 16) + strings.Repeat("📚", 16)
	if w := e.do(http.MethodPatch, "/api/folders/"+id, map[string]any{"name": mixed}, cookie); w.Code != http.StatusOK {
		t.Errorf("32 个 rune 的多字节名字应允许，实际 %d: %s", w.Code, w.Body.String())
	}
}

// TestNotePublishAuditUsername 覆盖 audit.md 2 规则 3：
// actor_username 必须是快照，不能为空串。
func TestNotePublishAuditUsername(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "要公开的笔记"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d", w.Code)
	}
	id := jsonBody(t, w.Body.Bytes())["id"].(string)

	if w := e.do(http.MethodPost, "/api/notes/"+id+"/publish", nil, cookie); w.Code != http.StatusOK {
		t.Fatalf("发布失败: %d: %s", w.Code, w.Body.String())
	}
	if w := e.do(http.MethodPost, "/api/notes/"+id+"/unpublish", nil, cookie); w.Code != http.StatusOK {
		t.Fatalf("撤回失败: %d: %s", w.Code, w.Body.String())
	}

	var names []string
	rows, err := e.db.Query(
		`SELECT actor_username FROM audit_events
		 WHERE event_type IN ('note_published','note_unpublished')
		 ORDER BY created_at`)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			t.Fatal(err)
		}
		names = append(names, name)
	}
	if len(names) != 2 {
		t.Fatalf("应有 2 条笔记审计事件，实际 %d", len(names))
	}
	for _, name := range names {
		if name != "kairo" {
			t.Errorf("actor_username = %q，期望 kairo", name)
		}
	}
}

// TestSearchUsesInjectedVisibility 覆盖 auth.md 6.3：
// 私有搜索必须走中间件注入的可见性条件，且不能因 OR 优先级把过滤绕开。
func TestSearchUsesInjectedVisibility(t *testing.T) {
	e, cookie := newUserEnv(t)

	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "alpha 私有", "content": "alpha"}, cookie)
	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "beta 噪声", "content": "beta"}, cookie)

	// 关键词 alpha 只应命中一篇——若可见性条件未加括号，OR 会把结果放大到全部
	w := e.do(http.MethodGet, "/api/search?q=alpha", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("搜索状态码 = %d: %s", w.Code, w.Body.String())
	}
	var res struct {
		Notes struct {
			Total int `json:"total"`
		} `json:"notes"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
		t.Fatal(err)
	}
	if res.Notes.Total != 1 {
		t.Errorf("搜索应只命中 1 篇，实际 %d（可见性条件可能未加括号）", res.Notes.Total)
	}

	// 别人不可见的笔记不应出现在自己的搜索结果里
	otherID := createSecondUser(t, e)
	e.userID = otherID
	otherCookie := e.loginNoTotp("other", "another-strong-password")
	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "alpha 别人的私有", "content": "alpha"}, otherCookie)

	w = e.do(http.MethodGet, "/api/search?q=alpha", nil, cookie)
	if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
		t.Fatal(err)
	}
	if res.Notes.Total != 1 {
		t.Errorf("跨用户私有笔记不应出现在搜索结果里，实际 total=%d", res.Notes.Total)
	}
}
