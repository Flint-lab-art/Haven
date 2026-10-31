// Package folders 实现文件夹领域（docs/api.md 第六点五节）。
//
// 文件夹通过 parent_id 自引用实现无限嵌套；归属按 user_id 隔离。
// 删除父文件夹时子文件夹由数据库 ON DELETE CASCADE 级联删除，
// 笔记由 notes.folder_id 的 ON DELETE SET NULL 回到收件箱。
package folders

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"unicode/utf8"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"
)

// 领域错误。
var (
	// ErrNotFound 文件夹不存在或不属于当前用户（404）。
	ErrNotFound = errors.New("文件夹不存在")
	// ErrNameRequired 文件夹名为空（422）。
	ErrNameRequired = errors.New("文件夹名不能为空")
	// ErrNameTooLong 文件夹名超过长度上限（422）。
	ErrNameTooLong = errors.New("文件夹名最多 32 个字符")
	// ErrDuplicate 同一个父目录下已有同名文件夹（409）。
	ErrDuplicate = errors.New("同一目录下已有同名文件夹")
	// ErrInvalidParent 父文件夹不存在或不属于当前用户（422）。
	ErrInvalidParent = errors.New("父文件夹不存在")
	// ErrCycle 移动会造成循环引用（422）。
	ErrCycle = errors.New("不能移动到自身或子文件夹下")
	// ErrIconTooLong 图标超过长度上限（422）。
	ErrIconTooLong = errors.New("图标最多 16 个字符")
	// ErrIconInvalid 图标包含换行等非法内容（422）。
	ErrIconInvalid = errors.New("图标只能是单行文本")
	// ErrInboxDelete 收件箱不能删除（409）。
	ErrInboxDelete = errors.New("收件箱不能删除")
	// ErrInboxMove 收件箱不能移动（422）。
	ErrInboxMove = errors.New("收件箱不能移动")
)

// MaxNameRunes 是文件夹名的最大 rune 数（api.md 7.2 / data-model.md 第九节规则 3）。
const MaxNameRunes = 32

// MaxIconRunes 是文件夹图标的最大 rune 数。
//
// 取值 256：既容纳家庭、旗帜等多码点 Emoji，也容纳上传图片的相对路径
// （如 /uploads/2026/11/<32位十六进制>.png，约 32 字符）。
// 以 / 开头的值按图片路径渲染，其余按 Emoji 渲染（docs/v4/frontend/frontend.md 3.3）。
const MaxIconRunes = 256

// Folder 是文件夹响应（api.md 6.5.1）。
type Folder struct {
	ID        string  `json:"id"`
	ParentID  *string `json:"parent_id"`
	Name      string  `json:"name"`
	Icon      *string `json:"icon"`
	IsInbox   bool    `json:"is_inbox"`
	SortOrder int     `json:"sort_order"`
}

// CreateInput 是 POST /api/folders 的入参。
type CreateInput struct {
	Name     string
	ParentID *string
	Icon     *string
}

// UpdateInput 是 PATCH /api/folders/:id 的入参。
//
// ParentIDSet 用于区分「未出现」与「显式置为 null」：null 表示移动到根目录。
type UpdateInput struct {
	Name        *string
	ParentID    *string
	ParentIDSet bool
	SortOrder   *int
	Icon        *string
	IconSet     bool
}

// Service 承载文件夹领域逻辑。
type Service struct {
	db *sql.DB
}

// NewService 构造 Service。
func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// List 返回当前用户的全部文件夹（平铺，由前端组合成树）。
func (s *Service) List(ctx context.Context, userID string) ([]Folder, error) {
	const q = `
		SELECT id, parent_id, name, icon, is_inbox, sort_order
		FROM folders
		WHERE user_id = $1
		ORDER BY is_inbox DESC, sort_order, name, created_at`

	rows, err := s.db.QueryContext(ctx, q, userID)
	if err != nil {
		return nil, fmt.Errorf("查询文件夹失败: %w", err)
	}
	defer rows.Close()

	out := make([]Folder, 0, 8)
	for rows.Next() {
		var f Folder
		if err := rows.Scan(&f.ID, &f.ParentID, &f.Name, &f.Icon, &f.IsInbox, &f.SortOrder); err != nil {
			return nil, fmt.Errorf("扫描文件夹失败: %w", err)
		}
		out = append(out, f)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取文件夹失败: %w", err)
	}
	return out, nil
}

// Create 新建文件夹（api.md 7.2）。
func (s *Service) Create(ctx context.Context, userID string, in CreateInput) (Folder, error) {
	name := strings.TrimSpace(in.Name)
	if name == "" {
		return Folder{}, ErrNameRequired
	}
	if utf8.RuneCountInString(name) > MaxNameRunes {
		return Folder{}, ErrNameTooLong
	}
	icon, err := normalizeIcon(in.Icon)
	if err != nil {
		return Folder{}, err
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return Folder{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	if in.ParentID != nil {
		ok, err := parentExists(ctx, tx, userID, *in.ParentID)
		if err != nil {
			return Folder{}, err
		}
		if !ok {
			return Folder{}, ErrInvalidParent
		}
	}

	dup, err := nameExists(ctx, tx, userID, "", in.ParentID, name)
	if err != nil {
		return Folder{}, err
	}
	if dup {
		return Folder{}, ErrDuplicate
	}

	const q = `
		INSERT INTO folders (user_id, parent_id, name, icon)
		VALUES ($1, $2, $3, $4)
		RETURNING id, parent_id, name, icon, is_inbox, sort_order`

	var f Folder
	if err := tx.QueryRowContext(ctx, q, userID, parentValue(in.ParentID), name, iconValue(icon)).
		Scan(&f.ID, &f.ParentID, &f.Name, &f.Icon, &f.IsInbox, &f.SortOrder); err != nil {
		return Folder{}, fmt.Errorf("创建文件夹失败: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return Folder{}, fmt.Errorf("提交事务失败: %w", err)
	}
	return f, nil
}

// Update 改名 / 移动 / 调整排序（api.md 6.5.3）。
func (s *Service) Update(ctx context.Context, userID, id string, in UpdateInput) (Folder, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return Folder{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	var current Folder
	const getQ = `SELECT id, parent_id, name, icon, is_inbox, sort_order FROM folders WHERE id = $1 AND user_id = $2`
	err = tx.QueryRowContext(ctx, getQ, id, userID).
		Scan(&current.ID, &current.ParentID, &current.Name, &current.Icon, &current.IsInbox, &current.SortOrder)
	if errors.Is(err, sql.ErrNoRows) {
		return Folder{}, ErrNotFound
	}
	if err != nil {
		return Folder{}, fmt.Errorf("查询文件夹失败: %w", err)
	}

	name := current.Name
	if in.Name != nil {
		name = strings.TrimSpace(*in.Name)
		if name == "" {
			return Folder{}, ErrNameRequired
		}
		if utf8.RuneCountInString(name) > MaxNameRunes {
			return Folder{}, ErrNameTooLong
		}
	}

	parent := current.ParentID
	if current.IsInbox && in.ParentIDSet && in.ParentID != nil {
		return Folder{}, ErrInboxMove
	}
	if in.ParentIDSet {
		if in.ParentID != nil {
			ok, err := parentExists(ctx, tx, userID, *in.ParentID)
			if err != nil {
				return Folder{}, err
			}
			if !ok {
				return Folder{}, ErrInvalidParent
			}

			// 不能移动到自身或自己的子文件夹下
			cycle, err := isSelfOrDescendant(ctx, tx, userID, id, *in.ParentID)
			if err != nil {
				return Folder{}, err
			}
			if cycle {
				return Folder{}, ErrCycle
			}
		}
		parent = in.ParentID
	}

	dup, err := nameExists(ctx, tx, userID, id, parent, name)
	if err != nil {
		return Folder{}, err
	}
	if dup {
		return Folder{}, ErrDuplicate
	}

	sortOrder := current.SortOrder
	if in.SortOrder != nil && !current.IsInbox {
		sortOrder = *in.SortOrder
	}

	icon := current.Icon
	if in.IconSet {
		icon, err = normalizeIcon(in.Icon)
		if err != nil {
			return Folder{}, err
		}
	}

	const q = `
		UPDATE folders
		SET name = $3, parent_id = $4, sort_order = $5, icon = $6, updated_at = now()
		WHERE id = $1 AND user_id = $2`

	if _, err := tx.ExecContext(ctx, q, id, userID, name, parentValue(parent), sortOrder, iconValue(icon)); err != nil {
		return Folder{}, fmt.Errorf("更新文件夹失败: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return Folder{}, fmt.Errorf("提交事务失败: %w", err)
	}
	return Folder{
		ID:        id,
		ParentID:  parent,
		Name:      name,
		Icon:      icon,
		IsInbox:   current.IsInbox,
		SortOrder: sortOrder,
	}, nil
}

// Delete 删除普通文件夹（api.md 6.5.4）。
//
// 收件箱不可删除；删除普通文件夹前，先把其子树内所有笔记移到收件箱。
// 若用户没有收件箱（历史数据兜底），笔记回落到 folder_id = NULL。
func (s *Service) Delete(ctx context.Context, userID, id string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	var isInbox bool
	err = tx.QueryRowContext(ctx,
		`SELECT is_inbox FROM folders WHERE id = $1 AND user_id = $2`, id, userID).Scan(&isInbox)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrNotFound
	}
	if err != nil {
		return fmt.Errorf("查询文件夹失败: %w", err)
	}
	if isInbox {
		return ErrInboxDelete
	}

	// 找收件箱；没有则回落到 NULL（历史兜底）。
	var inboxID *string
	err = tx.QueryRowContext(ctx,
		`SELECT id FROM folders WHERE user_id = $1 AND is_inbox`, userID).Scan(&inboxID)
	if errors.Is(err, sql.ErrNoRows) {
		inboxID = nil
	} else if err != nil {
		return fmt.Errorf("查询收件箱失败: %w", err)
	}

	if _, err := tx.ExecContext(ctx, `
		WITH RECURSIVE subtree AS (
			SELECT id FROM folders WHERE id = $1 AND user_id = $2
			UNION ALL
			SELECT f.id FROM folders f JOIN subtree s ON f.parent_id = s.id
		)
		UPDATE notes
		SET folder_id = $3
		WHERE user_id = $2
		  AND folder_id IN (SELECT id FROM subtree)
		  -- 回收站里的笔记保持原 folder_id，还原时才能回到原位（docs/v2/backend/data-model.md 第一节规则 2）
		  AND deleted_at IS NULL`,
		id, userID, parentValue(inboxID)); err != nil {
		return fmt.Errorf("迁移文件夹内笔记失败: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		`DELETE FROM folders WHERE id = $1 AND user_id = $2`, id, userID); err != nil {
		return fmt.Errorf("删除文件夹失败: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("提交事务失败: %w", err)
	}
	return nil
}

// parentExists 校验父文件夹属于当前用户。
func parentExists(ctx context.Context, tx *sql.Tx, userID, parentID string) (bool, error) {
	var exists bool
	if err := tx.QueryRowContext(ctx,
		`SELECT EXISTS (SELECT 1 FROM folders WHERE id = $1 AND user_id = $2)`,
		parentID, userID).Scan(&exists); err != nil {
		return false, fmt.Errorf("查询父文件夹失败: %w", err)
	}
	return exists, nil
}

// nameExists 检查同一父目录下是否已有同名文件夹；excludeID 用于更新时排除自身。
func nameExists(ctx context.Context, tx *sql.Tx, userID, excludeID string, parentID *string, name string) (bool, error) {
	const q = `
		SELECT EXISTS (
			SELECT 1 FROM folders
			WHERE user_id = $1
			  AND ($2::uuid IS NULL OR id <> $2)
			  AND parent_id IS NOT DISTINCT FROM $3
			  AND name = $4
		)`

	var exclude any
	if excludeID != "" {
		exclude = excludeID
	}

	var exists bool
	if err := tx.QueryRowContext(ctx, q, userID, exclude, parentValue(parentID), name).Scan(&exists); err != nil {
		return false, fmt.Errorf("检查文件夹重名失败: %w", err)
	}
	return exists, nil
}

// isSelfOrDescendant 判断 candidate 是否位于 root 的子树中（含自身）。
func isSelfOrDescendant(ctx context.Context, tx *sql.Tx, userID, rootID, candidateID string) (bool, error) {
	const q = `
		WITH RECURSIVE subtree AS (
			SELECT id FROM folders WHERE id = $1 AND user_id = $2
			UNION ALL
			SELECT f.id FROM folders f JOIN subtree s ON f.parent_id = s.id
		)
		SELECT EXISTS (SELECT 1 FROM subtree WHERE id = $3)`

	var exists bool
	if err := tx.QueryRowContext(ctx, q, rootID, userID, candidateID).Scan(&exists); err != nil {
		return false, fmt.Errorf("检查文件夹层级失败: %w", err)
	}
	return exists, nil
}

// parentValue 把可选父目录转成驱动可接受的值（nil → SQL NULL）。
func parentValue(parentID *string) any {
	if parentID == nil {
		return nil
	}
	return *parentID
}

// normalizeIcon 把图标整理成 NULL 或去空白后的单行字符串。
func normalizeIcon(icon *string) (*string, error) {
	if icon == nil {
		return nil, nil
	}
	value := strings.TrimSpace(*icon)
	if value == "" {
		return nil, nil
	}
	if strings.ContainsAny(value, "\r\n") {
		return nil, ErrIconInvalid
	}
	if utf8.RuneCountInString(value) > MaxIconRunes {
		return nil, ErrIconTooLong
	}
	return &value, nil
}

func iconValue(icon *string) any {
	if icon == nil {
		return nil
	}
	return *icon
}

// Handler 承载文件夹接口。
type Handler struct {
	svc *Service
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

type createRequest struct {
	Name     string  `json:"name"`
	ParentID *string `json:"parent_id"`
	Icon     *string `json:"icon"`
}

type updateRequest struct {
	Name      *string         `json:"name"`
	ParentID  json.RawMessage `json:"parent_id"`
	Icon      json.RawMessage `json:"icon"`
	SortOrder *int            `json:"sort_order"`
}

func fail(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		httpx.FailNotFound(c)
	case errors.Is(err, ErrDuplicate):
		httpx.FailConflict(c, ErrDuplicate.Error())
	case errors.Is(err, ErrInboxDelete):
		httpx.FailConflict(c, ErrInboxDelete.Error())
	case errors.Is(err, ErrNameRequired):
		httpx.FailValidation(c, map[string]string{"name": ErrNameRequired.Error()})
	case errors.Is(err, ErrNameTooLong):
		httpx.FailValidation(c, map[string]string{"name": ErrNameTooLong.Error()})
	case errors.Is(err, ErrInvalidParent):
		httpx.FailValidation(c, map[string]string{"parent_id": ErrInvalidParent.Error()})
	case errors.Is(err, ErrCycle):
		httpx.FailValidation(c, map[string]string{"parent_id": ErrCycle.Error()})
	case errors.Is(err, ErrInboxMove):
		httpx.FailValidation(c, map[string]string{"parent_id": ErrInboxMove.Error()})
	case errors.Is(err, ErrIconTooLong), errors.Is(err, ErrIconInvalid):
		httpx.FailValidation(c, map[string]string{"icon": err.Error()})
	default:
		httpx.FailInternal(c, err)
	}
}

// List 实现 GET /api/folders。
func (h *Handler) List(c *gin.Context) {
	items, err := h.svc.List(c.Request.Context(), auth.UserID(c))
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, httpx.NewList(items, len(items)))
}

// Create 实现 POST /api/folders。
func (h *Handler) Create(c *gin.Context) {
	var req createRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}
	if req.ParentID != nil && !httpx.IsUUID(*req.ParentID) {
		httpx.FailValidation(c, map[string]string{"parent_id": "父文件夹 id 无效"})
		return
	}

	folder, err := h.svc.Create(c.Request.Context(), auth.UserID(c), CreateInput{
		Name:     req.Name,
		ParentID: req.ParentID,
		Icon:     req.Icon,
	})
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(201, folder)
}

// Update 实现 PATCH /api/folders/:id。
func (h *Handler) Update(c *gin.Context) {
	var req updateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}

	in := UpdateInput{Name: req.Name, SortOrder: req.SortOrder}
	if req.ParentID != nil {
		in.ParentIDSet = true
		if string(req.ParentID) != "null" {
			var parentID string
			if err := json.Unmarshal(req.ParentID, &parentID); err != nil || !httpx.IsUUID(parentID) {
				httpx.FailValidation(c, map[string]string{"parent_id": "父文件夹 id 无效"})
				return
			}
			in.ParentID = &parentID
		}
	}
	if req.Icon != nil {
		in.IconSet = true
		if string(req.Icon) != "null" {
			var icon string
			if err := json.Unmarshal(req.Icon, &icon); err != nil {
				httpx.FailValidation(c, map[string]string{"icon": "图标必须是字符串"})
				return
			}
			in.Icon = &icon
		}
	}

	folder, err := h.svc.Update(c.Request.Context(), auth.UserID(c), c.Param("id"), in)
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, folder)
}

// Delete 实现 DELETE /api/folders/:id。
func (h *Handler) Delete(c *gin.Context) {
	if err := h.svc.Delete(c.Request.Context(), auth.UserID(c), c.Param("id")); err != nil {
		fail(c, err)
		return
	}
	c.Status(204)
}

// RegisterRoutes 注册文件夹路由（api.md 第六点五节）。
func RegisterRoutes(r gin.IRouter, h *Handler) {
	read := r.Group("/api/folders", auth.RequireLogin())
	read.GET("", h.List)

	write := r.Group("/api/folders", auth.RequireWrite())
	write.POST("", h.Create)
	write.PATCH("/:id", h.Update)
	write.DELETE("/:id", h.Delete)
}
