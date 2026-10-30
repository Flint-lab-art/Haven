package main

import (
	"net/http"
	"testing"
)

// 收件箱真实文件夹（docs/api.md 6.1 / 6.3 / 6.4 / 6.5，data-model.md 第七点五节）。

func createInboxFolder(t *testing.T, e *testEnv) string {
	t.Helper()
	var id string
	if err := e.db.QueryRow(
		`INSERT INTO folders (user_id, parent_id, name, is_inbox)
		 VALUES ($1, NULL, '收件箱', true) RETURNING id`,
		e.userID).Scan(&id); err != nil {
		t.Fatalf("创建收件箱失败: %v", err)
	}
	return id
}

func TestInboxFolder(t *testing.T) {
	e, cookie := newUserEnv(t)
	inboxID := createInboxFolder(t, e)

	// 列表里能看到真实收件箱。
	w := e.do(http.MethodGet, "/api/folders", nil, cookie)
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 {
		t.Fatalf("应只有收件箱，实际 total=%d items=%v", total, items)
	}
	if items[0]["id"] != inboxID || items[0]["is_inbox"] != true || items[0]["name"] != "收件箱" {
		t.Fatalf("收件箱字段异常: %v", items[0])
	}

	// 不传 folder_id 创建 → 归入收件箱。
	w = e.do(http.MethodPost, "/api/notes", map[string]any{"title": "默认收件箱"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记状态码 = %d: %s", w.Code, w.Body.String())
	}
	inboxNote := jsonBody(t, w.Body.Bytes())
	inboxNoteID := inboxNote["id"].(string)
	if inboxNote["folder_id"] != inboxID {
		t.Errorf("默认归属应为收件箱 %s，实际 %v", inboxID, inboxNote["folder_id"])
	}

	// 空 folder_id 查询 = 收件箱。
	w = e.do(http.MethodGet, "/api/notes?folder_id=", nil, cookie)
	items, total = listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 || items[0]["id"] != inboxNoteID {
		t.Fatalf("收件箱过滤异常: total=%d items=%v", total, items)
	}

	// 普通文件夹与移入/移出。
	folder := createFolder(t, e, cookie, "技术", nil)
	folderID := folder["id"].(string)

	w = e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "文件夹笔记", "folder_id": folderID}, cookie)
	folderNoteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	// folder_id: null = 移回收件箱。
	w = e.do(http.MethodPatch, "/api/notes/"+folderNoteID,
		map[string]any{"folder_id": nil}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("移回收件箱状态码 = %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes())["folder_id"]; got != inboxID {
		t.Errorf("移回收件箱后 folder_id = %v，期望 %s", got, inboxID)
	}

	// 删除普通文件夹：里面的笔记移到收件箱。
	w = e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "待迁移", "folder_id": folderID}, cookie)
	movedNoteID := jsonBody(t, w.Body.Bytes())["id"].(string)
	if w := e.do(http.MethodDelete, "/api/folders/"+folderID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除普通文件夹状态码 = %d: %s", w.Code, w.Body.String())
	}
	w = e.do(http.MethodGet, "/api/notes/"+movedNoteID, nil, cookie)
	if got := jsonBody(t, w.Body.Bytes())["folder_id"]; got != inboxID {
		t.Errorf("删除文件夹后笔记应进入收件箱 %s，实际 %v", inboxID, got)
	}

	// 收件箱不可删除。
	if w := e.do(http.MethodDelete, "/api/folders/"+inboxID, nil, cookie); w.Code != http.StatusConflict {
		t.Errorf("删除收件箱应 409，实际 %d: %s", w.Code, w.Body.String())
	}

	// 收件箱不可移动。
	other := createFolder(t, e, cookie, "其他", nil)
	if w := e.do(http.MethodPatch, "/api/folders/"+inboxID,
		map[string]any{"parent_id": other["id"]}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("移动收件箱应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 收件箱可以改名、换图标，is_inbox 保持不变。
	w = e.do(http.MethodPatch, "/api/folders/"+inboxID,
		map[string]any{"name": "重要", "icon": "📥"}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("修改收件箱状态码 = %d: %s", w.Code, w.Body.String())
	}
	updated := jsonBody(t, w.Body.Bytes())
	if updated["name"] != "重要" || updated["icon"] != "📥" || updated["is_inbox"] != true {
		t.Errorf("收件箱改名 / 图标结果异常: %v", updated)
	}
}
