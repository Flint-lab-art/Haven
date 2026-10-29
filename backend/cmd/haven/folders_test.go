package main

import (
	"net/http"
	"testing"
)

// 文件夹与笔记归属（docs/api.md 第六点五节、6.1 / 6.3 / 6.4）。

func createFolder(t *testing.T, e *testEnv, cookie *http.Cookie, name string, parentID *string) map[string]any {
	t.Helper()
	body := map[string]any{"name": name}
	if parentID != nil {
		body["parent_id"] = *parentID
	}
	w := e.do(http.MethodPost, "/api/folders", body, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建文件夹状态码 = %d: %s", w.Code, w.Body.String())
	}
	return jsonBody(t, w.Body.Bytes())
}

func TestFoldersCRUD(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 空列表
	w := e.do(http.MethodGet, "/api/folders", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("列表状态码 = %d", w.Code)
	}
	items, total := listBody(t, w.Body.Bytes())
	if total != 0 || len(items) != 0 {
		t.Fatalf("初始应为空，实际 total=%d", total)
	}

	root := createFolder(t, e, cookie, "技术", nil)
	rootID := root["id"].(string)
	if root["parent_id"] != nil {
		t.Errorf("根目录 parent_id 应为 null，实际 %v", root["parent_id"])
	}

	child := createFolder(t, e, cookie, "Go", &rootID)
	childID := child["id"].(string)
	if child["parent_id"] != rootID {
		t.Errorf("子目录 parent_id 应为 %s，实际 %v", rootID, child["parent_id"])
	}

	// 同一个父目录下重名 → 409
	if w := e.do(http.MethodPost, "/api/folders",
		map[string]any{"name": "Go", "parent_id": rootID}, cookie); w.Code != http.StatusConflict {
		t.Errorf("同父目录重名应 409，实际 %d: %s", w.Code, w.Body.String())
	}

	// 列表是平铺数组，按 sort_order / name 排序
	w = e.do(http.MethodGet, "/api/folders", nil, cookie)
	items, total = listBody(t, w.Body.Bytes())
	if total != 2 || len(items) != 2 {
		t.Fatalf("列表应有 2 个文件夹，实际 total=%d", total)
	}

	// 改名
	w = e.do(http.MethodPatch, "/api/folders/"+childID,
		map[string]any{"name": "Golang"}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("改名状态码 = %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes()); got["name"] != "Golang" {
		t.Errorf("改名未生效: %v", got["name"])
	}

	// 不能移动到自己的子目录下（循环引用）
	if w := e.do(http.MethodPatch, "/api/folders/"+rootID,
		map[string]any{"parent_id": childID}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("循环移动应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 移动到根目录（parent_id 显式为 null）
	w = e.do(http.MethodPatch, "/api/folders/"+childID,
		map[string]any{"parent_id": nil}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("移动状态码 = %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes()); got["parent_id"] != nil {
		t.Errorf("移动后 parent_id 应为 null，实际 %v", got["parent_id"])
	}

	// 删除根目录；子目录已经移走，不受影响
	if w := e.do(http.MethodDelete, "/api/folders/"+rootID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除状态码 = %d: %s", w.Code, w.Body.String())
	}
	w = e.do(http.MethodGet, "/api/folders", nil, cookie)
	items, total = listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 {
		t.Fatalf("删除后应剩 1 个，实际 total=%d", total)
	}
	if items[0]["id"] != childID {
		t.Errorf("剩余文件夹应为 %s，实际 %v", childID, items[0]["id"])
	}

	// 删除不存在的文件夹 → 404
	if w := e.do(http.MethodDelete, "/api/folders/"+rootID, nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("删除不存在的文件夹应 404，实际 %d", w.Code)
	}
}

func TestFoldersCascadeAndNoteUnclassified(t *testing.T) {
	e, cookie := newUserEnv(t)

	root := createFolder(t, e, cookie, "技术", nil)
	rootID := root["id"].(string)
	child := createFolder(t, e, cookie, "Go", &rootID)
	childID := child["id"].(string)

	// 笔记放进子文件夹
	w := e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "Go 笔记", "folder_id": childID}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记状态码 = %d: %s", w.Code, w.Body.String())
	}
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 删除根目录：子目录级联删除，笔记回到未分类
	if w := e.do(http.MethodDelete, "/api/folders/"+rootID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除根目录状态码 = %d: %s", w.Code, w.Body.String())
	}

	w = e.do(http.MethodGet, "/api/notes/"+noteID, nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("笔记应仍存在，状态码 %d", w.Code)
	}
	if got := jsonBody(t, w.Body.Bytes()); got["folder_id"] != nil {
		t.Errorf("删除文件夹后笔记应回到未分类，实际 folder_id=%v", got["folder_id"])
	}

	if w := e.do(http.MethodGet, "/api/folders", nil, cookie); func() bool {
		items, total := listBody(t, w.Body.Bytes())
		return total != 0 || len(items) != 0
	}() {
		t.Errorf("子文件夹应被级联删除")
	}
}

func TestNotesFolderBindingAndFilter(t *testing.T) {
	e, cookie := newUserEnv(t)

	folder := createFolder(t, e, cookie, "技术", nil)
	folderID := folder["id"].(string)

	// 带 folder_id 创建
	w := e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "在文件夹里", "folder_id": folderID}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建状态码 = %d: %s", w.Code, w.Body.String())
	}
	folderNoteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 不带 folder_id 创建 → 未分类
	w = e.do(http.MethodPost, "/api/notes", map[string]any{"title": "未分类"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建状态码 = %d: %s", w.Code, w.Body.String())
	}
	looseNoteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	// 详情返回 folder_id
	w = e.do(http.MethodGet, "/api/notes/"+folderNoteID, nil, cookie)
	if got := jsonBody(t, w.Body.Bytes()); got["folder_id"] != folderID {
		t.Errorf("详情 folder_id = %v，期望 %s", got["folder_id"], folderID)
	}
	w = e.do(http.MethodGet, "/api/notes/"+looseNoteID, nil, cookie)
	if got := jsonBody(t, w.Body.Bytes()); got["folder_id"] != nil {
		t.Errorf("未分类笔记 folder_id 应为 null，实际 %v", got["folder_id"])
	}

	// 按文件夹过滤
	w = e.do(http.MethodGet, "/api/notes?folder_id="+folderID, nil, cookie)
	items, total := listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 || items[0]["id"] != folderNoteID {
		t.Fatalf("按文件夹过滤结果异常: total=%d items=%v", total, items)
	}

	// 空字符串 = 未分类
	w = e.do(http.MethodGet, "/api/notes?folder_id=", nil, cookie)
	items, total = listBody(t, w.Body.Bytes())
	if total != 1 || len(items) != 1 || items[0]["id"] != looseNoteID {
		t.Fatalf("未分类过滤结果异常: total=%d items=%v", total, items)
	}

	// 不传 folder_id = 全部
	w = e.do(http.MethodGet, "/api/notes", nil, cookie)
	if _, total := listBody(t, w.Body.Bytes()); total != 2 {
		t.Fatalf("不过滤应返回 2 篇，实际 total=%d", total)
	}

	// PATCH 移出文件夹
	w = e.do(http.MethodPatch, "/api/notes/"+folderNoteID,
		map[string]any{"folder_id": nil}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("移出文件夹状态码 = %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes()); got["folder_id"] != nil {
		t.Errorf("移出后 folder_id 应为 null，实际 %v", got["folder_id"])
	}

	// PATCH 绑定到不存在的文件夹 → 422
	if w := e.do(http.MethodPatch, "/api/notes/"+folderNoteID,
		map[string]any{"folder_id": "00000000-0000-0000-0000-000000000000"}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("绑定不存在的文件夹应 422，实际 %d", w.Code)
	}

	// 非法 uuid 查询 → 422
	if w := e.do(http.MethodGet, "/api/notes?folder_id=not-a-uuid", nil, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("非法 folder_id 应 422，实际 %d", w.Code)
	}
}

func TestFoldersCrossUserIsolation(t *testing.T) {
	e, cookie := newUserEnv(t)
	folder := createFolder(t, e, cookie, "私有目录", nil)
	folderID := folder["id"].(string)

	// 第二个用户
	e.createUser("alice", "correct-horse-battery")
	alice := e.loginNoTotp("alice", "correct-horse-battery")

	w := e.do(http.MethodGet, "/api/folders", nil, alice)
	items, total := listBody(t, w.Body.Bytes())
	if total != 0 || len(items) != 0 {
		t.Fatalf("跨用户不应看到别人的文件夹，实际 total=%d", total)
	}

	// 跨用户改 / 删 → 404
	if w := e.do(http.MethodPatch, "/api/folders/"+folderID,
		map[string]any{"name": "偷改"}, alice); w.Code != http.StatusNotFound {
		t.Errorf("跨用户改名应 404，实际 %d", w.Code)
	}
	if w := e.do(http.MethodDelete, "/api/folders/"+folderID, nil, alice); w.Code != http.StatusNotFound {
		t.Errorf("跨用户删除应 404，实际 %d", w.Code)
	}

	// 跨用户把笔记放进别人的文件夹 → 422
	if w := e.do(http.MethodPost, "/api/notes",
		map[string]any{"title": "越权", "folder_id": folderID}, alice); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("跨用户绑定文件夹应 422，实际 %d: %s", w.Code, w.Body.String())
	}
}
