package main

import (
	"encoding/json"
	"net/http"
	"testing"
	"time"
)

// 首页统计（docs/v5/api.md 第一节）。

// statsBody 解析 GET /api/stats 的响应。
type statsBody struct {
	Totals struct {
		Notes       int   `json:"notes"`
		Words       int64 `json:"words"`
		PublicNotes int   `json:"public_notes"`
	} `json:"totals"`
	Week struct {
		Created int `json:"created"`
		Updated int `json:"updated"`
	} `json:"week"`
	Heatmap []struct {
		Date  string `json:"date"`
		Count int    `json:"count"`
	} `json:"heatmap"`
	Recent []struct {
		ID         string `json:"id"`
		Title      string `json:"title"`
		UpdatedAt  string `json:"updated_at"`
		Visibility string `json:"visibility"`
	} `json:"recent"`
}

func getStats(t *testing.T, e *testEnv, cookie *http.Cookie) statsBody {
	t.Helper()
	w := e.do(http.MethodGet, "/api/stats", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("统计接口应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	var b statsBody
	if err := json.Unmarshal(w.Body.Bytes(), &b); err != nil {
		t.Fatalf("解析统计响应失败: %v", err)
	}
	return b
}

// TestStatsEmpty 覆盖空账号：数字全为 0，热力图仍返回完整序列。
func TestStatsEmpty(t *testing.T) {
	e, cookie := newUserEnv(t)
	b := getStats(t, e, cookie)

	if b.Totals.Notes != 0 || b.Totals.Words != 0 || b.Totals.PublicNotes != 0 {
		t.Errorf("空账号统计应为 0，实际 %+v", b.Totals)
	}
	if len(b.Heatmap) == 0 {
		t.Fatalf("热力图应返回完整日期序列，实际为空")
	}
	if len(b.Recent) != 0 {
		t.Errorf("最近编辑应为空，实际 %d 条", len(b.Recent))
	}
}

// TestStatsTotals 覆盖笔记数、字数与公开数。
func TestStatsTotals(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 两篇笔记：一篇中文 5 字，一篇公开
	create := func(payload map[string]any) string {
		w := e.do(http.MethodPost, "/api/notes", payload, cookie)
		if w.Code != http.StatusCreated {
			t.Fatalf("创建笔记失败: %d: %s", w.Code, w.Body.String())
		}
		return jsonBody(t, w.Body.Bytes())["id"].(string)
	}
	create(map[string]any{"title": "私有", "content": "一二三四五"})
	pubID := create(map[string]any{"title": "公开", "content": "abc"})

	if w := e.do(http.MethodPost, "/api/notes/"+pubID+"/publish", nil, cookie); w.Code != http.StatusOK {
		t.Fatalf("发布失败: %d", w.Code)
	}

	b := getStats(t, e, cookie)
	if b.Totals.Notes != 2 {
		t.Errorf("笔记数应为 2，实际 %d", b.Totals.Notes)
	}
	// 字数只算正文：5 + 3 = 8
	if b.Totals.Words != 8 {
		t.Errorf("字数应为 8，实际 %d", b.Totals.Words)
	}
	if b.Totals.PublicNotes != 1 {
		t.Errorf("公开数应为 1，实际 %d", b.Totals.PublicNotes)
	}
}

// TestStatsExcludesTrashed 覆盖：回收站里的笔记不计入任何统计。
func TestStatsExcludesTrashed(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "会被删", "content": "内容"}, cookie)
	id := jsonBody(t, w.Body.Bytes())["id"].(string)
	before := getStats(t, e, cookie)

	if w := e.do(http.MethodDelete, "/api/notes/"+id, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除失败: %d", w.Code)
	}

	after := getStats(t, e, cookie)
	if after.Totals.Notes != before.Totals.Notes-1 {
		t.Errorf("回收站笔记不应计入，删除前 %d 删除后 %d", before.Totals.Notes, after.Totals.Notes)
	}
	if after.Totals.Words != before.Totals.Words-2 {
		t.Errorf("回收站笔记的字数不应计入")
	}
	for _, r := range after.Recent {
		if r.ID == id {
			t.Errorf("回收站笔记不应出现在最近编辑里")
		}
	}
}

// TestStatsHeatmap 覆盖热力图的日期序列与计数。
func TestStatsHeatmap(t *testing.T) {
	e, cookie := newUserEnv(t)
	create := func(title string) string {
		w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": title, "content": "x"}, cookie)
		if w.Code != http.StatusCreated {
			t.Fatalf("创建失败: %d", w.Code)
		}
		return jsonBody(t, w.Body.Bytes())["id"].(string)
	}

	create("今天的笔记")

	b := getStats(t, e, cookie)
	today := time.Now().Format("2006-01-02")

	found := false
	for _, c := range b.Heatmap {
		if c.Date == today {
			found = true
			if c.Count < 1 {
				t.Errorf("今天应有编辑记录，实际 %d", c.Count)
			}
		}
	}
	if !found {
		t.Errorf("热力图应包含今天 %s", today)
	}

	// 日期按升序排列且连续
	for i := 1; i < len(b.Heatmap); i++ {
		if b.Heatmap[i].Date <= b.Heatmap[i-1].Date {
			t.Fatalf("日期应升序排列，第 %d 项 %s 不大于 %s", i, b.Heatmap[i].Date, b.Heatmap[i-1].Date)
		}
	}
}

// TestStatsHeatmapCountsDistinctNotes 覆盖：一天内同一篇改多次只算 1 次。
func TestStatsHeatmapCountsDistinctNotes(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "反复改", "content": "a"}, cookie)
	id := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 连续改三次
	for _, c := range []string{"b", "c", "d"} {
		if w := e.do(http.MethodPatch, "/api/notes/"+id, map[string]any{"content": c}, cookie); w.Code != http.StatusOK {
			t.Fatalf("更新失败: %d", w.Code)
		}
	}

	b := getStats(t, e, cookie)
	today := time.Now().Format("2006-01-02")
	for _, cell := range b.Heatmap {
		if cell.Date == today && cell.Count != 1 {
			t.Errorf("同一篇改多次应只算 1 次，实际 %d", cell.Count)
		}
	}
}

// TestStatsRecent 覆盖最近编辑：最多 5 条、按更新时间倒序。
func TestStatsRecent(t *testing.T) {
	e, cookie := newUserEnv(t)

	for i := 0; i < 7; i++ {
		w := e.do(http.MethodPost, "/api/notes", map[string]any{
			"title":   "笔记" + string(rune('A'+i)),
			"content": "x",
		}, cookie)
		if w.Code != http.StatusCreated {
			t.Fatalf("创建失败: %d", w.Code)
		}
	}

	b := getStats(t, e, cookie)
	if len(b.Recent) != 5 {
		t.Fatalf("最近编辑应固定 5 条，实际 %d", len(b.Recent))
	}
	for i := 1; i < len(b.Recent); i++ {
		if b.Recent[i].UpdatedAt > b.Recent[i-1].UpdatedAt {
			t.Errorf("最近编辑应按更新时间倒序")
		}
	}
}

// TestStatsCrossUser 覆盖：只统计当前用户。
func TestStatsCrossUser(t *testing.T) {
	e, cookie := newUserEnv(t)
	if w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "我的", "content": "x"}, cookie); w.Code != http.StatusCreated {
		t.Fatalf("创建失败: %d", w.Code)
	}

	e.createUser("other", "another-horse-battery")
	otherCookie := e.loginNoTotp("other", "another-horse-battery")

	b := getStats(t, e, otherCookie)
	if b.Totals.Notes != 0 {
		t.Errorf("他人看不到我的统计，实际笔记数 %d", b.Totals.Notes)
	}
}

// TestStatsRequiresLogin 覆盖：匿名访问 401。
func TestStatsRequiresLogin(t *testing.T) {
	e, _ := newUserEnv(t)
	if w := e.do(http.MethodGet, "/api/stats", nil); w.Code != http.StatusUnauthorized {
		t.Errorf("匿名访问统计应 401，实际 %d", w.Code)
	}
}
