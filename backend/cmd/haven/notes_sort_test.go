package main

import (
	"net/http"
	"testing"
	"time"
)

// 笔记目录内排序（docs/api.md 6.1 / 6.4，data-model.md 第三节规则 10）。

func TestNotesSortOrderWithinFolder(t *testing.T) {
	e, cookie := newUserEnv(t)

	folder := createFolder(t, e, cookie, "技术", nil)
	folderID := folder["id"].(string)

	create := func(title string, folderID *string) map[string]any {
		t.Helper()
		body := map[string]any{"title": title}
		if folderID != nil {
			body["folder_id"] = *folderID
		}
		w := e.do(http.MethodPost, "/api/notes", body, cookie)
		if w.Code != http.StatusCreated {
			t.Fatalf("创建笔记状态码 = %d: %s", w.Code, w.Body.String())
		}
		return jsonBody(t, w.Body.Bytes())
	}

	a := create("A", &folderID)
	b := create("B", &folderID)
	c := create("C", &folderID)
	aID := a["id"].(string)
	bID := b["id"].(string)
	cID := c["id"].(string)

	// 固定 updated_at，避免连续创建时间过于接近导致「最近更新」断言不稳定。
	base := time.Now().UTC().Add(-time.Hour)
	for id, at := range map[string]time.Time{
		aID: base.Add(time.Minute),
		bID: base.Add(2 * time.Minute),
		cID: base.Add(3 * time.Minute),
	} {
		if _, err := e.db.Exec(`UPDATE notes SET updated_at = $2 WHERE id = $1`, id, at); err != nil {
			t.Fatalf("设置 updated_at 失败: %v", err)
		}
	}

	// 只改 sort_order 不应刷新 updated_at。
	w := e.do(http.MethodGet, "/api/notes/"+aID, nil, cookie)
	before := jsonBody(t, w.Body.Bytes())["updated_at"]
	patchSort := func(id string, order int) {
		t.Helper()
		w := e.do(http.MethodPatch, "/api/notes/"+id,
			map[string]any{"sort_order": order}, cookie)
		if w.Code != http.StatusOK {
			t.Fatalf("更新排序状态码 = %d: %s", w.Code, w.Body.String())
		}
	}
	patchSort(aID, 1)
	w = e.do(http.MethodGet, "/api/notes/"+aID, nil, cookie)
	after := jsonBody(t, w.Body.Bytes())["updated_at"]
	if before != after {
		t.Errorf("仅调整 sort_order 不应更新 updated_at: before=%v after=%v", before, after)
	}

	patchSort(cID, 0)
	patchSort(bID, 2)

	// 按目录查询：sort_order ASC, updated_at DESC。
	w = e.do(http.MethodGet, "/api/notes?folder_id="+folderID, nil, cookie)
	items, total := listBody(t, w.Body.Bytes())
	if total != 3 || len(items) != 3 {
		t.Fatalf("目录内应有 3 篇笔记，实际 total=%d", total)
	}
	wantOrder := []string{cID, aID, bID}
	for i, want := range wantOrder {
		if items[i]["id"] != want {
			t.Errorf("目录内第 %d 篇 = %v，期望 %s", i, items[i]["id"], want)
		}
		if got := int(items[i]["sort_order"].(float64)); got != i {
			t.Errorf("第 %d 篇 sort_order = %d，期望 %d", i, got, i)
		}
	}

	// 不传 folder_id：仍按 updated_at DESC，不受 sort_order 影响。
	w = e.do(http.MethodGet, "/api/notes", nil, cookie)
	items, _ = listBody(t, w.Body.Bytes())
	wantRecent := []string{cID, bID, aID}
	for i, want := range wantRecent {
		if items[i]["id"] != want {
			t.Errorf("最近更新第 %d 篇 = %v，期望 %s", i, items[i]["id"], want)
		}
	}

	// 编辑器保存时总会带 folder_id；只要目录没变，就不能重置目录内排序。
	w = e.do(http.MethodPatch, "/api/notes/"+aID,
		map[string]any{"title": "A2", "folder_id": folderID}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("保存标题状态码 = %d: %s", w.Code, w.Body.String())
	}
	if got := int(jsonBody(t, w.Body.Bytes())["sort_order"].(float64)); got != 1 {
		t.Errorf("同目录保存后 sort_order 应保持 1，实际 %d", got)
	}

	// 负数排序值 → 422。
	if w := e.do(http.MethodPatch, "/api/notes/"+aID,
		map[string]any{"sort_order": -1}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("负数 sort_order 应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 移入收件箱时未显式给 sort_order：按 0 处理，出现在收件箱顶部。
	w = e.do(http.MethodPatch, "/api/notes/"+bID,
		map[string]any{"folder_id": nil}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("移入收件箱状态码 = %d: %s", w.Code, w.Body.String())
	}
	moved := jsonBody(t, w.Body.Bytes())
	if moved["folder_id"] != nil {
		t.Errorf("移入收件箱后 folder_id 应为 null，实际 %v", moved["folder_id"])
	}
	if got := int(moved["sort_order"].(float64)); got != 0 {
		t.Errorf("移入收件箱后 sort_order 应为 0，实际 %d", got)
	}

	w = e.do(http.MethodGet, "/api/notes?folder_id=", nil, cookie)
	items, total = listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 || items[0]["id"] != bID {
		t.Fatalf("收件箱排序结果异常: total=%d items=%v", total, items)
	}
}
