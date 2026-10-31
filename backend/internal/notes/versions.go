package notes

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// 历史版本（docs/v2/api.md 第三、四节）。
//
// 编辑前把当前内容写进 note_versions；同一笔记在合并窗口内的多次修改只保留最早的一条，
// 避免编辑器 1 秒自动保存把时间线刷爆。

// VersionMergeWindow 是同一笔记相邻快照的合并窗口。
//
// 这是代码常量，不从环境变量读取（docs/v2/conventions.md 第一节第 6 条）。
const VersionMergeWindow = 5 * time.Minute

// VersionSummary 是版本列表项（docs/v2/api.md 3.1）。
type VersionSummary struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	CreatedAt   time.Time `json:"created_at"`
	ContentSize int       `json:"content_size"`
}

// Version 是单个版本的完整快照（docs/v2/api.md 3.2）。
type Version struct {
	ID        string    `json:"id"`
	NoteID    string    `json:"note_id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	FolderID  *string   `json:"folder_id"`
	TagIDs    []string  `json:"tag_ids"`
	CreatedAt time.Time `json:"created_at"`
}

// snapshot 是写快照时用到的笔记当前状态。
type snapshot struct {
	Title    string
	Content  string
	FolderID *string
	TagIDs   []string
}

// snapshotIfChanged 在事务内写入一条快照，仅当内容真的变化时。
//
// before 是更新前的状态，after 是这次更新想写入的状态。
// 比较只关心 title / content / folder_id / tag_ids，不含 sort_order（只调排序不产生版本）。
func (s *Service) snapshotIfChanged(
	ctx context.Context, tx *sql.Tx, userID, noteID string, before, after snapshot, now time.Time,
) error {
	if !before.differs(after) {
		return nil
	}

	// 合并窗口：该笔记最新一条快照若还在窗口内，就不再新增。
	const recentQ = `
		SELECT count(*) FROM note_versions
		WHERE note_id = $1 AND created_at > $2`

	var recent int
	if err := tx.QueryRowContext(ctx, recentQ, noteID, now.Add(-VersionMergeWindow)).Scan(&recent); err != nil {
		return fmt.Errorf("检查快照合并窗口失败: %w", err)
	}
	if recent > 0 {
		return nil
	}

	const insQ = `
		INSERT INTO note_versions (note_id, user_id, title, content, folder_id, tag_ids, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`

	tagIDs := before.TagIDs
	if tagIDs == nil {
		tagIDs = []string{}
	}
	if _, err := tx.ExecContext(ctx, insQ,
		noteID, userID, before.Title, before.Content, folderValue(before.FolderID), tagIDs, now); err != nil {
		return fmt.Errorf("写入笔记快照失败: %w", err)
	}
	return nil
}

// differs 判断两次状态在需要留档的字段上是否不同。
func (a snapshot) differs(b snapshot) bool {
	if a.Title != b.Title || a.Content != b.Content {
		return true
	}
	if (a.FolderID == nil) != (b.FolderID == nil) {
		return true
	}
	if a.FolderID != nil && *a.FolderID != *b.FolderID {
		return true
	}
	if len(a.TagIDs) != len(b.TagIDs) {
		return true
	}
	set := make(map[string]struct{}, len(a.TagIDs))
	for _, id := range a.TagIDs {
		set[id] = struct{}{}
	}
	for _, id := range b.TagIDs {
		if _, ok := set[id]; !ok {
			return true
		}
	}
	return false
}

// tagIDsOf 读取笔记当前的标签 id（按 id 排序，保证比较稳定）。
func tagIDsOf(ctx context.Context, tx *sql.Tx, noteID string) ([]string, error) {
	const q = `SELECT tag_id::text FROM note_tags WHERE note_id = $1 ORDER BY tag_id`
	rows, err := tx.QueryContext(ctx, q, noteID)
	if err != nil {
		return nil, fmt.Errorf("查询笔记标签失败: %w", err)
	}
	defer rows.Close()

	out := make([]string, 0, 4)
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("扫描笔记标签失败: %w", err)
		}
		out = append(out, id)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取笔记标签失败: %w", err)
	}
	return out, nil
}

// ListVersions 返回笔记的历史版本列表（docs/v2/api.md 3.1），不返回正文。
func (s *Service) ListVersions(ctx context.Context, userID, noteID string, limit, offset int) ([]VersionSummary, int, error) {
	if err := s.ensureLiveNote(ctx, userID, noteID); err != nil {
		return nil, 0, err
	}

	const countQ = `SELECT count(*) FROM note_versions WHERE note_id = $1 AND user_id = $2`
	var total int
	if err := s.db.QueryRowContext(ctx, countQ, noteID, userID).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("统计历史版本失败: %w", err)
	}

	const q = `
		SELECT id, title, length(content), created_at
		FROM note_versions
		WHERE note_id = $1 AND user_id = $2
		ORDER BY created_at DESC
		LIMIT $3 OFFSET $4`

	rows, err := s.db.QueryContext(ctx, q, noteID, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("查询历史版本失败: %w", err)
	}
	defer rows.Close()

	items := make([]VersionSummary, 0, limit)
	for rows.Next() {
		var v VersionSummary
		if err := rows.Scan(&v.ID, &v.Title, &v.ContentSize, &v.CreatedAt); err != nil {
			return nil, 0, fmt.Errorf("扫描历史版本失败: %w", err)
		}
		items = append(items, v)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("读取历史版本失败: %w", err)
	}
	return items, total, nil
}

// GetVersion 返回单个版本的完整快照（docs/v2/api.md 3.2）。
func (s *Service) GetVersion(ctx context.Context, userID, noteID, versionID string) (Version, error) {
	if err := s.ensureLiveNote(ctx, userID, noteID); err != nil {
		return Version{}, err
	}

	const q = `
		SELECT id, note_id, title, content, folder_id, tag_ids, created_at
		FROM note_versions
		WHERE id = $1 AND note_id = $2 AND user_id = $3`

	var v Version
	err := s.db.QueryRowContext(ctx, q, versionID, noteID, userID).Scan(
		&v.ID, &v.NoteID, &v.Title, &v.Content, &v.FolderID, &v.TagIDs, &v.CreatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return Version{}, ErrNotFound
	}
	if err != nil {
		return Version{}, fmt.Errorf("查询历史版本失败: %w", err)
	}
	if v.TagIDs == nil {
		v.TagIDs = []string{}
	}
	return v, nil
}

// RestoreVersion 把笔记内容回滚到指定版本（docs/v2/api.md 3.3）。
//
// 还原前会把当前内容写进一条新快照（同样受合并窗口约束），以便再次还原回去。
func (s *Service) RestoreVersion(ctx context.Context, userID, noteID, versionID string) (Note, error) {
	// 复用 Update：它已经在事务内完成「写快照 → 覆盖字段 → 刷新 updated_at」的全流程。
	v, err := s.GetVersion(ctx, userID, noteID, versionID)
	if err != nil {
		return Note{}, err
	}

	// 标签里可能有已被物理删除的 id，这里过滤掉，避免整次还原失败。
	tagIDs, err := s.existingTagIDs(ctx, userID, v.TagIDs)
	if err != nil {
		return Note{}, err
	}

	targetFolder := v.FolderID
	if targetFolder != nil {
		var exists bool
		if err := s.db.QueryRowContext(ctx,
			`SELECT EXISTS (SELECT 1 FROM folders WHERE id = $1 AND user_id = $2)`,
			*targetFolder, userID).Scan(&exists); err != nil {
			return Note{}, fmt.Errorf("校验快照文件夹失败: %w", err)
		}
		if !exists {
			// 原文件夹已不存在：交给 Update 的 null 语义落到收件箱。
			targetFolder = nil
		}
	}

	title := v.Title
	content := v.Content
	in := UpdateInput{
		Title:       &title,
		Content:     &content,
		FolderID:    targetFolder,
		FolderIDSet: true,
		TagIDs:      tagIDs,
	}
	return s.Update(ctx, userID, noteID, in)
}

// existingTagIDs 过滤掉已不存在的标签 id。
func (s *Service) existingTagIDs(ctx context.Context, userID string, ids []string) ([]string, error) {
	if len(ids) == 0 {
		return []string{}, nil
	}

	rows, err := s.db.QueryContext(ctx,
		`SELECT id::text FROM tags WHERE user_id = $1 AND id = ANY($2)`, userID, ids)
	if err != nil {
		return nil, fmt.Errorf("校验快照标签失败: %w", err)
	}
	defer rows.Close()

	out := make([]string, 0, len(ids))
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("扫描快照标签失败: %w", err)
		}
		out = append(out, id)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取快照标签失败: %w", err)
	}
	return out, nil
}

// ensureLiveNote 确认笔记存在、属于当前用户且未在回收站，否则返回 ErrNotFound。
func (s *Service) ensureLiveNote(ctx context.Context, userID, noteID string) error {
	var exists bool
	if err := s.db.QueryRowContext(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM notes WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
		)`, noteID, userID).Scan(&exists); err != nil {
		return fmt.Errorf("查询笔记失败: %w", err)
	}
	if !exists {
		return ErrNotFound
	}
	return nil
}
