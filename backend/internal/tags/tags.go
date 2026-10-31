// Package tags 实现标签领域（docs/api.md 第八节）。
//
// 标签按用户隔离，名称不区分大小写唯一（data-model.md 第四节）。
// 本期只支持创建与删除，不提供重命名。
package tags

import (
	"context"
	"database/sql"
	"errors"
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
	// ErrNotFound 标签不存在或不属于当前用户（404）。
	ErrNotFound = errors.New("标签不存在")
	// ErrDuplicate 同一用户下已有同名标签（409）。
	ErrDuplicate = errors.New("标签名已存在")
	// ErrNameRequired 标签名为空（422）。
	ErrNameRequired = errors.New("标签名不能为空")
	// ErrNameTooLong 标签名过长（422）。
	ErrNameTooLong = errors.New("标签名过长")
)

// MaxNameRunes 是标签名长度上限。
//
// api.md 8.2 要求「name 为空或过长」返回 422，但未给出具体长度；
// 这里取 64 个字符作为实现决策，改需求请先改文档。
const MaxNameRunes = 64

// Tag 是标签响应（api.md 8.1）。
type Tag struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	NoteCount int       `json:"note_count"`
	CreatedAt time.Time `json:"created_at"`
}

// Service 承载标签领域逻辑。
type Service struct {
	db *sql.DB
}

// NewService 构造 Service。
func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// List 返回当前用户的全部标签，带关联笔记数（api.md 8.1）。
//
// note_count 含私有笔记：查询本身就限定在 user_id 内（data-model.md 第四节规则 4）。
func (s *Service) List(ctx context.Context, userID string) ([]Tag, error) {
	const q = `
		SELECT t.id, t.name, t.created_at, count(nt.note_id)
		FROM tags t
		LEFT JOIN note_tags nt ON nt.tag_id = t.id
		WHERE t.user_id = $1
		GROUP BY t.id, t.name, t.created_at
		ORDER BY t.name`

	rows, err := s.db.QueryContext(ctx, q, userID)
	if err != nil {
		return nil, fmt.Errorf("查询标签失败: %w", err)
	}
	defer rows.Close()

	out := make([]Tag, 0, 8)
	for rows.Next() {
		var t Tag
		if err := rows.Scan(&t.ID, &t.Name, &t.CreatedAt, &t.NoteCount); err != nil {
			return nil, fmt.Errorf("扫描标签失败: %w", err)
		}
		out = append(out, t)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取标签失败: %w", err)
	}
	return out, nil
}

// Create 新建标签（api.md 8.2）。重名（lower(name)）返回 ErrDuplicate。
func (s *Service) Create(ctx context.Context, userID, name string) (Tag, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		return Tag{}, ErrNameRequired
	}
	if len([]rune(name)) > MaxNameRunes {
		return Tag{}, ErrNameTooLong
	}

	const q = `
		INSERT INTO tags (user_id, name) VALUES ($1, $2)
		ON CONFLICT DO NOTHING
		RETURNING id, name, created_at`

	var t Tag
	err := s.db.QueryRowContext(ctx, q, userID, name).Scan(&t.ID, &t.Name, &t.CreatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		// ON CONFLICT DO NOTHING 命中唯一索引：同一用户下已有同名标签
		return Tag{}, ErrDuplicate
	}
	if err != nil {
		return Tag{}, fmt.Errorf("创建标签失败: %w", err)
	}
	return t, nil
}

// Delete 删除标签（api.md 8.3）。note_tags 由外键级联清理。
func (s *Service) Delete(ctx context.Context, userID, id string) error {
	res, err := s.db.ExecContext(ctx, `DELETE FROM tags WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		return fmt.Errorf("删除标签失败: %w", err)
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

// NotesByTag 返回某标签下的笔记（api.md 8.4）。
//
// 返回结构与 GET /api/notes 一致（含 content_preview），由 notes 包提供查询，
// 这里的实现直接复用同一段 SQL 语义，避免两处排序/截断规则漂移。
func (s *Service) NotesByTag(ctx context.Context, userID, tagID string, limit, offset int) ([]gin.H, int, error) {
	// 先确认标签归属：不属于当前用户 → 404（api.md 8.4）
	var exists bool
	if err := s.db.QueryRowContext(ctx,
		`SELECT EXISTS (SELECT 1 FROM tags WHERE id = $1 AND user_id = $2)`,
		tagID, userID).Scan(&exists); err != nil {
		return nil, 0, fmt.Errorf("查询标签失败: %w", err)
	}
	if !exists {
		return nil, 0, ErrNotFound
	}

	const countQ = `
		SELECT count(*)
		FROM notes n
		JOIN note_tags nt ON nt.note_id = n.id
		WHERE n.user_id = $1 AND nt.tag_id = $2`

	var total int
	if err := s.db.QueryRowContext(ctx, countQ, userID, tagID).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("统计标签笔记失败: %w", err)
	}

	const q = `
		SELECT n.id, n.folder_id, n.title, n.content, n.visibility, n.published_at, n.created_at, n.updated_at
		FROM notes n
		JOIN note_tags nt ON nt.note_id = n.id
		WHERE n.user_id = $1 AND nt.tag_id = $2
		ORDER BY n.updated_at DESC
		LIMIT $3 OFFSET $4`

	rows, err := s.db.QueryContext(ctx, q, userID, tagID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("查询标签笔记失败: %w", err)
	}
	defer rows.Close()

	items := make([]gin.H, 0, limit)
	ids := make([]string, 0, limit)
	for rows.Next() {
		var id, title, content, visibility string
		var folderID *string
		var publishedAt, createdAt, updatedAt any
		if err := rows.Scan(&id, &folderID, &title, &content, &visibility, &publishedAt, &createdAt, &updatedAt); err != nil {
			return nil, 0, fmt.Errorf("扫描标签笔记失败: %w", err)
		}
		items = append(items, gin.H{
			"id":              id,
			"folder_id":       folderID,
			"title":           title,
			"content_preview": notes.Preview(content),
			"visibility":      visibility,
			"published_at":    publishedAt,
			"created_at":      createdAt,
			"updated_at":      updatedAt,
		})
		ids = append(ids, id)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("读取标签笔记失败: %w", err)
	}

	noteTags, err := notesTagsFor(ctx, s.db, ids)
	if err != nil {
		return nil, 0, err
	}
	for _, item := range items {
		item["tags"] = noteTags[item["id"].(string)]
	}
	return items, total, nil
}

// Handler 承载标签接口。
type Handler struct {
	svc *Service
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func fail(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		httpx.FailNotFound(c)
	case errors.Is(err, ErrDuplicate):
		httpx.FailConflict(c, ErrDuplicate.Error())
	case errors.Is(err, ErrNameRequired):
		httpx.FailValidation(c, map[string]string{"name": ErrNameRequired.Error()})
	case errors.Is(err, ErrNameTooLong):
		httpx.FailValidation(c, map[string]string{"name": ErrNameTooLong.Error()})
	default:
		httpx.FailInternal(c, err)
	}
}

// List 实现 GET /api/tags（api.md 8.1）。
func (h *Handler) List(c *gin.Context) {
	items, err := h.svc.List(c.Request.Context(), auth.UserID(c))
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, httpx.NewList(items, len(items)))
}

type createRequest struct {
	Name string `json:"name"`
}

// Create 实现 POST /api/tags（api.md 8.2）。
func (h *Handler) Create(c *gin.Context) {
	var req createRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}

	tag, err := h.svc.Create(c.Request.Context(), auth.UserID(c), req.Name)
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(201, tag)
}

// Delete 实现 DELETE /api/tags/:id（api.md 8.3）。
func (h *Handler) Delete(c *gin.Context) {
	if err := h.svc.Delete(c.Request.Context(), auth.UserID(c), c.Param("id")); err != nil {
		fail(c, err)
		return
	}
	c.Status(204)
}

// Notes 实现 GET /api/tags/:id/notes（api.md 8.4）。
func (h *Handler) Notes(c *gin.Context) {
	page, err := httpx.ParsePagination(c)
	if err != nil {
		httpx.FailValidation(c, map[string]string{"limit": err.Error()})
		return
	}

	items, total, err := h.svc.NotesByTag(c.Request.Context(), auth.UserID(c), c.Param("id"), page.Limit, page.Offset)
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, httpx.NewList(items, total))
}

// RegisterRoutes 注册标签路由（api.md 第八节）。
func RegisterRoutes(r gin.IRouter, h *Handler) {
	read := r.Group("/api/tags", auth.RequireLogin())
	read.GET("", h.List)
	read.GET("/:id/notes", h.Notes)

	write := r.Group("/api/tags", auth.RequireWrite())
	write.POST("", h.Create)
	write.DELETE("/:id", h.Delete)
}
