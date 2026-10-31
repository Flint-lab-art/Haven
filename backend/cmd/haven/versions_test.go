package main

import (
	"net/http"
	"testing"
)

// 历史版本（docs/v2/api.md 第三节，docs/v2/backend/data-model.md 第二节）。

func createNoteForVersions(t *testing.T, e *testEnv, cookie *http.Cookie) string {
	t.Helper()
	w := e.do(http.MethodPost, "/api/notes", map[string]any{
		"title":   "原始标题",
		"content": "原始正文",
	}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d: %s", w.Code, w.Body.String())
	}
	return jsonBody(t, w.Body.Bytes())["id"].(string)
}

// TestVersionCreatedOnEdit 覆盖：标题 / 正文变化时产生快照。
func TestVersionCreatedOnEdit(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)

	// 初次编辑（新建笔记不产生快照，只有编辑才产生）
	w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"content": "第二次内容"}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("编辑失败: %d: %s", w.Code, w.Body.String())
	}

	w = e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("版本列表应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 {
		t.Fatalf("应产生 1 条快照，实际 %d", total)
	}
	if items[0]["title"] != "原始标题" {
		t.Errorf("快照应记录编辑前的标题，实际 %v", items[0]["title"])
	}
	if items[0]["content_size"] == nil {
		t.Errorf("列表应返回 content_size")
	}
	// 列表不返回正文
	if _, hasContent := items[0]["content"]; hasContent {
		t.Errorf("版本列表不应返回正文")
	}
}

// TestVersionSkippedForSortOrderOnly 覆盖：只改 sort_order 不产生快照。
func TestVersionSkippedForSortOrderOnly(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)

	if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"sort_order": 5}, cookie); w.Code != http.StatusOK {
		t.Fatalf("调整排序失败: %d: %s", w.Code, w.Body.String())
	}

	w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	_, total := listBody(t, w.Body.Bytes())
	if total != 0 {
		t.Errorf("只调 sort_order 不应产生快照，实际 %d 条", total)
	}
}

// TestVersionSkippedWhenUnchanged 覆盖：内容没变不产生快照（编辑器会重复保存）。
func TestVersionSkippedWhenUnchanged(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)

	body := map[string]any{"content": "原始正文"}
	for i := 0; i < 3; i++ {
		if w := e.do(http.MethodPatch, "/api/notes/"+noteID, body, cookie); w.Code != http.StatusOK {
			t.Fatalf("重复保存失败: %d", w.Code)
		}
	}

	w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	_, total := listBody(t, w.Body.Bytes())
	if total != 0 {
		t.Errorf("内容没变不应产生快照，实际 %d 条", total)
	}
}

// TestVersionMergeWindow 覆盖：同一笔记 5 分钟内的多次修改合并为一条。
func TestVersionMergeWindow(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)

	for _, content := range []string{"改动一", "改动二", "改动三"} {
		if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"content": content}, cookie); w.Code != http.StatusOK {
			t.Fatalf("编辑失败: %d", w.Code)
		}
	}

	w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 {
		t.Fatalf("合并窗口内应只有 1 条快照，实际 %d", total)
	}
	// 保留的是最早那条：第一次编辑前的「原始正文」
	versionID := items[0]["id"].(string)
	w = e.do(http.MethodGet, "/api/notes/"+noteID+"/versions/"+versionID, nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("取版本详情失败: %d", w.Code)
	}
	if w.Body.String() == "" || jsonBody(t, w.Body.Bytes())["content"] != "原始正文" {
		t.Errorf("合并时应保留最早的快照内容，实际 %v", jsonBody(t, w.Body.Bytes())["content"])
	}

	// 窗口外再改一次应产生第二条
	if _, err := e.db.Exec(
		`UPDATE note_versions SET created_at = now() - interval '10 minutes' WHERE note_id = $1`, noteID); err != nil {
		t.Fatalf("调整快照时间失败: %v", err)
	}
	if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"content": "窗口外改动"}, cookie); w.Code != http.StatusOK {
		t.Fatalf("编辑失败: %d", w.Code)
	}

	w = e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	if _, total := listBody(t, w.Body.Bytes()); total != 2 {
		t.Errorf("窗口外应新增第 2 条快照，实际 %d", total)
	}
}

// TestVersionRestore 覆盖 3.3：还原后标题、正文、文件夹、标签与快照一致。
func TestVersionRestore(t *testing.T) {
	e, cookie, inboxID, folderID := trashEnv(t)

	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "快照标签"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建标签失败: %d", w.Code)
	}
	tagID := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 初始状态：在 folderID 下，带标签
	w = e.do(http.MethodPost, "/api/notes", map[string]any{
		"title":     "快照标题",
		"content":   "快照正文",
		"folder_id": folderID,
		"tag_ids":   []string{tagID},
	}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d: %s", w.Code, w.Body.String())
	}
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 改到收件箱、去掉标签、改内容 —— 这一步产生快照
	if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{
		"title":     "改过的标题",
		"content":   "改过的正文",
		"folder_id": inboxID,
		"tag_ids":   []string{},
	}, cookie); w.Code != http.StatusOK {
		t.Fatalf("编辑失败: %d: %s", w.Code, w.Body.String())
	}

	w = e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 {
		t.Fatalf("应有 1 条快照，实际 %d", total)
	}
	versionID := items[0]["id"].(string)

	// 还原到快照
	w = e.do(http.MethodPost, "/api/notes/"+noteID+"/versions/"+versionID+"/restore", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("还原应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	body := jsonBody(t, w.Body.Bytes())
	if body["title"] != "快照标题" {
		t.Errorf("标题应还原为「快照标题」，实际 %v", body["title"])
	}
	if body["content"] != "快照正文" {
		t.Errorf("正文应还原，实际 %v", body["content"])
	}
	if body["folder_id"] != folderID {
		t.Errorf("文件夹应还原为 %s，实际 %v", folderID, body["folder_id"])
	}
	tags, _ := body["tags"].([]any)
	if len(tags) != 1 {
		t.Errorf("标签应还原为 1 个，实际 %d", len(tags))
	}

	// 还原本身也产生一条快照
	w = e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	if _, total := listBody(t, w.Body.Bytes()); total != 1 {
		// 还原发生在合并窗口内，因此不会新增；清掉窗口外再确认会新增。
		t.Errorf("合并窗口内还原不应新增快照，实际 %d", total)
	}
}

// TestVersionRestoreCreatesSnapshotOutsideWindow 覆盖：窗口外的还原会产生新快照。
func TestVersionRestoreCreatesSnapshotOutsideWindow(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)

	if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"content": "第二版"}, cookie); w.Code != http.StatusOK {
		t.Fatalf("编辑失败: %d", w.Code)
	}
	if _, err := e.db.Exec(
		`UPDATE note_versions SET created_at = now() - interval '10 minutes' WHERE note_id = $1`, noteID); err != nil {
		t.Fatalf("调整快照时间失败: %v", err)
	}

	w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	items, _ := listBody(t, w.Body.Bytes())
	versionID := items[0]["id"].(string)

	if w := e.do(http.MethodPost, "/api/notes/"+noteID+"/versions/"+versionID+"/restore", nil, cookie); w.Code != http.StatusOK {
		t.Fatalf("还原应 200，实际 %d", w.Code)
	}

	w = e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	if _, total := listBody(t, w.Body.Bytes()); total != 2 {
		t.Errorf("窗口外还原应新增一条快照，实际 %d", total)
	}
}

// TestVersionOfTrashedNote 覆盖：已删除笔记的版本接口返回 404。
func TestVersionOfTrashedNote(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)

	if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"content": "改动"}, cookie); w.Code != http.StatusOK {
		t.Fatalf("编辑失败: %d", w.Code)
	}
	w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	items, _ := listBody(t, w.Body.Bytes())
	versionID := items[0]["id"].(string)

	if w := e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除失败: %d", w.Code)
	}

	if w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("已删笔记的版本列表应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions/"+versionID, nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("已删笔记的版本详情应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodPost, "/api/notes/"+noteID+"/versions/"+versionID+"/restore", nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("已删笔记的版本还原应 404，实际 %d", w.Code)
	}
}

// TestVersionCrossUser 覆盖跨用户隔离。
func TestVersionCrossUser(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)
	if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"content": "改动"}, cookie); w.Code != http.StatusOK {
		t.Fatalf("编辑失败: %d", w.Code)
	}

	w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, cookie)
	items, _ := listBody(t, w.Body.Bytes())
	versionID := items[0]["id"].(string)

	e.createUser("other", "another-horse-battery")
	otherCookie := e.loginNoTotp("other", "another-horse-battery")

	if w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions", nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("他人版本列表应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodGet, "/api/notes/"+noteID+"/versions/"+versionID, nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("他人版本详情应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodPost, "/api/notes/"+noteID+"/versions/"+versionID+"/restore", nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("他人版本还原应 404，实际 %d", w.Code)
	}
}

// TestVersionsCascadeOnPurge 覆盖：永久删除笔记后快照一并清理。
func TestVersionsCascadeOnPurge(t *testing.T) {
	e, cookie := newUserEnv(t)
	noteID := createNoteForVersions(t, e, cookie)
	e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"content": "改动"}, cookie)
	e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie)

	if w := e.do(http.MethodDelete, "/api/notes/"+noteID+"/purge", nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("purge 应 204，实际 %d", w.Code)
	}

	var cnt int
	if err := e.db.QueryRow(`SELECT count(*) FROM note_versions WHERE note_id = $1`, noteID).Scan(&cnt); err != nil {
		t.Fatalf("查询失败: %v", err)
	}
	if cnt != 0 {
		t.Errorf("purge 后快照应被级联删除，实际剩余 %d", cnt)
	}
}
