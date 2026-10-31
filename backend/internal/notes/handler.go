package notes

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"
)

// 笔记相关的 HTTP handler，对照 docs/api.md 第六、七节。
//
// 约定：*gin.Context 只在本层；业务逻辑在 Service。错误统一交给 httpx。

// Handler 承载笔记接口。
type Handler struct {
	svc *Service
	// usernameByID 用于审计的 actor_username 快照（audit.md 2 规则 3）。
	// 由 router 注入；为 nil 时快照留空。
	usernameByID func(ctx context.Context, id string) (string, error)
	// OnNotePublished / OnNoteUnpublished 用于写审计事件（audit.md 第三节）。
	// 钩子内部不返回错误：审计失败不影响业务。
	OnNotePublished   func(c *gin.Context, ac AuditContext, noteID, title string)
	OnNoteUnpublished func(c *gin.Context, ac AuditContext, noteID, title string)
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// SetUsernameLookup 注入用户名查询函数，供审计快照使用。
func (h *Handler) SetUsernameLookup(fn func(ctx context.Context, id string) (string, error)) {
	h.usernameByID = fn
}

// AuditContext 是写笔记审计所需的信息。
type AuditContext struct {
	UserID   string
	Username string
	IP       string
	UA       string
}

// auditContext 组装审计上下文；用户名只是快照，取不到时留空。
func (h *Handler) auditContext(c *gin.Context) AuditContext {
	id := auth.CurrentIdentity(c)
	ac := AuditContext{
		UserID: id.UserID,
		IP:     c.ClientIP(),
		UA:     c.Request.UserAgent(),
	}
	if ac.UserID != "" && h.usernameByID != nil {
		if name, err := h.usernameByID(c.Request.Context(), ac.UserID); err == nil {
			ac.Username = name
		}
	}
	return ac
}

// 请求体。

type createRequest struct {
	Title    string   `json:"title"`
	Content  string   `json:"content"`
	TagIDs   []string `json:"tag_ids"`
	FolderID *string  `json:"folder_id"`
}

type updateRequest struct {
	Title     *string         `json:"title"`
	Content   *string         `json:"content"`
	TagIDs    *[]string       `json:"tag_ids"`
	FolderID  json.RawMessage `json:"folder_id"`
	SortOrder *int            `json:"sort_order"`
}

// fail 把领域错误映射成 api.md 1.4 的响应。
func fail(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		httpx.FailNotFound(c)
	case errors.Is(err, ErrAlreadyPublic), errors.Is(err, ErrAlreadyPrivate):
		httpx.FailConflict(c, err.Error())
	case errors.Is(err, ErrTitleRequired):
		httpx.FailValidation(c, map[string]string{"title": ErrTitleRequired.Error()})
	case errors.Is(err, ErrInvalidTag):
		httpx.FailValidation(c, map[string]string{"tag_ids": ErrInvalidTag.Error()})
	case errors.Is(err, ErrInvalidFolder):
		httpx.FailValidation(c, map[string]string{"folder_id": ErrInvalidFolder.Error()})
	case errors.Is(err, ErrInvalidSortOrder):
		httpx.FailValidation(c, map[string]string{"sort_order": ErrInvalidSortOrder.Error()})
	default:
		httpx.FailInternal(c, err)
	}
}

// List 实现 GET /api/notes（api.md 6.1）。
func (h *Handler) List(c *gin.Context) {
	page, err := httpx.ParsePagination(c)
	if err != nil {
		httpx.FailValidation(c, map[string]string{"limit": err.Error()})
		return
	}

	filter := ListFilter{
		Visibility: c.Query("visibility"),
		TagID:      c.Query("tag_id"),
	}
	if filter.Visibility != "" && filter.Visibility != "private" && filter.Visibility != "public" {
		httpx.FailValidation(c, map[string]string{"visibility": "只能是 private 或 public"})
		return
	}
	if raw, ok := c.GetQuery("folder_id"); ok {
		filter.FolderFilter = true
		if raw == "" {
			// 空字符串是收件箱别名；没有收件箱的历史数据继续按 NULL 处理。
			inboxID, err := h.svc.InboxID(c.Request.Context(), auth.UserID(c))
			if err != nil {
				fail(c, err)
				return
			}
			if inboxID != nil {
				filter.FolderID = *inboxID
			}
		} else {
			if !httpx.IsUUID(raw) {
				httpx.FailValidation(c, map[string]string{"folder_id": "文件夹 id 无效"})
				return
			}
			filter.FolderID = raw
		}
	}

	items, total, err := h.svc.ListPrivate(c.Request.Context(), auth.UserID(c), auth.CurrentVisibility(c),
		filter, page.Limit, page.Offset)
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(http.StatusOK, httpx.NewList(items, total))
}

// Get 实现 GET /api/notes/:id（api.md 6.2）。
func (h *Handler) Get(c *gin.Context) {
	note, err := h.svc.Get(c.Request.Context(), auth.UserID(c), c.Param("id"))
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(http.StatusOK, note)
}

// Create 实现 POST /api/notes（api.md 6.3）。
//
// 请求体里即使出现 visibility 也被忽略：Structure 不含该字段，Gin 直接丢弃。
func (h *Handler) Create(c *gin.Context) {
	var req createRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}
	if req.FolderID != nil && !httpx.IsUUID(*req.FolderID) {
		httpx.FailValidation(c, map[string]string{"folder_id": "文件夹 id 无效"})
		return
	}

	note, err := h.svc.Create(c.Request.Context(), auth.UserID(c), CreateInput{
		Title:    req.Title,
		Content:  req.Content,
		TagIDs:   req.TagIDs,
		FolderID: req.FolderID,
	})
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(http.StatusCreated, note)
}

// Update 实现 PATCH /api/notes/:id（api.md 6.4）。
func (h *Handler) Update(c *gin.Context) {
	var req updateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}

	in := UpdateInput{Title: req.Title, Content: req.Content, SortOrder: req.SortOrder}
	if req.TagIDs != nil {
		// 显式出现即全量替换；空数组表示清空（api.md 6.4）
		in.TagIDs = *req.TagIDs
		if in.TagIDs == nil {
			in.TagIDs = []string{}
		}
	}
	if req.FolderID != nil {
		// 显式出现才更新；null 表示移回收件箱
		in.FolderIDSet = true
		if string(req.FolderID) != "null" {
			var folderID string
			if err := json.Unmarshal(req.FolderID, &folderID); err != nil || !httpx.IsUUID(folderID) {
				httpx.FailValidation(c, map[string]string{"folder_id": "文件夹 id 无效"})
				return
			}
			in.FolderID = &folderID
		}
	}

	note, err := h.svc.Update(c.Request.Context(), auth.UserID(c), c.Param("id"), in)
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(http.StatusOK, note)
}

// Delete 实现 DELETE /api/notes/:id（api.md 6.5）。
func (h *Handler) Delete(c *gin.Context) {
	if err := h.svc.Delete(c.Request.Context(), auth.UserID(c), c.Param("id")); err != nil {
		fail(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// Publish 实现 POST /api/notes/:id/publish（api.md 6.6）。
func (h *Handler) Publish(c *gin.Context) {
	note, err := h.svc.Publish(c.Request.Context(), auth.UserID(c), c.Param("id"))
	if err != nil {
		fail(c, err)
		return
	}
	if h.OnNotePublished != nil {
		h.OnNotePublished(c, h.auditContext(c), note.ID, note.Title)
	}
	c.JSON(http.StatusOK, note)
}

// Unpublish 实现 POST /api/notes/:id/unpublish（api.md 6.7）。
func (h *Handler) Unpublish(c *gin.Context) {
	note, err := h.svc.Unpublish(c.Request.Context(), auth.UserID(c), c.Param("id"))
	if err != nil {
		fail(c, err)
		return
	}
	if h.OnNoteUnpublished != nil {
		h.OnNoteUnpublished(c, h.auditContext(c), note.ID, note.Title)
	}
	c.JSON(http.StatusOK, note)
}

// ListPublic 实现 GET /api/public/notes（api.md 7.1）。
func (h *Handler) ListPublic(c *gin.Context) {
	page, err := httpx.ParsePagination(c)
	if err != nil {
		httpx.FailValidation(c, map[string]string{"limit": err.Error()})
		return
	}

	items, total, err := h.svc.ListPublic(c.Request.Context(), page.Limit, page.Offset)
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(http.StatusOK, httpx.NewList(items, total))
}

// GetPublic 实现 GET /api/public/notes/:id（api.md 7.2）。
func (h *Handler) GetPublic(c *gin.Context) {
	note, err := h.svc.GetPublic(c.Request.Context(), c.Param("id"))
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(http.StatusOK, note)
}

// RegisterRoutes 注册笔记路由。
//
// 鉴权档位对照 api.md 第六节：
//   - 读：登录；
//   - 写 / publish / unpublish：登录 + write；
//   - 公开侧：匿名。
func RegisterRoutes(r gin.IRouter, h *Handler) {
	read := r.Group("/api/notes", auth.RequireLogin())
	read.GET("", h.List)
	read.GET("/:id", h.Get)

	write := r.Group("/api/notes", auth.RequireWrite())
	write.POST("", h.Create)
	write.PATCH("/:id", h.Update)
	write.DELETE("/:id", h.Delete)
	write.POST("/:id/publish", h.Publish)
	write.POST("/:id/unpublish", h.Unpublish)

	r.GET("/api/public/notes", h.ListPublic)
	r.GET("/api/public/notes/:id", h.GetPublic)
}
