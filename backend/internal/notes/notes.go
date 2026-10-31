// Package notes 实现笔记领域：私有侧 CRUD + publish/unpublish，
// 以及公开侧只读列表与详情。
//
// 依据 docs/api.md 第六、七节 与 docs/backend/data-model.md 第三节。
// 公开可见的判定条件全库唯一：visibility = 'public' AND published_at IS NOT NULL。
package notes

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"
)

// 领域错误，由 handler 映射成 api.md 1.4 的状态码。
var (
	// ErrNotFound 笔记不存在（或不属于当前用户）。跨用户访问一律 404（auth.md 6.4）。
	ErrNotFound = errors.New("笔记不存在")
	// ErrAlreadyPublic / ErrAlreadyPrivate 用于 publish / unpublish 的 409。
	ErrAlreadyPublic  = errors.New("笔记已是 public")
	ErrAlreadyPrivate = errors.New("笔记已是 private")
	// ErrInvalidTag 表示 tag_ids 里有不属于当前用户的标签（422）。
	ErrInvalidTag = errors.New("标签不存在")
	// ErrInvalidFolder 表示 folder_id 指向不存在的文件夹或不属于当前用户（422）。
	ErrInvalidFolder = errors.New("文件夹不存在")
	// ErrTitleRequired 标题为空（422）。
	ErrTitleRequired = errors.New("标题不能为空")
	// ErrInvalidSortOrder 排序值为负数（422）。
	ErrInvalidSortOrder = errors.New("排序值不能为负数")
)

// PreviewRuneLimit 是列表里 content_preview 的截断长度（api.md 6.1 备注）。
const PreviewRuneLimit = 200

// TagBrief 是笔记响应里内嵌的标签（api.md 6.1）。
type TagBrief struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// Note 是详情响应（api.md 6.2）。
type Note struct {
	ID          string     `json:"id"`
	FolderID    *string    `json:"folder_id"`
	SortOrder   int        `json:"sort_order"`
	Title       string     `json:"title"`
	Content     string     `json:"content"`
	Visibility  string     `json:"visibility"`
	PublishedAt *time.Time `json:"published_at"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	Tags        []TagBrief `json:"tags"`
}

// NoteSummary 是私有列表项（api.md 6.1）：不含 content，含 content_preview。
type NoteSummary struct {
	ID             string     `json:"id"`
	FolderID       *string    `json:"folder_id"`
	SortOrder      int        `json:"sort_order"`
	Title          string     `json:"title"`
	ContentPreview string     `json:"content_preview"`
	Visibility     string     `json:"visibility"`
	PublishedAt    *time.Time `json:"published_at"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	Tags           []TagBrief `json:"tags"`
}

// PublicNote 是公开详情（api.md 7.2）：不含 visibility / created_at。
type PublicNote struct {
	ID          string     `json:"id"`
	Title       string     `json:"title"`
	Content     string     `json:"content"`
	PublishedAt time.Time  `json:"published_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	Tags        []TagBrief `json:"tags"`
}

// PublicNoteSummary 是公开列表项（api.md 7.1）。
type PublicNoteSummary struct {
	ID             string     `json:"id"`
	Title          string     `json:"title"`
	ContentPreview string     `json:"content_preview"`
	PublishedAt    time.Time  `json:"published_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	Tags           []TagBrief `json:"tags"`
}

// ListFilter 是私有列表的过滤条件（api.md 6.1 查询参数）。
type ListFilter struct {
	Visibility string // 空表示不过滤
	TagID      string // 空表示不过滤
	// FolderFilter 为 true 时按 FolderID 过滤；
	// FolderID 为空串表示「收件箱」（folder_id IS NULL）。
	FolderFilter bool
	FolderID     string
}

// CreateInput 是 POST /api/notes 的入参。
//
// 刻意没有 Visibility 字段：新建一律 private（api.md 6.3、conventions.md 第四节）。
type CreateInput struct {
	Title    string
	Content  string
	TagIDs   []string
	FolderID *string
}

// UpdateInput 是 PATCH /api/notes/:id 的入参。
//
// 字段为指针以区分「未出现」与「显式置空」（api.md 1.7 部分更新）。
// TagIDs 为 nil 表示未出现；非 nil 表示全量替换（含空数组 = 清空标签）。
// FolderIDSet 为 true 时，FolderID 为 nil 表示移回收件箱。
// SortOrder 为 nil 表示未出现；非 nil 时必须是 >= 0 的整数。
type UpdateInput struct {
	Title       *string
	Content     *string
	TagIDs      []string
	FolderID    *string
	FolderIDSet bool
	SortOrder   *int
}

// Service 承载笔记领域逻辑，不依赖 gin。
type Service struct {
	db  *sql.DB
	now func() time.Time
}

// NewService 构造 Service。
func NewService(db *sql.DB) *Service {
	return &Service{db: db, now: time.Now}
}

// Preview 按 rune 截断正文至 PreviewRuneLimit，超出以 … 结尾（api.md 6.1）。
func Preview(content string) string {
	runes := []rune(content)
	if len(runes) <= PreviewRuneLimit {
		return content
	}
	return string(runes[:PreviewRuneLimit]) + "…"
}

// ListPrivate 返回当前用户的笔记列表（api.md 6.1）。
//
// vis 由授权中间件注入（auth.md 6.3）：登录用户为「自己的 OR 公开」。
// $1 恒为当前用户 id，既供可见性条件使用，也是归属过滤（auth.md 6.4）。
func (s *Service) ListPrivate(ctx context.Context, userID string, vis auth.Visibility, f ListFilter, limit, offset int) ([]NoteSummary, int, error) {
	if vis.Condition == "" {
		// 没有可见性条件 = 什么都不可见（auth.Visibility 注释）
		return []NoteSummary{}, 0, nil
	}

	var tagID any
	if f.TagID != "" {
		tagID = f.TagID
	}

	// 可见性条件必须整体加括号：它自身含 OR（auth.md 6.3），
	// 不括起来会与后面的 AND 条件混在一起，把可见性过滤绕开。
	const whereTmpl = `
		WHERE (%VIS%)
		  AND ($2 = '' OR visibility = $2)
		  AND ($3::uuid IS NULL OR id IN (SELECT note_id FROM note_tags WHERE tag_id = $3))
		  AND (NOT $4::boolean
		       OR (folder_id IS NULL AND $5 = '')
		       OR folder_id = NULLIF($5, '')::uuid)`

	base := strings.Replace(whereTmpl, "%VIS%", vis.Condition, 1)
	// 参数：$1 = userID（可见性条件与归属过滤共用）
	args := append([]any{userID}, f.Visibility, tagID, f.FolderFilter, f.FolderID)

	var total int
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM notes`+base, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("统计笔记数量失败: %w", err)
	}

	// 传 folder_id 时（含空串 = 收件箱）按目录内自定义顺序；
	// 不传 folder_id 时保持「最近更新」排序（api.md 6.1）。
	orderBy := "updated_at DESC"
	if f.FolderFilter {
		orderBy = "sort_order ASC, updated_at DESC"
	}

	q := `
		SELECT id, folder_id, sort_order, title, content, visibility, published_at, created_at, updated_at
		FROM notes` + base + `
		ORDER BY ` + orderBy + `
		LIMIT $6 OFFSET $7`

	listArgs := append(append([]any{}, args...), limit, offset)

	rows, err := s.db.QueryContext(ctx, q, listArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("查询笔记列表失败: %w", err)
	}
	defer rows.Close()

	items := make([]NoteSummary, 0, limit)
	ids := make([]string, 0, limit)
	for rows.Next() {
		var content string
		var item NoteSummary
		if err := rows.Scan(&item.ID, &item.FolderID, &item.SortOrder, &item.Title, &content, &item.Visibility,
			&item.PublishedAt, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, 0, fmt.Errorf("扫描笔记失败: %w", err)
		}
		item.ContentPreview = Preview(content)
		items = append(items, item)
		ids = append(ids, item.ID)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("读取笔记列表失败: %w", err)
	}

	tags, err := s.tagsFor(ctx, ids)
	if err != nil {
		return nil, 0, err
	}
	for i := range items {
		items[i].Tags = tags[items[i].ID]
	}

	return items, total, nil
}

// Get 返回当前用户的一篇笔记详情（api.md 6.2）。
func (s *Service) Get(ctx context.Context, userID, id string) (Note, error) {
	const q = `
		SELECT id, folder_id, sort_order, title, content, visibility, published_at, created_at, updated_at
		FROM notes
		WHERE id = $1 AND user_id = $2`

	var n Note
	err := s.db.QueryRowContext(ctx, q, id, userID).Scan(
		&n.ID, &n.FolderID, &n.SortOrder, &n.Title, &n.Content, &n.Visibility, &n.PublishedAt, &n.CreatedAt, &n.UpdatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return Note{}, ErrNotFound
	}
	if err != nil {
		return Note{}, fmt.Errorf("查询笔记失败: %w", err)
	}

	tags, err := s.tagsFor(ctx, []string{id})
	if err != nil {
		return Note{}, err
	}
	n.Tags = tags[id]
	return n, nil
}

// Create 新建笔记（api.md 6.3）。
//
// visibility 不参与写入，由数据库 DEFAULT 'private' 兜底（conventions.md 第四节）。
func (s *Service) Create(ctx context.Context, userID string, in CreateInput) (Note, error) {
	title := strings.TrimSpace(in.Title)
	if title == "" {
		return Note{}, ErrTitleRequired
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return Note{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	// 不传 folder_id 时默认归入收件箱；没有收件箱的历史数据再回落到 NULL。
	folderID := in.FolderID
	if folderID == nil {
		folderID, err = inboxFolderID(ctx, tx, userID)
		if err != nil {
			return Note{}, err
		}
	}
	if folderID != nil {
		if err := validateFolder(ctx, tx, userID, *folderID); err != nil {
			return Note{}, err
		}
	}

	var id string
	if err := tx.QueryRowContext(ctx,
		`INSERT INTO notes (user_id, folder_id, title, content) VALUES ($1, $2, $3, $4) RETURNING id`,
		userID, folderValue(folderID), title, in.Content).Scan(&id); err != nil {
		return Note{}, fmt.Errorf("创建笔记失败: %w", err)
	}

	if err := s.replaceTags(ctx, tx, userID, id, in.TagIDs); err != nil {
		return Note{}, err
	}

	if err := tx.Commit(); err != nil {
		return Note{}, fmt.Errorf("提交事务失败: %w", err)
	}
	return s.Get(ctx, userID, id)
}

// Update 局部更新笔记（api.md 6.4 / 1.7）。
func (s *Service) Update(ctx context.Context, userID, id string, in UpdateInput) (Note, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return Note{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	// 先确认归属并取出当前文件夹，顺便区分 404 与「是否真的移动」。
	var currentFolderID *string
	err = tx.QueryRowContext(ctx,
		`SELECT folder_id FROM notes WHERE id = $1 AND user_id = $2`,
		id, userID).Scan(&currentFolderID)
	if errors.Is(err, sql.ErrNoRows) {
		return Note{}, ErrNotFound
	}
	if err != nil {
		return Note{}, fmt.Errorf("查询笔记失败: %w", err)
	}

	if in.SortOrder != nil && *in.SortOrder < 0 {
		return Note{}, ErrInvalidSortOrder
	}

	if in.Title != nil {
		title := strings.TrimSpace(*in.Title)
		if title == "" {
			return Note{}, ErrTitleRequired
		}
		if _, err := tx.ExecContext(ctx,
			`UPDATE notes SET title = $2 WHERE id = $1`, id, title); err != nil {
			return Note{}, fmt.Errorf("更新标题失败: %w", err)
		}
	}

	if in.Content != nil {
		if _, err := tx.ExecContext(ctx,
			`UPDATE notes SET content = $2 WHERE id = $1`, id, *in.Content); err != nil {
			return Note{}, fmt.Errorf("更新正文失败: %w", err)
		}
	}

	if in.TagIDs != nil {
		if err := s.replaceTags(ctx, tx, userID, id, in.TagIDs); err != nil {
			return Note{}, err
		}
	}

	// folder_id 为 null 表示「移到收件箱」；没有收件箱的历史数据再回落到 NULL。
	targetFolder := in.FolderID
	if in.FolderIDSet && targetFolder == nil {
		targetFolder, err = inboxFolderID(ctx, tx, userID)
		if err != nil {
			return Note{}, err
		}
	}

	// 只有 folder_id 真的变化才算「移动」；编辑器每次保存都带 folder_id，
	// 不能因此把目录内自定义排序重置为 0（api.md 6.4）。
	folderChanged := in.FolderIDSet && !sameFolder(currentFolderID, targetFolder)
	if folderChanged {
		if targetFolder != nil {
			if err := validateFolder(ctx, tx, userID, *targetFolder); err != nil {
				return Note{}, err
			}
		}
		// 移动笔记时如未显式给 sort_order，按 0 处理，出现在目标目录顶部（api.md 6.4）。
		sortOrder := 0
		if in.SortOrder != nil {
			sortOrder = *in.SortOrder
		}
		if _, err := tx.ExecContext(ctx,
			`UPDATE notes SET folder_id = $2, sort_order = $3 WHERE id = $1`,
			id, folderValue(targetFolder), sortOrder); err != nil {
			return Note{}, fmt.Errorf("更新文件夹归属失败: %w", err)
		}
	} else if in.SortOrder != nil {
		if _, err := tx.ExecContext(ctx,
			`UPDATE notes SET sort_order = $2 WHERE id = $1`, id, *in.SortOrder); err != nil {
			return Note{}, fmt.Errorf("更新笔记排序失败: %w", err)
		}
	}

	// 仅调整 sort_order 不算内容更新，不刷新 updated_at（data-model.md 第三节规则 10）。
	onlySortOrder := in.SortOrder != nil && !folderChanged &&
		in.Title == nil && in.Content == nil && in.TagIDs == nil
	if !onlySortOrder {
		if _, err := tx.ExecContext(ctx,
			`UPDATE notes SET updated_at = now() WHERE id = $1`, id); err != nil {
			return Note{}, fmt.Errorf("更新笔记时间失败: %w", err)
		}
	}

	if err := tx.Commit(); err != nil {
		return Note{}, fmt.Errorf("提交事务失败: %w", err)
	}
	return s.Get(ctx, userID, id)
}

// Delete 删除笔记（api.md 6.5）。关联由外键级联清理。
func (s *Service) Delete(ctx context.Context, userID, id string) error {
	res, err := s.db.ExecContext(ctx, `DELETE FROM notes WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		return fmt.Errorf("删除笔记失败: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("读取删除结果失败: %w", err)
	}
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// Publish 公开笔记（api.md 6.6）。
//
// published_at 只在为 NULL 时写入；再次公开不覆盖首次发布时间。
func (s *Service) Publish(ctx context.Context, userID, id string) (Note, error) {
	const q = `
		UPDATE notes
		SET visibility = 'public',
		    published_at = COALESCE(published_at, now()),
		    updated_at = now()
		WHERE id = $1 AND user_id = $2 AND visibility = 'private'
		RETURNING id`

	var got string
	err := s.db.QueryRowContext(ctx, q, id, userID).Scan(&got)
	if errors.Is(err, sql.ErrNoRows) {
		// 区分「不存在」与「已是 public」
		note, getErr := s.Get(ctx, userID, id)
		if getErr != nil {
			return Note{}, getErr
		}
		if note.Visibility == "public" {
			return Note{}, ErrAlreadyPublic
		}
		return Note{}, ErrNotFound
	}
	if err != nil {
		return Note{}, fmt.Errorf("公开笔记失败: %w", err)
	}
	return s.Get(ctx, userID, id)
}

// Unpublish 撤回笔记（api.md 6.7）。published_at 保留不变。
func (s *Service) Unpublish(ctx context.Context, userID, id string) (Note, error) {
	const q = `
		UPDATE notes
		SET visibility = 'private',
		    updated_at = now()
		WHERE id = $1 AND user_id = $2 AND visibility = 'public'
		RETURNING id`

	var got string
	err := s.db.QueryRowContext(ctx, q, id, userID).Scan(&got)
	if errors.Is(err, sql.ErrNoRows) {
		note, getErr := s.Get(ctx, userID, id)
		if getErr != nil {
			return Note{}, getErr
		}
		if note.Visibility == "private" {
			return Note{}, ErrAlreadyPrivate
		}
		return Note{}, ErrNotFound
	}
	if err != nil {
		return Note{}, fmt.Errorf("撤回笔记失败: %w", err)
	}
	return s.Get(ctx, userID, id)
}

// ListPublic 返回公开笔记列表（api.md 7.1），跨用户。
func (s *Service) ListPublic(ctx context.Context, limit, offset int) ([]PublicNoteSummary, int, error) {
	const countQ = `SELECT count(*) FROM notes WHERE ` + authVisibilityPublic
	var total int
	if err := s.db.QueryRowContext(ctx, countQ).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("统计公开笔记失败: %w", err)
	}

	const q = `
		SELECT id, title, content, published_at, updated_at
		FROM notes
		WHERE ` + authVisibilityPublic + `
		ORDER BY published_at DESC
		LIMIT $1 OFFSET $2`

	rows, err := s.db.QueryContext(ctx, q, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("查询公开笔记失败: %w", err)
	}
	defer rows.Close()

	items := make([]PublicNoteSummary, 0, limit)
	ids := make([]string, 0, limit)
	for rows.Next() {
		var content string
		var item PublicNoteSummary
		if err := rows.Scan(&item.ID, &item.Title, &content, &item.PublishedAt, &item.UpdatedAt); err != nil {
			return nil, 0, fmt.Errorf("扫描公开笔记失败: %w", err)
		}
		item.ContentPreview = Preview(content)
		items = append(items, item)
		ids = append(ids, item.ID)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("读取公开笔记失败: %w", err)
	}

	tags, err := s.tagsFor(ctx, ids)
	if err != nil {
		return nil, 0, err
	}
	for i := range items {
		items[i].Tags = tags[items[i].ID]
	}

	return items, total, nil
}

// GetPublic 返回公开笔记详情（api.md 7.2）。非 public 或 published_at 为空一律 404。
func (s *Service) GetPublic(ctx context.Context, id string) (PublicNote, error) {
	const q = `
		SELECT id, title, content, published_at, updated_at
		FROM notes
		WHERE id = $1 AND ` + authVisibilityPublic

	var n PublicNote
	err := s.db.QueryRowContext(ctx, q, id).Scan(
		&n.ID, &n.Title, &n.Content, &n.PublishedAt, &n.UpdatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return PublicNote{}, ErrNotFound
	}
	if err != nil {
		return PublicNote{}, fmt.Errorf("查询公开笔记失败: %w", err)
	}

	tags, err := s.tagsFor(ctx, []string{id})
	if err != nil {
		return PublicNote{}, err
	}
	n.Tags = tags[id]
	return n, nil
}

// authVisibilityPublic 是全库唯一的公开可见条件（data-model.md 第十节规则 4）。
// 直接引用 auth 包的常量，避免同一条件出现第二份定义。
const authVisibilityPublic = auth.VisibilityPublic

// validateFolder 校验文件夹属于当前用户（data-model.md 第三节规则 9）。
func validateFolder(ctx context.Context, tx *sql.Tx, userID, folderID string) error {
	var exists bool
	if err := tx.QueryRowContext(ctx,
		`SELECT EXISTS (SELECT 1 FROM folders WHERE id = $1 AND user_id = $2)`,
		folderID, userID).Scan(&exists); err != nil {
		return fmt.Errorf("校验文件夹失败: %w", err)
	}
	if !exists {
		return ErrInvalidFolder
	}
	return nil
}

// folderValue 把可选文件夹转成驱动可接受的值（nil → SQL NULL）。
// rowQuerier 让 *sql.DB 与 *sql.Tx 共用同一个查询函数。
type rowQuerier interface {
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

// inboxFolderID 返回当前用户的收件箱 id；没有收件箱时返回 nil（历史数据兜底）。
func inboxFolderID(ctx context.Context, q rowQuerier, userID string) (*string, error) {
	var id string
	err := q.QueryRowContext(ctx,
		`SELECT id FROM folders WHERE user_id = $1 AND is_inbox`, userID).Scan(&id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("查询收件箱失败: %w", err)
	}
	return &id, nil
}

// InboxID 返回当前用户的收件箱 id，供 handler 解析 folder_id= 别名。
func (s *Service) InboxID(ctx context.Context, userID string) (*string, error) {
	return inboxFolderID(ctx, s.db, userID)
}

// sameFolder 判断两个可空文件夹 id 是否相同（nil == nil）。
func sameFolder(a, b *string) bool {
	if a == nil || b == nil {
		return a == nil && b == nil
	}
	return *a == *b
}

func folderValue(folderID *string) any {
	if folderID == nil {
		return nil
	}
	return *folderID
}

// replaceTags 全量替换笔记的标签关联，并校验标签属于当前用户。
func (s *Service) replaceTags(ctx context.Context, tx *sql.Tx, userID, noteID string, tagIDs []string) error {
	if tagIDs == nil {
		return nil
	}

	// 去重，避免同一标签重复关联导致主键冲突
	seen := make(map[string]struct{}, len(tagIDs))
	unique := make([]string, 0, len(tagIDs))
	for _, id := range tagIDs {
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		unique = append(unique, id)
	}

	if len(unique) > 0 {
		// 校验每个标签都属于当前用户（data-model.md 第五节规则 3）
		var owned int
		if err := tx.QueryRowContext(ctx,
			`SELECT count(*) FROM tags WHERE user_id = $1 AND id = ANY($2)`,
			userID, unique).Scan(&owned); err != nil {
			return fmt.Errorf("校验标签失败: %w", err)
		}
		if owned != len(unique) {
			return ErrInvalidTag
		}
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM note_tags WHERE note_id = $1`, noteID); err != nil {
		return fmt.Errorf("清理笔记标签失败: %w", err)
	}

	for _, tagID := range unique {
		if _, err := tx.ExecContext(ctx,
			`INSERT INTO note_tags (note_id, tag_id) VALUES ($1, $2)`, noteID, tagID); err != nil {
			return fmt.Errorf("关联标签失败: %w", err)
		}
	}
	return nil
}

// tagsFor 批量取多篇笔记的标签，返回 note_id -> tags。
func (s *Service) tagsFor(ctx context.Context, noteIDs []string) (map[string][]TagBrief, error) {
	out := make(map[string][]TagBrief, len(noteIDs))
	if len(noteIDs) == 0 {
		return out, nil
	}

	const q = `
		SELECT nt.note_id, t.id, t.name
		FROM note_tags nt
		JOIN tags t ON t.id = nt.tag_id
		WHERE nt.note_id = ANY($1)
		ORDER BY t.name`

	rows, err := s.db.QueryContext(ctx, q, noteIDs)
	if err != nil {
		return nil, fmt.Errorf("查询笔记标签失败: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var noteID string
		var tag TagBrief
		if err := rows.Scan(&noteID, &tag.ID, &tag.Name); err != nil {
			return nil, fmt.Errorf("扫描笔记标签失败: %w", err)
		}
		out[noteID] = append(out[noteID], tag)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取笔记标签失败: %w", err)
	}

	// 没有标签的笔记返回空数组而不是 null（api.md 1.3）
	for _, id := range noteIDs {
		if out[id] == nil {
			out[id] = []TagBrief{}
		}
	}
	return out, nil
}

// 编译期断言：列表响应包裹由 httpx 统一构造。
var _ = httpx.NewList
