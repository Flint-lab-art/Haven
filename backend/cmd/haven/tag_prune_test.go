package main

import (
	"net/http"
	"testing"
)

// 空标签自动清理（docs/v3/api.md 第六节）：
// 引用归零的标签在查询标签列表时被删除。

// TestTagPruneOrphans 覆盖：解除关联后标签消失，并被物理删除。
func TestTagPruneOrphans(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "临时标签"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建标签失败: %d: %s", w.Code, w.Body.String())
	}
	tagID := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 新建标签还没有任何引用：下次查列表时应被清理
	w = e.do(http.MethodGet, "/api/tags", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("标签列表应 200，实际 %d", w.Code)
	}
	items, total := listBody(t, w.Body.Bytes())
	if total != 0 {
		t.Errorf("未被引用的标签应被清理，实际还剩 %d 个", total)
	}
	for _, it := range items {
		if it["id"] == tagID {
			t.Errorf("空标签不应出现在列表里")
		}
	}

	var cnt int
	if err := e.db.QueryRow(`SELECT count(*) FROM tags WHERE id = $1`, tagID).Scan(&cnt); err != nil {
		t.Fatalf("查询失败: %v", err)
	}
	if cnt != 0 {
		t.Errorf("空标签应被物理删除，实际仍存在")
	}
}

// TestTagPruneKeepsReferenced 覆盖：有引用的标签不受影响。
func TestTagPruneKeepsReferenced(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "保留标签"}, cookie)
	tagID := jsonBody(t, w.Body.Bytes())["id"].(string)

	w = e.do(http.MethodPost, "/api/notes", map[string]any{
		"title":   "带标签的笔记",
		"tag_ids": []string{tagID},
	}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d: %s", w.Code, w.Body.String())
	}
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	w = e.do(http.MethodGet, "/api/tags", nil, cookie)
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 {
		t.Fatalf("有引用的标签应保留，实际 %d", total)
	}
	if items[0]["note_count"] != float64(1) {
		t.Errorf("note_count 应为 1，实际 %v", items[0]["note_count"])
	}

	// 解除关联后再查：应被清理
	w = e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"tag_ids": []string{}}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("解除关联失败: %d", w.Code)
	}

	w = e.do(http.MethodGet, "/api/tags", nil, cookie)
	if _, total := listBody(t, w.Body.Bytes()); total != 0 {
		t.Errorf("解除关联后标签应被清理，实际还剩 %d", total)
	}
}

// TestTagPruneIgnoresTrashedNotes 覆盖：回收站里的笔记不算引用。
//
// 否则会出现「列表显示 0 篇但标签还在」的不一致。
func TestTagPruneIgnoresTrashedNotes(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "仅回收站引用"}, cookie)
	tagID := jsonBody(t, w.Body.Bytes())["id"].(string)

	w = e.do(http.MethodPost, "/api/notes", map[string]any{
		"title":   "会被删除",
		"tag_ids": []string{tagID},
	}, cookie)
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	if w := e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除笔记失败: %d", w.Code)
	}

	w = e.do(http.MethodGet, "/api/tags", nil, cookie)
	if _, total := listBody(t, w.Body.Bytes()); total != 0 {
		t.Errorf("只被回收站笔记引用的标签也应清理，实际还剩 %d", total)
	}
}
