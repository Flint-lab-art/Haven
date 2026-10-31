package main

import (
	"net/http"
	"testing"
)

// 删除文件夹时，回收站里的笔记必须保持原 folder_id（docs/v2/data-model.md 第一节规则 2）。
//
// 否则「还原到原位置」会失效：笔记被从回收站对应目录悄悄搬进收件箱。
// 这里绕过接口直接标记删除（F1.2 落地前 DELETE 仍是硬删）。

// TestFolderDeleteSkipsTrashedNotes 覆盖：删除文件夹时只搬迁未删笔记。
func TestFolderDeleteSkipsTrashedNotes(t *testing.T) {
	e, cookie := newUserEnv(t)
	inboxID := createInboxFolder(t, e)

	// 建文件夹与其子文件夹
	createFolder := func(name string, parentID any) string {
		t.Helper()
		payload := map[string]any{"name": name}
		if parentID != nil {
			payload["parent_id"] = parentID
		}
		w := e.do(http.MethodPost, "/api/folders", payload, cookie)
		if w.Code != http.StatusCreated {
			t.Fatalf("创建文件夹 %s 失败: %d: %s", name, w.Code, w.Body.String())
		}
		return jsonBody(t, w.Body.Bytes())["id"].(string)
	}
	parent := createFolder("要删的目录", nil)
	child := createFolder("子目录", parent)

	createNote := func(title, folderID string) string {
		t.Helper()
		w := e.do(http.MethodPost, "/api/notes", map[string]any{
			"title":     title,
			"folder_id": folderID,
		}, cookie)
		if w.Code != http.StatusCreated {
			t.Fatalf("创建笔记 %s 失败: %d: %s", title, w.Code, w.Body.String())
		}
		return jsonBody(t, w.Body.Bytes())["id"].(string)
	}

	liveNote := createNote("未删除的笔记", child)
	trashedNote := createNote("回收站里的笔记", child)

	// 只把 trashedNote 标进回收站
	if _, err := e.db.Exec(`UPDATE notes SET deleted_at = now() WHERE id = $1`, trashedNote); err != nil {
		t.Fatalf("标记删除失败: %v", err)
	}

	// 删除父目录（子树含 child）
	if w := e.do(http.MethodDelete, "/api/folders/"+parent, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除文件夹失败: %d: %s", w.Code, w.Body.String())
	}

	// 未删除的笔记应落到收件箱（folder_id 变为收件箱 id，不为 NULL 且不是被删目录）
	var liveFolder *string
	if err := e.db.QueryRow(`SELECT folder_id::text FROM notes WHERE id = $1`, liveNote).Scan(&liveFolder); err != nil {
		t.Fatalf("查询未删笔记失败: %v", err)
	}
	if liveFolder != nil && *liveFolder == child {
		t.Errorf("未删笔记不应仍挂在该目录下")
	}

	// 回收站里的笔记应保持原 folder_id（此时指向已删除的目录，外键 ON DELETE SET NULL 会置空）
	// 这里断言的是「删除文件夹的 UPDATE 没动它」——即 folder_id 变成 NULL 而不是收件箱 id。
	var trashedFolder *string
	if err := e.db.QueryRow(`SELECT folder_id::text FROM notes WHERE id = $1`, trashedNote).Scan(&trashedFolder); err != nil {
		t.Fatalf("查询回收站笔记失败: %v", err)
	}

	if trashedFolder != nil && *trashedFolder == inboxID {
		t.Errorf("回收站笔记被搬进了收件箱，应保持原 folder_id（现已被外键置 NULL）")
	}
}

// TestFolderDeleteMovesLiveNotesToInbox 确认未删除的笔记仍按原规则回收到收件箱。
func TestFolderDeleteMovesLiveNotesToInbox(t *testing.T) {
	e, cookie := newUserEnv(t)
	inboxID := createInboxFolder(t, e)

	w := e.do(http.MethodPost, "/api/folders", map[string]any{"name": "普通目录"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建文件夹失败: %d", w.Code)
	}
	folderID := jsonBody(t, w.Body.Bytes())["id"].(string)

	w = e.do(http.MethodPost, "/api/notes", map[string]any{"title": "活的", "folder_id": folderID}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d: %s", w.Code, w.Body.String())
	}
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	if w := e.do(http.MethodDelete, "/api/folders/"+folderID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除文件夹失败: %d: %s", w.Code, w.Body.String())
	}

	var got *string
	if err := e.db.QueryRow(`SELECT folder_id::text FROM notes WHERE id = $1`, noteID).Scan(&got); err != nil {
		t.Fatalf("查询笔记失败: %v", err)
	}
	if got == nil || *got != inboxID {
		t.Errorf("未删笔记应落入收件箱 %s，实际 %v", inboxID, got)
	}
}
