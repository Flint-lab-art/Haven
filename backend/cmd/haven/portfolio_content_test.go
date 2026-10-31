package main

import (
	"net/http"
	"testing"
)

// 作品集介绍正文（docs/v3/api.md 第二、三节）：
// 私有域可写可读，公开详情页能拿到正文，公开列表不带正文。

// TestPortfolioContent 覆盖作品的正文写入与公开读取。
func TestPortfolioContent(t *testing.T) {
	e, cookie := newUserEnv(t)

	const intro = "# 官网检索器\n\n用 Playwright 做官网收录检索。\n\n## 特性\n\n- 多任务并行\n- 断点续跑"

	w := e.do(http.MethodPost, "/api/portfolio", map[string]any{
		"title":       "官网检索器",
		"description": "官网收录检索工具",
		"content":     intro,
		"sort_order":  0,
	}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建作品失败: %d: %s", w.Code, w.Body.String())
	}
	id := jsonBody(t, w.Body.Bytes())["id"].(string)

	if got := jsonBody(t, w.Body.Bytes())["content"]; got != intro {
		t.Errorf("创建响应应带回正文，实际 %v", got)
	}

	// 公开列表：不带正文
	w = e.do(http.MethodGet, "/api/public/portfolio", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("公开列表应 200，实际 %d", w.Code)
	}
	items, _ := listBody(t, w.Body.Bytes())
	if len(items) != 1 {
		t.Fatalf("应有 1 个作品，实际 %d", len(items))
	}
	if _, has := items[0]["content"]; has {
		t.Errorf("公开列表不应返回正文（content，omitempty 应省略空值，但这里有内容）")
	}

	// 公开详情：带正文
	w = e.do(http.MethodGet, "/api/public/portfolio/"+id, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("公开详情应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	body := jsonBody(t, w.Body.Bytes())
	if body["content"] != intro {
		t.Errorf("公开详情应返回正文，实际 %q", body["content"])
	}
	if body["title"] != "官网检索器" {
		t.Errorf("公开详情标题不对: %v", body["title"])
	}

	// PATCH 更新正文
	const updated = "改过的介绍"
	w = e.do(http.MethodPatch, "/api/portfolio/"+id, map[string]any{"content": updated}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("更新正文应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes())["content"]; got != updated {
		t.Errorf("更新后正文应为 %q，实际 %v", updated, got)
	}

	// 只改标题不应清空正文
	w = e.do(http.MethodPatch, "/api/portfolio/"+id, map[string]any{"title": "新标题"}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("更新标题应 200，实际 %d", w.Code)
	}
	if got := jsonBody(t, w.Body.Bytes())["content"]; got != updated {
		t.Errorf("只改标题后正文应保持不变，实际 %v", got)
	}
}

// TestPortfolioContentDefaultsEmpty 覆盖不传 content 时默认空串。
func TestPortfolioContentDefaultsEmpty(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/portfolio", map[string]any{"title": "无正文作品"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建作品失败: %d: %s", w.Code, w.Body.String())
	}
	id := jsonBody(t, w.Body.Bytes())["id"].(string)

	w = e.do(http.MethodGet, "/api/public/portfolio/"+id, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("公开详情应 200，实际 %d", w.Code)
	}
	// content 为空串时被 omitempty 省略，等价于「没有正文」
	if got, has := jsonBody(t, w.Body.Bytes())["content"]; has && got != "" {
		t.Errorf("未写正文时应为空，实际 %v", got)
	}
}

// TestPortfolioDetailNotFound 覆盖不存在的作品返回 404。
func TestPortfolioDetailNotFound(t *testing.T) {
	e, _ := newUserEnv(t)

	w := e.do(http.MethodGet, "/api/public/portfolio/00000000-0000-0000-0000-000000000000", nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("不存在的作品应 404，实际 %d: %s", w.Code, w.Body.String())
	}
}

// TestPortfolioPrivateDetail 覆盖私有域详情接口（docs/v3/api.md 1.2）。
//
// 私有域列表用的是公开列表接口，不返回正文，编辑器必须能单独取到它。
func TestPortfolioPrivateDetail(t *testing.T) {
	e, cookie := newUserEnv(t)

	const intro = "正文内容，用于公开详情页"
	w := e.do(http.MethodPost, "/api/portfolio", map[string]any{
		"title":   "带正文的作品",
		"content": intro,
	}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建作品失败: %d: %s", w.Code, w.Body.String())
	}
	id := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 私有详情带正文
	w = e.do(http.MethodGet, "/api/portfolio/"+id, nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("私有详情应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes())["content"]; got != intro {
		t.Errorf("私有详情应返回正文 %q，实际 %v", intro, got)
	}

	// 匿名访问私有详情应 401
	if w := e.do(http.MethodGet, "/api/portfolio/"+id, nil); w.Code != http.StatusUnauthorized {
		t.Errorf("匿名访问私有详情应 401，实际 %d", w.Code)
	}

	// 他人访问应 404
	e.createUser("other", "another-horse-battery")
	otherCookie := e.loginNoTotp("other", "another-horse-battery")
	if w := e.do(http.MethodGet, "/api/portfolio/"+id, nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("他人访问私有详情应 404，实际 %d", w.Code)
	}
}
