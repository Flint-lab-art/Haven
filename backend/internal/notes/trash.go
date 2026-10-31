package notes

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
)

// 回收站（docs/v2/api.md 第二、四节）。
//
// 删除只写 notes.deleted_at，folder_id 保留即「原位置」；
// 原文件夹被删除时由外键 ON DELETE SET NULL 置空，还原时归入收件箱。

// TrashRetention 是回收站的保留时长。超过后由惰性清理物理删除。
//
// 这是代码常量，不从环境变量读取（docs/v2/conventions.md 第一节第 6 条）。
const TrashRetention = 30 * 24 * time.Hour

// TrashItem 是回收站列表项（docs/v2/api.md 2.1）。
type TrashItem struct {
	ID             string    `json:"id"`
	Title          string    `json:"title"`
	ContentPreview string    `json:"content_preview"`
	FolderID       *string   `json:"folder_id"`
	FolderPath     string    `json:"folder_path"`
	DeletedAt      time.Time `json:"deleted_at"`
}

// ListTrash 返回当前用户的回收站列表。调用前会顺带清理超过保留期的记录。
func (s *Service) ListTrash(ctx context.Context, userID string, limit, offset int) ([]TrashItem, int, error) {
	if err := s.cleanupExpired(ctx, userID); err != nil {
		return nil, 0, err
	}

	const countQ = `
		SELECT count(*) FROM notes WHERE user_id = $1 AND deleted_at IS NOT NULL`

	var total int
	if err := s.db.QueryRowContext(ctx, countQ, userID).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("统计回收站数量失败: %w", err)
	}

	const q = `
		SELECT id, title, content, folder_id, deleted_at
		FROM notes
		WHERE user_id = $1 AND deleted_at IS NOT NULL
		ORDER BY deleted_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := s.db.QueryContext(ctx, q, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("查询回收站失败: %w", err)
	}
	defer rows.Close()

	items := make([]TrashItem, 0, limit)
	folderIDs := make([]string, 0, limit)
	for rows.Next() {
		var content string
		var item TrashItem
		if err := rows.Scan(&item.ID, &item.Title, &content, &item.FolderID, &item.DeletedAt); err != nil {
			return nil, 0, fmt.Errorf("扫描回收站失败: %w", err)
		}
		item.ContentPreview = Preview(content)
		items = append(items, item)
		if item.FolderID != nil {
			folderIDs = append(folderIDs, *item.FolderID)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("读取回收站失败: %w", err)
	}

	paths, err := s.folderPaths(ctx, userID, folderIDs)
	if err != nil {
		return nil, 0, err
	}
	for i := range items {
		if items[i].FolderID != nil {
			items[i].FolderPath = paths[*items[i].FolderID]
		}
	}
	return items, total, nil
}

// Restore 把笔记从回收站还原（docs/v2/api.md 2.2）。
//
// 原 folder_id 仍存在则回到原文件夹；已被外键置 NULL 时归入收件箱。
func (s *Service) Restore(ctx context.Context, userID, id string) (Note, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return Note{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	var folderID *string
	err = tx.QueryRowContext(ctx, `
		SELECT folder_id FROM notes
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NOT NULL`, id, userID).Scan(&folderID)
	if errors.Is(err, sql.ErrNoRows) {
		return Note{}, ErrNotFound
	}
	if err != nil {
		return Note{}, fmt.Errorf("查询回收站笔记失败: %w", err)
	}

	// 原文件夹已不存在（或笔记本来就没有归属）时落到收件箱。
	if folderID == nil {
		inbox, err := inboxFolderID(ctx, tx, userID)
		if err != nil {
			return Note{}, err
		}
		folderID = inbox
	}

	if _, err := tx.ExecContext(ctx, `
		UPDATE notes
		SET deleted_at = NULL, folder_id = $3
		WHERE id = $1 AND user_id = $2`, id, userID, folderValue(folderID)); err != nil {
		return Note{}, fmt.Errorf("还原笔记失败: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return Note{}, fmt.Errorf("提交事务失败: %w", err)
	}
	return s.Get(ctx, userID, id)
}

// Purge 永久删除一篇回收站中的笔记（docs/v2/api.md 2.3）。
//
// 只对已在回收站中的笔记有效；未删除的笔记返回 ErrNotFound，避免误调用造成硬删。
func (s *Service) Purge(ctx context.Context, userID, id string) error {
	res, err := s.db.ExecContext(ctx, `
		DELETE FROM notes
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NOT NULL`, id, userID)
	if err != nil {
		return fmt.Errorf("永久删除笔记失败: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("读取永久删除结果失败: %w", err)
	}
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// EmptyTrash 清空回收站（docs/v2/api.md 2.4）。
func (s *Service) EmptyTrash(ctx context.Context, userID string) error {
	if _, err := s.db.ExecContext(ctx, `
		DELETE FROM notes WHERE user_id = $1 AND deleted_at IS NOT NULL`, userID); err != nil {
		return fmt.Errorf("清空回收站失败: %w", err)
	}
	return nil
}

// cleanupExpired 惰性清理超过保留期的回收站记录（docs/v2/api.md 第四节）。
func (s *Service) cleanupExpired(ctx context.Context, userID string) error {
	if _, err := s.db.ExecContext(ctx, `
		DELETE FROM notes
		WHERE user_id = $1
		  AND deleted_at IS NOT NULL
		  AND deleted_at < $2`, userID, s.now().Add(-TrashRetention)); err != nil {
		return fmt.Errorf("清理过期回收站失败: %w", err)
	}
	return nil
}

// folderNode 是拼路径用的文件夹信息。
type folderNode struct {
	parent *string
	name   string
}

// folderPaths 把文件夹 id 映射成「祖先 / … / 自身」形式的路径。
//
// 一次查出该用户的全部文件夹后在内存里拼，避免逐条递归查询。
func (s *Service) folderPaths(ctx context.Context, userID string, ids []string) (map[string]string, error) {
	out := make(map[string]string, len(ids))
	if len(ids) == 0 {
		return out, nil
	}

	rows, err := s.db.QueryContext(ctx, `
		SELECT id, parent_id, name FROM folders WHERE user_id = $1`, userID)
	if err != nil {
		return nil, fmt.Errorf("查询文件夹失败: %w", err)
	}
	defer rows.Close()

	nodes := make(map[string]folderNode, 16)
	for rows.Next() {
		var id, name string
		var parent *string
		if err := rows.Scan(&id, &parent, &name); err != nil {
			return nil, fmt.Errorf("扫描文件夹失败: %w", err)
		}
		nodes[id] = folderNode{parent: parent, name: name}
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取文件夹失败: %w", err)
	}

	for _, id := range ids {
		out[id] = buildFolderPath(nodes, id)
	}
	return out, nil
}

// buildFolderPath 从节点向上回溯拼出「祖先 / … / 自身」。
//
// 遇到缺失节点、或超过节点总数（说明数据成环）时提前停止，避免死循环。
func buildFolderPath(nodes map[string]folderNode, id string) string {
	parts := make([]string, 0, 4)
	seen := make(map[string]bool, 4)
	for cur := id; cur != ""; {
		if seen[cur] || len(seen) > len(nodes) {
			break
		}
		seen[cur] = true

		n, ok := nodes[cur]
		if !ok {
			break
		}
		parts = append(parts, n.name)
		if n.parent == nil {
			break
		}
		cur = *n.parent
	}

	// parts 是「自身 → 祖先」，反转成「祖先 / … / 自身」。
	for i, j := 0, len(parts)-1; i < j; i, j = i+1, j-1 {
		parts[i], parts[j] = parts[j], parts[i]
	}
	return strings.Join(parts, " / ")
}
