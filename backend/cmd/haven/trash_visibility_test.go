package main

import (
	"encoding/json"
	"net/http"
	"testing"
)

// 回收站可见性回归测试（docs/v2/backend/data-model.md 第一节规则 3）。
//
// 删除笔记只写 notes.deleted_at，所有读路径都必须排除已删行。
// 可见性条件统一在 auth.VisibilityPublic / VisibilityOwnedOrPublic 里，
// 本文件逐条验证每个读接口确实拿不到已删笔记。

// execDelete 直接把笔记标记为已删除。
//
// F1.2 完成前 DELETE /api/notes/:id 仍是硬删除，这里绕过接口直接写库，
// 以便现在就锁住可见性行为；F1.2 落地后接口与这条路径等价。
func execDelete(t *testing.T, e *testEnv, noteID string) {
	t.Helper()
	res, err := e.db.Exec(`UPDATE notes SET deleted_at = now() WHERE id = $1`, noteID)
	if err == nil {
		if n, _ := res.RowsAffected(); n == 0 {
			t.Fatalf("标记删除失败：笔记 %s 不存在", noteID)
		}
		return
	}
	t.Fatalf("标记删除失败: %v", err)
}

// TestDeletedNoteInvisibleEverywhere 覆盖公开列表、公开详情、公开搜索、
// 私有搜索、私有列表、按标签查笔记与 note_count。
func TestDeletedNoteInvisibleEverywhere(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 建标签 + 笔记 + 发布
	w := e.do(http.MethodPost, "/api/tags", map[string]any{"name": "可见性"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建标签失败: %d: %s", w.Code, w.Body.String())
	}
	tagID := jsonBody(t, w.Body.Bytes())["id"].(string)

	w = e.do(http.MethodPost, "/api/notes", map[string]any{
		"title":   "会被删除的笔记",
		"content": "正文里有个独特词 zzqqx",
		"tag_ids": []string{tagID},
	}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d: %s", w.Code, w.Body.String())
	}
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	if w := e.do(http.MethodPost, "/api/notes/"+noteID+"/publish", nil, cookie); w.Code != http.StatusOK {
		t.Fatalf("发布失败: %d: %s", w.Code, w.Body.String())
	}

	// 删除前：各接口都能看到
	assertVisible := func(t *testing.T, want bool) {
		t.Helper()

		checkListContains := func(path string, wantNote bool) {
			t.Helper()
			w := e.do(http.MethodGet, path, nil, cookie)
			if w.Code != http.StatusOK {
				t.Fatalf("%s 返回 %d: %s", path, w.Code, w.Body.String())
			}
			items, _ := listBody(t, w.Body.Bytes())
			found := false
			for _, it := range items {
				if it["id"] == noteID {
					found = true
				}
			}
			if found != wantNote {
				t.Errorf("%s 包含该笔记 = %v，期望 %v", path, found, wantNote)
			}
		}

		checkListContains("/api/public/notes", want)
		checkListContains("/api/notes", want)
		checkListContains("/api/tags/"+tagID+"/notes", want)

		// 公开详情
		w := e.do(http.MethodGet, "/api/public/notes/"+noteID, nil)
		if w.Code == http.StatusOK && !want {
			t.Errorf("公开详情应 404，实际 200")
		}
		if w.Code != http.StatusOK && want {
			t.Errorf("公开详情应 200，实际 %d", w.Code)
		}

		// 公开搜索
		w = e.do(http.MethodGet, "/api/public/search?q=zzqqx", nil)
		if w.Code != http.StatusOK {
			t.Fatalf("公开搜索返回 %d: %s", w.Code, w.Body.String())
		}
		_, pubTotal := listBody(t, w.Body.Bytes())
		if (pubTotal > 0) != want {
			t.Errorf("公开搜索命中数 = %d，期望命中 = %v", pubTotal, want)
		}

		// 私有搜索
		w = e.do(http.MethodGet, "/api/search?q=zzqqx", nil, cookie)
		if w.Code != http.StatusOK {
			t.Fatalf("私有搜索返回 %d: %s", w.Code, w.Body.String())
		}
		var sr struct {
			Notes struct {
				Items []map[string]any `json:"items"`
				Total int              `json:"total"`
			} `json:"notes"`
		}
		if err := json.Unmarshal(w.Body.Bytes(), &sr); err != nil {
			t.Fatalf("解析私有搜索失败: %v", err)
		}
		if (sr.Notes.Total > 0) != want {
			t.Errorf("私有搜索命中数 = %d，期望命中 = %v", sr.Notes.Total, want)
		}

		// 标签的 note_count
		w = e.do(http.MethodGet, "/api/tags", nil, cookie)
		if w.Code != http.StatusOK {
			t.Fatalf("标签列表返回 %d", w.Code)
		}
		tags, _ := listBody(t, w.Body.Bytes())
		for _, tg := range tags {
			if tg["id"] != tagID {
				continue
			}
			count := tg["note_count"].(float64)
			if (count > 0) != want {
				t.Errorf("标签 note_count = %v，期望 >0 = %v", count, want)
			}
		}
	}

	assertVisible(t, true)

	execDelete(t, e, noteID)
	assertVisible(t, false)
}

// TestDeletedNote404OnPrivateDetail 确认已删除笔记在私有详情接口也不可见。
func TestDeletedNote404OnPrivateDetail(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "私有详情"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d", w.Code)
	}
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	if w := e.do(http.MethodGet, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusOK {
		t.Fatalf("删除前应 200，实际 %d", w.Code)
	}

	execDelete(t, e, noteID)

	if w := e.do(http.MethodGet, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("删除后应 404，实际 %d: %s", w.Code, w.Body.String())
	}
}

// TestDeleteMovesToTrash 覆盖 api.md 6.5 的二期语义：
// 删除接口不再物理删除，只写 deleted_at（docs/v2/api.md 1.1）。
func TestDeleteMovesToTrash(t *testing.T) {
	e, cookie := newUserEnv(t)

	w := e.do(http.MethodPost, "/api/notes", map[string]any{"title": "要进回收站"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建笔记失败: %d", w.Code)
	}
	noteID := jsonBody(t, w.Body.Bytes())["id"].(string)

	if w := e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("删除应 204，实际 %d: %s", w.Code, w.Body.String())
	}

	// 行还在，deleted_at 有值
	var deletedAt *string
	if err := e.db.QueryRow(`SELECT deleted_at::text FROM notes WHERE id = $1`, noteID).Scan(&deletedAt); err != nil {
		t.Fatalf("笔记行应仍存在，实际查询失败: %v", err)
	}
	if deletedAt == nil {
		t.Errorf("deleted_at 应有值，实际 NULL")
	}

	// 再次删除应 404（已在回收站）
	if w := e.do(http.MethodDelete, "/api/notes/"+noteID, nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("重复删除应 404，实际 %d: %s", w.Code, w.Body.String())
	}

	// 编辑已删除笔记应 404
	if w := e.do(http.MethodPatch, "/api/notes/"+noteID, map[string]any{"title": "改"}, cookie); w.Code != http.StatusNotFound {
		t.Errorf("编辑回收站笔记应 404，实际 %d: %s", w.Code, w.Body.String())
	}

	// 发布已删除笔记应 404
	if w := e.do(http.MethodPost, "/api/notes/"+noteID+"/publish", nil, cookie); w.Code != http.StatusNotFound {
		t.Errorf("发布回收站笔记应 404，实际 %d: %s", w.Code, w.Body.String())
	}
}
