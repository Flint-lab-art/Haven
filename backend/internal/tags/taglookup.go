package tags

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/kairo/haven/internal/notes"
)

// notesTagsFor 批量取多篇笔记的标签，返回 note_id -> []notes.TagBrief。
//
// 交给 notes 包统一实现，避免 tags 与 notes 各自维护一份「标签列表 + 空数组」规则。
func notesTagsFor(ctx context.Context, db *sql.DB, noteIDs []string) (map[string][]notes.TagBrief, error) {
	out := make(map[string][]notes.TagBrief, len(noteIDs))
	if len(noteIDs) == 0 {
		return out, nil
	}

	const q = `
		SELECT nt.note_id, t.id, t.name
		FROM note_tags nt
		JOIN tags t ON t.id = nt.tag_id
		WHERE nt.note_id = ANY($1)
		ORDER BY t.name`

	rows, err := db.QueryContext(ctx, q, noteIDs)
	if err != nil {
		return nil, fmt.Errorf("查询笔记标签失败: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var noteID string
		var tag notes.TagBrief
		if err := rows.Scan(&noteID, &tag.ID, &tag.Name); err != nil {
			return nil, fmt.Errorf("扫描笔记标签失败: %w", err)
		}
		out[noteID] = append(out[noteID], tag)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取笔记标签失败: %w", err)
	}

	for _, id := range noteIDs {
		if out[id] == nil {
			out[id] = []notes.TagBrief{}
		}
	}
	return out, nil
}
