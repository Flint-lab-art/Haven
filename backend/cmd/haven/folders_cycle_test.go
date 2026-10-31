package main

import (
	"encoding/json"
	"net/http"
	"testing"
)

// isSelfOrDescendant 的回归测试（ui-design.md 9.2「禁止拖入自身或自己的子文件夹」）。
//
// 该函数依赖数据库事务做递归查询，无法做纯函数单测，这里通过 PATCH /api/folders/:id
// 验证防环：把文件夹移到自己或自己的后代下必须 422，且数据不被改动。

// TestFolderMovePreventsCycle 覆盖将自己 / 后代设为父目录的三种情形。
func TestFolderMovePreventsCycle(t *testing.T) {
	e, cookie := newUserEnv(t)

	create := func(name string, parentID any) string {
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

	root := create("root", nil)
	child := create("child", root)
	grand := create("grand", child)
	other := create("other", nil)

	// 1. 移到自己
	if w := e.do(http.MethodPatch, "/api/folders/"+root, map[string]any{"parent_id": root}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("移到自身应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 2. 移到直接子级
	if w := e.do(http.MethodPatch, "/api/folders/"+root, map[string]any{"parent_id": child}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("移到直接子级应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 3. 移到隔代后代
	if w := e.do(http.MethodPatch, "/api/folders/"+root, map[string]any{"parent_id": grand}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("移到隔代后代应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 4. 移到兄弟（合法，不应被防环逻辑误伤）
	if w := e.do(http.MethodPatch, "/api/folders/"+root, map[string]any{"parent_id": other}, cookie); w.Code != http.StatusOK {
		t.Errorf("移到无关节点应成功，实际 %d: %s", w.Code, w.Body.String())
	}
}

// TestFolderMoveThenDescendBlocked 覆盖移动成功后再试图制造环的情形。
func TestFolderMoveThenDescendBlocked(t *testing.T) {
	e, cookie := newUserEnv(t)

	create := func(name string, parentID any) string {
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

	a := create("a", nil)
	b := create("b", nil)

	// b 移到 a 下成功
	if w := e.do(http.MethodPatch, "/api/folders/"+b, map[string]any{"parent_id": a}, cookie); w.Code != http.StatusOK {
		t.Fatalf("b 移到 a 下应成功，实际 %d: %s", w.Code, w.Body.String())
	}
	// 此时 a 是 b 的父级，再想把 a 移到 b 下必须被拒
	if w := e.do(http.MethodPatch, "/api/folders/"+a, map[string]any{"parent_id": b}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("a 移到 b 下（构成环）应 422，实际 %d: %s", w.Code, w.Body.String())
	}

	// 确认数据没被改坏：列表里仍是两个根节点结构
	w := e.do(http.MethodGet, "/api/folders", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("获取文件夹列表失败: %d", w.Code)
	}
	var body struct {
		Items []struct {
			ID       string  `json:"id"`
			ParentID *string `json:"parent_id"`
		} `json:"items"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("解析文件夹列表失败: %v", err)
	}
	for _, f := range body.Items {
		if f.ID == a && f.ParentID != nil {
			t.Errorf("a 应仍在根目录，实际 parent_id=%v", *f.ParentID)
		}
	}
}
