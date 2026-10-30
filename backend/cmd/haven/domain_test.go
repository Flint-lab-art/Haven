package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/kairo/haven/internal/auth"
)

// 笔记 / 标签 / 搜索 / 作品集的端到端测试，逐条对照 docs/api.md 第六至十节。

// newUserEnv 建一个用户并返回已登录会话 cookie。
func newUserEnv(t *testing.T) (*testEnv, *http.Cookie) {
	t.Helper()
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	return e, e.loginNoTotp("kairo", "correct-horse-battery")
}

// jsonBody 把响应体解析成 map。
func jsonBody(t *testing.T, body []byte) map[string]any {
	t.Helper()
	var m map[string]any
	if err := json.Unmarshal(body, &m); err != nil {
		t.Fatalf("响应不是合法 JSON: %v (%s)", err, body)
	}
	return m
}

// listBody 解析 {items, total}。
func listBody(t *testing.T, body []byte) ([]map[string]any, int) {
	t.Helper()
	var out struct {
		Items []map[string]any `json:"items"`
		Total int              `json:"total"`
	}
	if err := json.Unmarshal(body, &out); err != nil {
		t.Fatalf("列表响应解析失败: %v (%s)", err, body)
	}
	// api.md 1.3：空列表必须是 []，不能是 null
	if string(body) != "" && contains(string(body), `"items":null`) {
		t.Fatalf("空列表不能返回 null: %s", body)
	}
	return out.Items, out.Total
}

// ---------- 笔记私有侧（api.md 六） ----------

func TestNotesCRUD(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 创建：不接受 visibility，即使传了也一律 private（api.md 6.3）
	w := e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "第一篇", "content": "正文内容", "visibility": "public"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建状态码 = %d: %s", w.Code, w.Body.String())
	}
	created := jsonBody(t, w.Body.Bytes())
	id, _ := created["id"].(string)
	if created["visibility"] != "private" {
		t.Errorf("新建笔记必须为 private，实际 %v", created["visibility"])
	}
	if created["published_at"] != nil {
		t.Error("新建笔记 published_at 应为 null")
	}

	// 详情
	w = e.do(http.MethodGet, "/api/notes/"+id, nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("详情状态码 = %d", w.Code)
	}

	// 列表：不含 content，含 content_preview
	w = e.do(http.MethodGet, "/api/notes", nil, cookie)
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 {
		t.Fatalf("列表应 1 条，实际 total=%d", total)
	}
	if _, ok := items[0]["content"]; ok {
		t.Error("列表不应返回 content")
	}
	if items[0]["content_preview"] != "正文内容" {
		t.Errorf("content_preview 异常: %v", items[0]["content_preview"])
	}
	// 无标签时返回空数组而不是 null
	if tags, ok := items[0]["tags"].([]any); !ok || len(tags) != 0 {
		t.Errorf("无标签时应返回空数组，实际 %v", items[0]["tags"])
	}

	// 部分更新：只改 title，content 不变（api.md 1.7）
	w = e.do(http.MethodPatch, "/api/notes/"+id, map[string]any{"title": "改名了"}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("更新状态码 = %d: %s", w.Code, w.Body.String())
	}
	updated := jsonBody(t, w.Body.Bytes())
	if updated["title"] != "改名了" {
		t.Errorf("title 未更新: %v", updated["title"])
	}
	if updated["content"] != "正文内容" {
		t.Errorf("未出现的 content 不应被改，实际 %v", updated["content"])
	}

	// 删除
	if w := e.do(http.MethodDelete, "/api/notes/"+id, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除状态码 = %d", w.Code)
	}
	if w := e.do(http.MethodGet, "/api/notes/"+id, nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("删除后详情应 404，实际 %d", w.Code)
	}
}

func TestNotesContentPreview(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 201 个中文字符：截断为 200 字 + …（按 rune，不按字节）
	content := ""
	for i := 0; i < 201; i++ {
		content += "字"
	}
	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "长文", "content": content}, cookie)

	w := e.do(http.MethodGet, "/api/notes", nil, cookie)
	items, _ := listBody(t, w.Body.Bytes())
	preview, _ := items[0]["content_preview"].(string)

	runes := []rune(preview)
	if len(runes) != 201 { // 200 字 + '…'
		t.Errorf("preview 长度应为 201 个字符，实际 %d", len(runes))
	}
	if runes[len(runes)-1] != '…' {
		t.Errorf("截断后应以 … 结尾，实际 %q", string(runes[len(runes)-1]))
	}
}

func TestNotesTitleRequired(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "   "}, cookie)
	if w.Code != http.StatusUnprocessableEntity {
		t.Fatalf("空标题应 422，实际 %d", w.Code)
	}
	if body := jsonBody(t, w.Body.Bytes()); body["fields"] == nil {
		t.Error("422 应带 fields（api.md 1.4）")
	}
}

func TestNotesTagValidation(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 不存在的标签：422
	w := e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "带标签", "tag_ids": []string{"00000000-0000-0000-0000-000000000000"}}, cookie)
	if w.Code != http.StatusUnprocessableEntity {
		t.Fatalf("无效标签应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 正常挂标签
	w = e.do(http.MethodPost, "/api/tags", map[string]any{"name": "编程"}, cookie)
	tag := jsonBody(t, w.Body.Bytes())
	tagID, _ := tag["id"].(string)

	w = e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "带标签", "tag_ids": []string{tagID, tagID}}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建带标签笔记状态码 = %d: %s", w.Code, w.Body.String())
	}
	note := jsonBody(t, w.Body.Bytes())
	tags, _ := note["tags"].([]any)
	if len(tags) != 1 {
		t.Errorf("重复 tag_id 应去重，实际 %d 个", len(tags))
	}
}

func TestNotesTagIdsFullReplace(t *testing.T) {
	e, cookie := newUserEnv(t)

	var tagIDs []string
	for _, name := range []string{"A", "B"} {
		w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": name}, cookie)
		tag := jsonBody(t, w.Body.Bytes())
		id, _ := tag["id"].(string)
		tagIDs = append(tagIDs, id)
	}

	w := e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "笔记", "tag_ids": tagIDs}, cookie)
	note := jsonBody(t, w.Body.Bytes())
	noteID, _ := note["id"].(string)

	// 全量替换为单个标签
	w = e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"tag_ids": []string{tagIDs[0]}}, cookie)
	updated := jsonBody(t, w.Body.Bytes())
	tags, _ := updated["tags"].([]any)
	if len(tags) != 1 {
		t.Fatalf("tag_ids 应为全量替换，实际 %d 个", len(tags))
	}
	if first, _ := tags[0].(map[string]any); first["id"] != tagIDs[0] {
		t.Errorf("应保留指定标签，实际 %v", tags[0])
	}

	// 空数组 = 清空
	w = e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"tag_ids": []string{}}, cookie)
	updated = jsonBody(t, w.Body.Bytes())
	tags, _ = updated["tags"].([]any)
	if len(tags) != 0 {
		t.Errorf("空数组应清空标签，实际 %v", tags)
	}
}

func TestNotesPublishUnpublish(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "要公开"}, cookie)
	note := jsonBody(t, w.Body.Bytes())
	id, _ := note["id"].(string)

	// publish
	w = e.do(http.MethodPost, "/api/notes/"+id+"/publish", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("publish 状态码 = %d: %s", w.Code, w.Body.String())
	}
	published := jsonBody(t, w.Body.Bytes())
	if published["visibility"] != "public" || published["published_at"] == nil {
		t.Fatalf("publish 后应为 public 且有 published_at: %v", published)
	}
	firstPublishedAt := published["published_at"]

	// 重复 publish：409（api.md 6.6）
	if w := e.do(http.MethodPost, "/api/notes/"+id+"/publish", nil, cookie); w.Code != http.StatusConflict {
		t.Errorf("重复 publish 应 409，实际 %d", w.Code)
	}

	// unpublish：published_at 保留
	w = e.do(http.MethodPost, "/api/notes/"+id+"/unpublish", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("unpublish 状态码 = %d", w.Code)
	}
	unpublished := jsonBody(t, w.Body.Bytes())
	if unpublished["visibility"] != "private" {
		t.Errorf("unpublish 后应为 private")
	}
	if unpublished["published_at"] != firstPublishedAt {
		t.Errorf("撤回应保留 published_at，期望 %v 实际 %v", firstPublishedAt, unpublished["published_at"])
	}

	// 重复 unpublish：409
	if w := e.do(http.MethodPost, "/api/notes/"+id+"/unpublish", nil, cookie); w.Code != http.StatusConflict {
		t.Errorf("重复 unpublish 应 409，实际 %d", w.Code)
	}

	// 再次 publish 不覆盖首次发布时间（data-model.md 第三节规则 3）
	w = e.do(http.MethodPost, "/api/notes/"+id+"/publish", nil, cookie)
	republished := jsonBody(t, w.Body.Bytes())
	if republished["published_at"] != firstPublishedAt {
		t.Errorf("再次公开不应覆盖首次发布时间")
	}

	// publish 会写审计（audit.md 第三节）
	if _, ok := e.findAudit("note_published"); !ok {
		t.Error("publish 应写 note_published 审计")
	}
	if _, ok := e.findAudit("note_unpublished"); !ok {
		t.Error("unpublish 应写 note_unpublished 审计")
	}
}

func TestNotesCrossUserIsolation(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "私有笔记"}, cookie)
	note := jsonBody(t, w.Body.Bytes())
	id, _ := note["id"].(string)
	e.do(http.MethodPost, "/api/notes/"+id+"/publish", nil, cookie)

	// 另一个用户的视角：看不到别人的私有笔记
	otherID := createSecondUser(t, e)
	e.userID = otherID
	otherCookie := e.loginNoTotp("other", "another-strong-password")

	if w := e.do(http.MethodGet, "/api/notes/"+id, nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("跨用户读私有笔记应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodPatch, "/api/notes/"+id, map[string]any{"title": "x"}, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("跨用户改笔记应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodDelete, "/api/notes/"+id, nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("跨用户删笔记应 404，实际 %d", w.Code)
	}

	// 别人已 public 的笔记，登录用户也能通过公开接口读到
	if w := e.do(http.MethodGet, "/api/public/notes/"+id, nil); w.Code != http.StatusOK {
		t.Errorf("公开笔记应可匿名读取，实际 %d", w.Code)
	}
}

// createSecondUser 插入第二个用户（本期只有初始化脚本能建账号，测试里直连）。
func createSecondUser(t *testing.T, e *testEnv) string {
	t.Helper()
	hash, err := auth.HashPassword("another-strong-password")
	if err != nil {
		t.Fatal(err)
	}
	var id string
	if err := e.db.QueryRow(
		`INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id`,
		"other", hash).Scan(&id); err != nil {
		t.Fatalf("插入第二个用户失败: %v", err)
	}
	return id
}

// ---------- 笔记公开侧（api.md 七） ----------

func TestPublicNotes(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 一篇 private、一篇 public
	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "私密"}, cookie)
	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "公开的", "content": "正文"}, cookie)
	pub := jsonBody(t, w.Body.Bytes())
	pubID, _ := pub["id"].(string)
	e.do(http.MethodPost, "/api/notes/"+pubID+"/publish", nil, cookie)

	// 列表：匿名可访问，只含 public
	w = e.do(http.MethodGet, "/api/public/notes", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("公开列表状态码 = %d", w.Code)
	}
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 {
		t.Fatalf("公开列表应只有 1 篇，实际 %d", total)
	}
	if items[0]["title"] != "公开的" {
		t.Errorf("公开列表内容异常: %v", items[0]["title"])
	}
	if _, ok := items[0]["visibility"]; ok {
		t.Error("公开列表不应返回 visibility（api.md 7.1）")
	}

	// 详情
	if w := e.do(http.MethodGet, "/api/public/notes/"+pubID, nil); w.Code != http.StatusOK {
		t.Errorf("公开详情状态码 = %d", w.Code)
	}

	// private 笔记的公开详情一律 404
	w = e.do(http.MethodPost, "/api/notes", map[string]any{"title": "私密2"}, cookie)
	priv := jsonBody(t, w.Body.Bytes())
	privID, _ := priv["id"].(string)
	if w := e.do(http.MethodGet, "/api/public/notes/"+privID, nil); w.Code != http.StatusNotFound {
		t.Errorf("private 笔记公开接口应 404，实际 %d", w.Code)
	}
}

func TestPublicNotesExcludesPublishedAtNull(t *testing.T) {
	// 直接构造 visibility=public 但 published_at 为空的数据，
	// 验证「唯一判定条件」生效（data-model.md 第三节规则 4）
	e, _ := newUserEnv(t)

	var id string
	if err := e.db.QueryRow(
		`INSERT INTO notes (user_id, title, visibility) VALUES ($1, '脏数据', 'public') RETURNING id`,
		e.userID).Scan(&id); err != nil {
		t.Fatal(err)
	}

	items, total := listBody(t, e.do(http.MethodGet, "/api/public/notes", nil).Body.Bytes())
	if total != 0 || len(items) != 0 {
		t.Errorf("published_at 为空的 public 笔记不应出现在公开列表，实际 %d", total)
	}
	if w := e.do(http.MethodGet, "/api/public/notes/"+id, nil); w.Code != http.StatusNotFound {
		t.Errorf("published_at 为空的 public 笔记详情应 404，实际 %d", w.Code)
	}
}

// ---------- 标签（api.md 八） ----------

func TestTagsCRUD(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "编程"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建标签状态码 = %d: %s", w.Code, w.Body.String())
	}
	tag := jsonBody(t, w.Body.Bytes())
	if tag["note_count"] != float64(0) {
		t.Errorf("新标签 note_count 应为 0，实际 %v", tag["note_count"])
	}

	// 大小写不同视为重名：409（data-model.md 第四节规则 2）
	if w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "编程"}, cookie); w.Code != http.StatusConflict {
		t.Errorf("重名应 409，实际 %d", w.Code)
	}

	// 空名：422
	if w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "  "}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("空标签名应 422，实际 %d", w.Code)
	}

	// 列表
	items, total := listBody(t, e.do(http.MethodGet, "/api/tags", nil, cookie).Body.Bytes())
	if total != 1 || len(items) != 1 {
		t.Fatalf("标签列表应 1 条，实际 %d", total)
	}

	// 没有重命名接口（data-model.md 第四节规则 3）
	if w := e.do(http.MethodPatch, "/api/tags/"+tag["id"].(string), map[string]any{"name": "x"}, cookie); w.Code == http.StatusOK {
		t.Error("不应提供标签重命名接口")
	}

	// 删除
	if w := e.do(http.MethodDelete, "/api/tags/"+tag["id"].(string), nil, cookie); w.Code != http.StatusNoContent {
		t.Errorf("删除标签状态码 = %d", w.Code)
	}
}

func TestTagsNotesByTag(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "Go"}, cookie)
	tagID, _ := jsonBody(t, w.Body.Bytes())["id"].(string)

	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "带标签笔记", "tag_ids": []string{tagID}}, cookie)
	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "无标签笔记"}, cookie)

	// /api/tags/:id/notes 结构同 /api/notes（含 content_preview，api.md 8.4）
	w = e.do(http.MethodGet, "/api/tags/"+tagID+"/notes", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("按标签查笔记状态码 = %d: %s", w.Code, w.Body.String())
	}
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 {
		t.Fatalf("应只有 1 篇带标签笔记，实际 %d", total)
	}
	if _, ok := items[0]["content_preview"]; !ok {
		t.Error("按标签查笔记应含 content_preview（api.md 8.4）")
	}

	// 标签属主校验：别人的标签 → 404
	otherID := createSecondUser(t, e)
	_ = otherID
	e.userID = otherID
	otherCookie := e.loginNoTotp("other", "another-strong-password")
	if w := e.do(http.MethodGet, "/api/tags/"+tagID+"/notes", nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("跨用户查标签笔记应 404，实际 %d", w.Code)
	}
}

// ---------- 搜索（api.md 九） ----------

func TestSearchPrivate(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "编程语言"}, cookie)
	tagID, _ := jsonBody(t, w.Body.Bytes())["id"].(string)

	e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "Go 并发", "content": "goroutine 调度", "tag_ids": []string{tagID}}, cookie)
	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "无关内容", "content": "别的"}, cookie)

	// 搜正文命中（走 search_text，不直接查 title/content）
	w = e.do(http.MethodGet, "/api/search?q=goroutine", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("搜索状态码 = %d: %s", w.Code, w.Body.String())
	}
	var res struct {
		Notes struct {
			Items []map[string]any `json:"items"`
			Total int              `json:"total"`
		} `json:"notes"`
		Tags struct {
			Items []map[string]any `json:"items"`
			Total int              `json:"total"`
		} `json:"tags"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
		t.Fatal(err)
	}
	if res.Notes.Total != 1 {
		t.Errorf("搜正文应命中 1 篇，实际 %d", res.Notes.Total)
	}
	if res.Tags.Total != 0 {
		t.Errorf("该关键词不应命中标签，实际 %d", res.Tags.Total)
	}

	// 搜标题
	w = e.do(http.MethodGet, "/api/search?q=并发", nil, cookie)
	_ = json.Unmarshal(w.Body.Bytes(), &res)
	if res.Notes.Total != 1 {
		t.Errorf("搜标题应命中 1 篇，实际 %d", res.Notes.Total)
	}

	// 搜标签
	w = e.do(http.MethodGet, "/api/search?q=编程", nil, cookie)
	_ = json.Unmarshal(w.Body.Bytes(), &res)
	if res.Tags.Total != 1 {
		t.Errorf("应命中 1 个标签，实际 %d", res.Tags.Total)
	}
	if res.Tags.Items[0]["note_count"] == nil {
		t.Error("标签结果应含 note_count（api.md 9.1）")
	}

	// q 必填
	if w := e.do(http.MethodGet, "/api/search", nil, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("缺少 q 应 422，实际 %d", w.Code)
	}

	// 通配符按字面处理：% 不应匹配全部
	w = e.do(http.MethodGet, "/api/search?q=%25", nil, cookie)
	_ = json.Unmarshal(w.Body.Bytes(), &res)
	if res.Notes.Total != 0 {
		t.Errorf("关键词 %% 不应被当作通配符，实际命中 %d", res.Notes.Total)
	}
}

func TestSearchPublic(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "公开可见", "content": "secretword"}, cookie)
	note := jsonBody(t, w.Body.Bytes())
	id, _ := note["id"].(string)
	e.do(http.MethodPost, "/api/notes/"+id+"/publish", nil, cookie)

	// 未公开的笔记搜不到
	e.do(http.MethodPost, "/api/notes", map[string]any{"title": "私有可见", "content": "secretword"}, cookie)

	w = e.do(http.MethodGet, "/api/public/search?q=secretword", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("公开搜索状态码 = %d", w.Code)
	}
	var res struct {
		Items []map[string]any `json:"items"`
		Total int              `json:"total"`
	}
	_ = json.Unmarshal(w.Body.Bytes(), &res)
	if res.Total != 1 {
		t.Errorf("公开搜索只应命中已公开笔记，实际 %d", res.Total)
	}
	// 不返回标签列表（api.md 9.2）
	var raw map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &raw)
	if _, ok := raw["tags"]; ok {
		t.Error("公开搜索不应返回标签列表")
	}
}

// ---------- 作品集（api.md 十） ----------

func TestPortfolioCRUD(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/portfolio",
		map[string]any{"title": "Haven", "description": "知识中台", "sort_order": 1}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建作品状态码 = %d: %s", w.Code, w.Body.String())
	}
	item := jsonBody(t, w.Body.Bytes())
	id, _ := item["id"].(string)
	if repos, ok := item["repos"].([]any); !ok || len(repos) != 0 {
		t.Errorf("新作品 repos 应为空数组，实际 %v", item["repos"])
	}

	// 加两个仓库：gogs 主链接 + github
	w = e.do(http.MethodPost, "/api/portfolio/"+id+"/repos",
		map[string]any{"platform": "gogs", "repo_path": "kairo/haven", "is_primary": true}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("加仓库状态码 = %d: %s", w.Code, w.Body.String())
	}
	gogsRepo := jsonBody(t, w.Body.Bytes())
	// url 由后端拼接（data-model.md 第七节规则 1）
	if gogsRepo["url"] != "https://gogs.example.com/kairo/haven" {
		t.Errorf("gogs url 拼接错误: %v", gogsRepo["url"])
	}

	w = e.do(http.MethodPost, "/api/portfolio/"+id+"/repos",
		map[string]any{"platform": "github", "repo_path": "kairo/haven"}, cookie)
	ghRepo := jsonBody(t, w.Body.Bytes())
	if ghRepo["url"] != "https://github.com/kairo/haven" {
		t.Errorf("github url 拼接错误: %v", ghRepo["url"])
	}

	// 重复仓库：409
	if w := e.do(http.MethodPost, "/api/portfolio/"+id+"/repos",
		map[string]any{"platform": "github", "repo_path": "kairo/haven"}, cookie); w.Code != http.StatusConflict {
		t.Errorf("重复仓库应 409，实际 %d", w.Code)
	}

	// 第二个主链接：409
	if w := e.do(http.MethodPost, "/api/portfolio/"+id+"/repos",
		map[string]any{"platform": "github", "repo_path": "other/repo", "is_primary": true}, cookie); w.Code != http.StatusConflict {
		t.Errorf("已有主链接时再加主链接应 409，实际 %d", w.Code)
	}

	// 非法 platform：422
	if w := e.do(http.MethodPost, "/api/portfolio/"+id+"/repos",
		map[string]any{"platform": "gitlab", "repo_path": "a/b"}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("非法 platform 应 422，实际 %d", w.Code)
	}

	// 公开列表
	w = e.do(http.MethodGet, "/api/public/portfolio", nil)
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 {
		t.Fatalf("作品集应 1 条，实际 %d", total)
	}
	repos, _ := items[0]["repos"].([]any)
	if len(repos) != 2 {
		t.Fatalf("应含 2 个仓库，实际 %d", len(repos))
	}
	// 主链接优先排在前面
	first, _ := repos[0].(map[string]any)
	if first["is_primary"] != true {
		t.Error("列表应把主链接排在前面")
	}

	// 改仓库路径
	ghID, _ := ghRepo["id"].(string)
	w = e.do(http.MethodPatch, "/api/portfolio/"+id+"/repos/"+ghID,
		map[string]any{"repo_path": "kairo/haven-v2"}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("改仓库状态码 = %d: %s", w.Code, w.Body.String())
	}
	if updated := jsonBody(t, w.Body.Bytes()); updated["url"] != "https://github.com/kairo/haven-v2" {
		t.Errorf("改路径后 url 应重算，实际 %v", updated["url"])
	}

	// 删仓库
	if w := e.do(http.MethodDelete, "/api/portfolio/"+id+"/repos/"+ghID, nil, cookie); w.Code != http.StatusNoContent {
		t.Errorf("删仓库状态码 = %d", w.Code)
	}

	// 改作品（部分更新）
	w = e.do(http.MethodPatch, "/api/portfolio/"+id, map[string]any{"sort_order": 5}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("更新作品状态码 = %d", w.Code)
	}
	if got := jsonBody(t, w.Body.Bytes()); got["sort_order"] != float64(5) {
		t.Errorf("sort_order 未更新，实际 %v", got["sort_order"])
	}

	// 删作品
	if w := e.do(http.MethodDelete, "/api/portfolio/"+id, nil, cookie); w.Code != http.StatusNoContent {
		t.Errorf("删作品状态码 = %d", w.Code)
	}
	if items, total := listBody(t, e.do(http.MethodGet, "/api/public/portfolio", nil).Body.Bytes()); total != 0 || len(items) != 0 {
		t.Error("删除后作品集应为空")
	}
}

func TestPortfolioSortOrder(t *testing.T) {
	e, cookie := newUserEnv(t)

	for _, it := range []struct {
		title string
		order int
	}{{"B", 2}, {"A", 1}} {
		e.do(http.MethodPost, "/api/portfolio",
			map[string]any{"title": it.title, "sort_order": it.order}, cookie)
	}

	items, _ := listBody(t, e.do(http.MethodGet, "/api/public/portfolio", nil).Body.Bytes())
	if len(items) != 2 {
		t.Fatalf("应 2 条，实际 %d", len(items))
	}
	if items[0]["title"] != "A" {
		t.Errorf("应按 sort_order 升序，首条应为 A，实际 %v", items[0]["title"])
	}
}

// ---------- 权限矩阵抽查（api.md 1.6 / auth.md 七） ----------

func TestWritePermissionWithTokens(t *testing.T) {
	e, cookie := newUserEnv(t)
	e.enableTotpAndLogin(t, cookie)

	// read Token：能读不能写
	readTok := e.createToken(t, auth.ScopeRead)
	if w := e.doWithToken(http.MethodGet, "/api/notes", readTok); w.Code != http.StatusOK {
		t.Errorf("read Token 读笔记应 200，实际 %d", w.Code)
	}
	if w := e.doWithToken(http.MethodPost, "/api/notes", readTok); w.Code != http.StatusForbidden {
		t.Errorf("read Token 写应 403，实际 %d", w.Code)
	}
	// 凭证类操作一律 403
	for _, path := range []string{"/api/sessions", "/api/trusted-devices", "/api/tokens"} {
		if w := e.doWithToken(http.MethodGet, path, readTok); w.Code != http.StatusForbidden {
			t.Errorf("Token 访问 %s 应 403，实际 %d", path, w.Code)
		}
	}

	// read_write Token：能写
	rwTok := e.createToken(t, auth.ScopeReadWrite)
	req := httptest.NewRequest(http.MethodPost, "/api/notes", bytes.NewReader([]byte(`{"title":"用 Token 建"}`)))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+rwTok)
	w := httptest.NewRecorder()
	e.router.ServeHTTP(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("read_write Token 创建笔记应 201，实际 %d: %s", w.Code, w.Body.String())
	}
	// 但凭证类仍然 403
	if w := e.doWithToken(http.MethodPost, "/api/tokens", rwTok); w.Code != http.StatusForbidden {
		t.Errorf("read_write Token 也不能建 Token，实际 %d", w.Code)
	}
}

// enableTotpAndLogin 启用 TOTP 并用通过 TOTP 的新会话替换 e 的登录态。
func (e *testEnv) enableTotpAndLogin(t *testing.T, cookie *http.Cookie) {
	t.Helper()
	secret := enableTotp(t, e, cookie)
	e.loginWithTotp("kairo", "correct-horse-battery", secret)
}

// createToken 用「通过 TOTP 的会话」建一个 Token，返回明文。
func (e *testEnv) createToken(t *testing.T, scope string) string {
	t.Helper()
	secret := e.currentTotpSecret(t)
	cookie := e.loginWithTotp("kairo", "correct-horse-battery", secret)

	w := e.do(http.MethodPost, "/api/tokens", map[string]any{"name": "t-" + scope, "scope": scope}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建 %s Token 状态码 = %d: %s", scope, w.Code, w.Body.String())
	}
	token, _ := jsonBody(t, w.Body.Bytes())["token"].(string)
	return token
}

// currentTotpSecret 读取库里当前的 TOTP secret。
func (e *testEnv) currentTotpSecret(t *testing.T) string {
	t.Helper()
	var secret sql.NullString
	if err := e.db.QueryRow(`SELECT totp_secret FROM users WHERE id = $1`, e.userID).Scan(&secret); err != nil {
		t.Fatal(err)
	}
	return secret.String
}
