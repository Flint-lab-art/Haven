package main

import (
	"net/http"
	"testing"

	"github.com/kairo/haven/internal/auth"
)

// 回收站接口（docs/v2/api.md 第二节）。

// trashEnv 建好收件箱与一个自定义目录，返回两者的 id。
func trashEnv(t *testing.T) (*testEnv, *http.Cookie, string, string) {
	t.Helper()
	e, cookie := newUserEnv(t)
	inboxID := createInboxFolder(t, e)

	w := e.do(http.MethodPost, "/api/folders", map[string]any{"name": "技术"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建文件夹失败: %d: %s", w.Code, w.Body.String())
	}
	folderID := jsonBody(t, w.Body.Bytes())["id"].(string)
	return e, cookie, inboxID, folderID
}

func createNoteIn(t *testing.T, e *testEnv, cookie *http.Cookie, title, folderID string) string {
	t.Helper()
	w := e.do(http.MethodPost, "/api/notes", map[string]any{
		"title":     title,
		"content":   "正文内容 " + title,
		"folder_id": folderID,
	}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d: %s", w.Code, w.Body.String())
	}
	return jsonBody(t, w.Body.Bytes())["id"].(string)
}

// TestTrashList 覆盖 2.1：只列已删除笔记，带原路径与删除时间。
func TestTrashList(t *testing.T) {
	e, cookie, inboxID, folderID := trashEnv(t)

	kept := createNoteIn(t, e, cookie, "留下的", inboxID)
	gone := createNoteIn(t, e, cookie, "删掉的", folderID)
	_ = kept

	if w := e.do(http.MethodDelete, "/api/notes/"+gone, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除失败: %d", w.Code)
	}

	w := e.do(http.MethodGet, "/api/notes/trash", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("回收站列表应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 {
		t.Fatalf("回收站应只有 1 条，实际 total=%d len=%d", total, len(items))
	}
	item := items[0]
	if item["id"] != gone {
		t.Errorf("回收站里的笔记 id 不对: %v", item["id"])
	}
	if item["folder_path"] != "技术" {
		t.Errorf("folder_path 应为「技术」，实际 %v", item["folder_path"])
	}
	if item["deleted_at"] == nil {
		t.Errorf("deleted_at 不应为空")
	}
	if item["content_preview"] == nil || item["content_preview"] == "" {
		t.Errorf("应返回 content_preview")
	}

	// 未删除的笔记不在回收站
	for _, it := range items {
		if it["id"] == kept {
			t.Errorf("未删除的笔记不应出现在回收站")
		}
	}
}

// TestTrashRestore 覆盖 2.2：还原回原文件夹，并重新可见。
func TestTrashRestore(t *testing.T) {
	e, cookie, _, folderID := trashEnv(t)

	noteID := createNoteIn(t, e, cookie, "可还原", folderID)
	e.do(http.MethodPost, "/api/notes/"+noteID+"/publish", nil, cookie)
	if w := e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除失败: %d", w.Code)
	}

	w := e.do(http.MethodPost, "/api/notes/"+noteID+"/restore", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("还原应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	body := jsonBody(t, w.Body.Bytes())
	if body["folder_id"] != folderID {
		t.Errorf("应回到原文件夹 %s，实际 %v", folderID, body["folder_id"])
	}

	// 还原后重新出现在私有列表与公开详情
	w = e.do(http.MethodGet, "/api/notes/"+noteID, nil, cookie)
	if w.Code != http.StatusOK {
		t.Errorf("还原后详情应 200，实际 %d", w.Code)
	}
	w = e.do(http.MethodGet, "/api/public/notes/"+noteID, nil)
	if w.Code != http.StatusOK {
		t.Errorf("还原后公开详情应 200，实际 %d", w.Code)
	}

	// 不在回收站的笔记不能还原
	if w := e.do(http.MethodPost, "/api/notes/"+noteID+"/restore", nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("还原未删除的笔记应 404，实际 %d", w.Code)
	}
}

// TestTrashRestoreWhenFolderGone 覆盖 2.2：原文件夹已删除时归入收件箱。
func TestTrashRestoreWhenFolderGone(t *testing.T) {
	e, cookie, inboxID, folderID := trashEnv(t)

	noteID := createNoteIn(t, e, cookie, "孤儿笔记", folderID)
	if w := e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除失败: %d", w.Code)
	}

	// 删除原文件夹（回收站笔记的 folder_id 会被外键置 NULL）
	if w := e.do(http.MethodDelete, "/api/folders/"+folderID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除文件夹失败: %d: %s", w.Code, w.Body.String())
	}

	w := e.do(http.MethodPost, "/api/notes/"+noteID+"/restore", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("还原应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	body := jsonBody(t, w.Body.Bytes())
	if body["folder_id"] != inboxID {
		t.Errorf("原文件夹不存在时应落入收件箱 %s，实际 %v", inboxID, body["folder_id"])
	}
}

// TestTrashPurge 覆盖 2.3：只对回收站中的笔记有效，真删后彻底消失。
func TestTrashPurge(t *testing.T) {
	e, cookie, inboxID, _ := trashEnv(t)

	live := createNoteIn(t, e, cookie, "活的", inboxID)
	trashed := createNoteIn(t, e, cookie, "要永久删", inboxID)

	// 未删除的笔记不能 purge
	if w := e.do(http.MethodDelete, "/api/notes/"+live+"/purge", nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("purge 未删除笔记应 404，实际 %d", w.Code)
	}

	if w := e.do(http.MethodDelete, "/api/notes/"+trashed, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除失败: %d", w.Code)
	}
	if w := e.do(http.MethodDelete, "/api/notes/"+trashed+"/purge", nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("purge 应 204，实际 %d: %s", w.Code, w.Body.String())
	}

	var cnt int
	if err := e.db.QueryRow(`SELECT count(*) FROM notes WHERE id = $1`, trashed).Scan(&cnt); err != nil {
		t.Fatalf("查询失败: %v", err)
	}
	if cnt != 0 {
		t.Errorf("purge 后行应被物理删除，实际仍存在")
	}
}

// TestTrashEmpty 覆盖 2.4：清空回收站只删已删除笔记。
func TestTrashEmpty(t *testing.T) {
	e, cookie, inboxID, _ := trashEnv(t)

	live := createNoteIn(t, e, cookie, "活的", inboxID)
	for i := 0; i < 3; i++ {
		id := createNoteIn(t, e, cookie, "删"+string(rune('a'+i)), inboxID)
		e.do(http.MethodDelete, "/api/notes/"+id, nil, cookie)
	}

	if w := e.do(http.MethodDelete, "/api/notes/trash", nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("清空应 204，实际 %d: %s", w.Code, w.Body.String())
	}

	w := e.do(http.MethodGet, "/api/notes/trash", nil, cookie)
	_, total := listBody(t, w.Body.Bytes())
	if total != 0 {
		t.Errorf("清空后回收站应为空，实际 %d", total)
	}

	// 活的笔记不受影响
	if w := e.do(http.MethodGet, "/api/notes/"+live, nil, cookie); w.Code != http.StatusOK {
		t.Errorf("未删除的笔记应仍在，实际 %d", w.Code)
	}
}

// TestTrashExpiredCleanup 覆盖第四节：超过 30 天的记录在访问回收站时被清理。
func TestTrashExpiredCleanup(t *testing.T) {
	e, cookie, inboxID, _ := trashEnv(t)

	fresh := createNoteIn(t, e, cookie, "刚删", inboxID)
	stale := createNoteIn(t, e, cookie, "早就删了", inboxID)

	e.do(http.MethodDelete, "/api/notes/"+fresh, nil, cookie)
	e.do(http.MethodDelete, "/api/notes/"+stale, nil, cookie)

	// 把 stale 的删除时间改到 31 天前
	if _, err := e.db.Exec(
		`UPDATE notes SET deleted_at = now() - interval '31 days' WHERE id = $1`, stale); err != nil {
		t.Fatalf("修改删除时间失败: %v", err)
	}

	w := e.do(http.MethodGet, "/api/notes/trash", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("回收站列表应 200，实际 %d", w.Code)
	}
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 {
		t.Errorf("过期记录应被清理，只剩 1 条，实际 %d", total)
	}
	for _, it := range items {
		if it["id"] == stale {
			t.Errorf("超过保留期的记录不应再出现")
		}
	}

	var cnt int
	if err := e.db.QueryRow(`SELECT count(*) FROM notes WHERE id = $1`, stale).Scan(&cnt); err != nil {
		t.Fatalf("查询失败: %v", err)
	}
	if cnt != 0 {
		t.Errorf("过期记录应被物理删除")
	}
}

// TestTrashCrossUser 覆盖跨用户隔离：看不到、也还原不了他人的回收站笔记。
func TestTrashCrossUser(t *testing.T) {
	e, cookie, inboxID, _ := trashEnv(t)

	noteID := createNoteIn(t, e, cookie, "别人的", inboxID)
	e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie)

	// 第二个用户
	e.createUser("other", "another-horse-battery")
	otherCookie := e.loginNoTotp("other", "another-horse-battery")

	w := e.do(http.MethodGet, "/api/notes/trash", nil, otherCookie)
	_, total := listBody(t, w.Body.Bytes())
	if total != 0 {
		t.Errorf("他人回收站应为空，实际 %d", total)
	}

	if w := e.do(http.MethodPost, "/api/notes/"+noteID+"/restore", nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("还原他人笔记应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodDelete, "/api/notes/"+noteID+"/purge", nil, otherCookie); w.Code != http.StatusNotFound {
		t.Errorf("永久删除他人笔记应 404，实际 %d", w.Code)
	}
}

// TestTrashTokenPermission 覆盖鉴权：read Token 不能做回收站写操作。
func TestTrashTokenPermission(t *testing.T) {
	e, cookie, inboxID, _ := trashEnv(t)

	noteID := createNoteIn(t, e, cookie, "要删的", inboxID)
	e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie)

	created, err := e.svc.CreateAPIToken(t.Context(), e.userID, "read-only", auth.ScopeRead, nil)
	if err != nil {
		t.Fatalf("创建 Token 失败: %v", err)
	}
	tok := created.Token

	// read Token 可以看列表
	if w := e.doWithToken(http.MethodGet, "/api/notes/trash", tok); w.Code != http.StatusOK {
		t.Errorf("read Token 查看回收站应 200，实际 %d", w.Code)
	}
	// 不能还原
	if w := e.doWithToken(http.MethodPost, "/api/notes/"+noteID+"/restore", tok); w.Code != http.StatusForbidden {
		t.Errorf("read Token 还原应 403，实际 %d", w.Code)
	}
	// 不能清空
	if w := e.doWithToken(http.MethodDelete, "/api/notes/trash", tok); w.Code != http.StatusForbidden {
		t.Errorf("read Token 清空应 403，实际 %d", w.Code)
	}
}
