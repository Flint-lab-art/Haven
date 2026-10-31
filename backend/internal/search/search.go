// Package search 实现搜索（docs/api.md 第九节）。
//
// 只做子串包含查询（data-model.md 第八节）：
//   - 笔记查生成列 notes.search_text，应用层不写该字段；
//   - 标签查 tags.name；
//   - 不安装中文分词扩展，1–2 字查询退化为全表扫描，接受该代价。
//   匹配规则见 docs/backend/search.md。
package search

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"
	"github.com/kairo/haven/internal/notes"

	"github.com/gin-gonic/gin"
)

// 领域错误。
var (
	// ErrQueryRequired 缺少或空的 q（422）。
	ErrQueryRequired = fmt.Errorf("搜索关键词不能为空")
)

// escapeLike 转义 ILIKE 的通配符，使关键词按字面匹配（含 % 和 _ 的个人笔记也能搜到）。
func escapeLike(q string) string {
	r := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)
	return "%" + r.Replace(q) + "%"
}

// TagBrief 是笔记里内嵌的标签。
type TagBrief struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// NoteHit 是搜索返回的笔记项（api.md 10.1 / 10.2），不含正文，只返回标题与元信息。
type NoteHit struct {
	ID             string     `json:"id"`
	Title          string     `json:"title"`
	ContentPreview string     `json:"content_preview"`
	Visibility     string     `json:"visibility,omitempty"`
	PublishedAt    *time.Time `json:"published_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	Tags           []TagBrief `json:"tags"`
}

// TagHit 是搜索返回的标签项（api.md 10.1）。
type TagHit struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	NoteCount int    `json:"note_count"`
}

// PrivateResult 是 GET /api/search 的响应（api.md 10.1）。
type PrivateResult struct {
	Notes Section `json:"notes"`
	Tags  Section `json:"tags"`
}

// Section 是结果分块：{items, total}。
type Section struct {
	Items any `json:"items"`
	Total int `json:"total"`
}

// PublicResult 是 GET /api/public/search 的响应（api.md 10.2）：只有笔记列表。
type PublicResult struct {
	Items []NoteHit `json:"items"`
	Total int       `json:"total"`
}

// Service 承载搜索逻辑。
type Service struct {
	db *sql.DB
}

// NewService 构造 Service。
func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// Private 执行已登录用户的搜索（api.md 10.1）。
//
// vis 由授权中间件注入（auth.md 6.3）：登录用户为「自己的 OR 公开」，
// $1 恒为当前用户 id。分页只作用于笔记结果。
func (s *Service) Private(ctx context.Context, userID string, vis auth.Visibility, q string, limit, offset int) (PrivateResult, error) {
	if vis.Condition == "" {
		return PrivateResult{
			Notes: Section{Items: []NoteHit{}, Total: 0},
			Tags:  Section{Items: []TagHit{}, Total: 0},
		}, nil
	}
	pattern := escapeLike(strings.TrimSpace(q))

	notesCount := `
		SELECT count(*) FROM notes
		WHERE (` + vis.Condition + `) AND search_text ILIKE $2`

	var notesTotal int
	if err := s.db.QueryRowContext(ctx, notesCount, append(append([]any{}, vis.Args...), pattern)...).Scan(&notesTotal); err != nil {
		return PrivateResult{}, fmt.Errorf("统计搜索笔记失败: %w", err)
	}

	notesQ := `
		SELECT id, title, content, visibility, published_at, updated_at
		FROM notes
		WHERE ` + vis.Condition + ` AND search_text ILIKE $2
		ORDER BY updated_at DESC
		LIMIT $3 OFFSET $4`

	noteItems, err := s.scanNotes(ctx, notesQ, append(append([]any{}, vis.Args...), pattern, limit, offset)...)
	if err != nil {
		return PrivateResult{}, err
	}

	// 标签：name ILIKE
	const tagsQ = `
		SELECT t.id, t.name, count(nt.note_id) AS note_count
		FROM tags t
		LEFT JOIN note_tags nt ON nt.tag_id = t.id
		WHERE t.user_id = $1 AND t.name ILIKE $2
		GROUP BY t.id, t.name
		ORDER BY t.name`

	rows, err := s.db.QueryContext(ctx, tagsQ, userID, pattern)
	if err != nil {
		return PrivateResult{}, fmt.Errorf("搜索标签失败: %w", err)
	}
	defer rows.Close()

	tagItems := make([]TagHit, 0, 8)
	for rows.Next() {
		var t TagHit
		if err := rows.Scan(&t.ID, &t.Name, &t.NoteCount); err != nil {
			return PrivateResult{}, fmt.Errorf("扫描标签搜索结果失败: %w", err)
		}
		tagItems = append(tagItems, t)
	}
	if err := rows.Err(); err != nil {
		return PrivateResult{}, fmt.Errorf("读取标签搜索结果失败: %w", err)
	}

	return PrivateResult{
		Notes: Section{Items: noteItems, Total: notesTotal},
		Tags:  Section{Items: tagItems, Total: len(tagItems)},
	}, nil
}

// Public 执行匿名搜索（api.md 10.2）：只搜已公开笔记，不返回标签列表。
func (s *Service) Public(ctx context.Context, q string, limit, offset int) (PublicResult, error) {
	pattern := escapeLike(strings.TrimSpace(q))

	const countQ = `
		SELECT count(*) FROM notes
		WHERE ` + auth.VisibilityPublic + ` AND search_text ILIKE $1`

	var total int
	if err := s.db.QueryRowContext(ctx, countQ, pattern).Scan(&total); err != nil {
		return PublicResult{}, fmt.Errorf("统计公开搜索失败: %w", err)
	}

	const q2 = `
		SELECT id, title, content, visibility, published_at, updated_at
		FROM notes
		WHERE ` + auth.VisibilityPublic + ` AND search_text ILIKE $1
		ORDER BY published_at DESC
		LIMIT $2 OFFSET $3`

	items, err := s.scanNotes(ctx, q2, pattern, limit, offset)
	if err != nil {
		return PublicResult{}, err
	}
	// 公开搜索不暴露 visibility（api.md 10.2 的字段清单里没有它）
	for i := range items {
		items[i].Visibility = ""
	}
	return PublicResult{Items: items, Total: total}, nil
}

// scanNotes 执行笔记查询并补上标签。
func (s *Service) scanNotes(ctx context.Context, query string, args ...any) ([]NoteHit, error) {
	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("搜索笔记失败: %w", err)
	}
	defer rows.Close()

	items := make([]NoteHit, 0, 8)
	ids := make([]string, 0, 8)
	for rows.Next() {
		var content string
		var item NoteHit
		if err := rows.Scan(&item.ID, &item.Title, &content, &item.Visibility,
			&item.PublishedAt, &item.UpdatedAt); err != nil {
			return nil, fmt.Errorf("扫描搜索结果失败: %w", err)
		}
		item.ContentPreview = notes.Preview(content)
		items = append(items, item)
		ids = append(ids, item.ID)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取搜索结果失败: %w", err)
	}

	tags, err := s.tagsFor(ctx, ids)
	if err != nil {
		return nil, err
	}
	for i := range items {
		items[i].Tags = tags[items[i].ID]
	}
	return items, nil
}

// tagsFor 批量取笔记标签。
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
		return nil, fmt.Errorf("查询搜索标签失败: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var noteID string
		var tag TagBrief
		if err := rows.Scan(&noteID, &tag.ID, &tag.Name); err != nil {
			return nil, fmt.Errorf("扫描搜索标签失败: %w", err)
		}
		out[noteID] = append(out[noteID], tag)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取搜索标签失败: %w", err)
	}
	for _, id := range noteIDs {
		if out[id] == nil {
			out[id] = []TagBrief{}
		}
	}
	return out, nil
}

// Handler 承载搜索接口。
type Handler struct {
	svc *Service
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// Private 实现 GET /api/search（api.md 10.1）。q 必填。
func (h *Handler) Private(c *gin.Context) {
	q := strings.TrimSpace(c.Query("q"))
	if q == "" {
		httpx.FailValidation(c, map[string]string{"q": ErrQueryRequired.Error()})
		return
	}

	page, err := httpx.ParsePagination(c)
	if err != nil {
		httpx.FailValidation(c, map[string]string{"limit": err.Error()})
		return
	}

	res, err := h.svc.Private(c.Request.Context(), auth.UserID(c), auth.CurrentVisibility(c), q, page.Limit, page.Offset)
	if err != nil {
		httpx.FailInternal(c, err)
		return
	}
	c.JSON(200, res)
}

// Public 实现 GET /api/public/search（api.md 10.2）。
func (h *Handler) Public(c *gin.Context) {
	q := strings.TrimSpace(c.Query("q"))
	if q == "" {
		httpx.FailValidation(c, map[string]string{"q": ErrQueryRequired.Error()})
		return
	}

	page, err := httpx.ParsePagination(c)
	if err != nil {
		httpx.FailValidation(c, map[string]string{"limit": err.Error()})
		return
	}

	res, err := h.svc.Public(c.Request.Context(), q, page.Limit, page.Offset)
	if err != nil {
		httpx.FailInternal(c, err)
		return
	}
	c.JSON(200, res)
}

// RegisterRoutes 注册搜索路由（api.md 第九节）。
func RegisterRoutes(r gin.IRouter, h *Handler) {
	r.GET("/api/search", auth.RequireLogin(), h.Private)
	r.GET("/api/public/search", h.Public)
}
