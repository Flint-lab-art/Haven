// Package portfolio 实现作品集（docs/api.md 第十节）。
//
// 相关链接直接存完整 URL，不再由后端按 platform 拼接（docs/v3/api.md 第五节）：
//   - 仓库链接按域名在公开页显示 GitHub / Gogs 图标；
//   - 其他链接存一条 title，公开页展示标题而不是 URL。
package portfolio

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"

	"github.com/gin-gonic/gin"
)

// GitHubBaseURL 是固定的 GitHub 站点地址（data-model.md 第七节规则 1）。
const GitHubBaseURL = "https://github.com"

// 领域错误。
var (
	// ErrItemNotFound 作品不存在或不属于当前用户（404）。
	ErrItemNotFound = errors.New("作品不存在")
	// ErrRepoNotFound 仓库不存在（404）。
	ErrRepoNotFound = errors.New("仓库不存在")
	// ErrDuplicateRepo 同一作品下 URL 重复（409）。
	ErrDuplicateRepo = errors.New("该作品下已存在相同链接")
	// ErrPrimaryExists 该作品已有主链接（409）。
	ErrPrimaryExists = errors.New("该作品已有主链接")
	// ErrTitleRequired 标题为空（422）。
	ErrTitleRequired = errors.New("标题不能为空")
	// ErrURLRequired 链接地址为空（422）。
	ErrURLRequired = errors.New("链接地址不能为空")
)

// Repo 是作品关联的仓库（api.md 10.1）。
type Repo struct {
	ID  string `json:"id"`
	URL string `json:"url"`
	// Title 是非仓库链接在公开页展示的文字；仓库链接留空，由前端按域名显示图标。
	Title string `json:"title"`
	// Kind 由 URL 域名推断：github / gogs / link。不落库，每次查询时计算。
	Kind      string `json:"kind"`
	IsPrimary bool   `json:"is_primary"`
}

// Item 是作品条目。
type Item struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	// Content 是作品介绍正文（Markdown 源文本），公开详情页渲染用（docs/v3/api.md 第二节）。
	// 列表接口不返回它，避免公开列表带上大段正文。
	Content   string `json:"content,omitempty"`
	SortOrder int    `json:"sort_order"`
	Repos     []Repo `json:"repos"`
}

// Service 承载作品集逻辑。
type Service struct {
	db          *sql.DB
	gogsBaseURL string
}

// NewService 构造 Service。gogsBaseURL 来自 HAVEN_GOGS_BASE_URL（已去掉末尾斜杠）。
func NewService(db *sql.DB, gogsBaseURL string) *Service {
	return &Service{db: db, gogsBaseURL: strings.TrimSuffix(gogsBaseURL, "/")}
}

// ListPublic 返回作品集（api.md 10.1），按 sort_order 升序。
//
// 主页按站点聚合展示；本期只有一个用户，但仍带上归属过滤。
func (s *Service) ListPublic(ctx context.Context) ([]Item, error) {
	const itemsQ = `
		SELECT id, title, description, sort_order
		FROM portfolio_items
		ORDER BY sort_order, title`

	rows, err := s.db.QueryContext(ctx, itemsQ)
	if err != nil {
		return nil, fmt.Errorf("查询作品集失败: %w", err)
	}
	defer rows.Close()

	items := make([]Item, 0, 8)
	ids := make([]string, 0, 8)
	for rows.Next() {
		var it Item
		if err := rows.Scan(&it.ID, &it.Title, &it.Description, &it.SortOrder); err != nil {
			return nil, fmt.Errorf("扫描作品失败: %w", err)
		}
		it.Repos = []Repo{}
		items = append(items, it)
		ids = append(ids, it.ID)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取作品集失败: %w", err)
	}

	repos, err := s.reposFor(ctx, ids)
	if err != nil {
		return nil, err
	}
	for i := range items {
		items[i].Repos = repos[items[i].ID]
	}
	return items, nil
}

// GetPublic 返回单个作品的公开详情（docs/v3/api.md 2.2），含介绍正文。
//
// 列表接口（ListPublic）不返回正文，只有详情页需要。
func (s *Service) GetPublic(ctx context.Context, id string) (Item, error) {
	const q = `
		SELECT id, title, description, content, sort_order
		FROM portfolio_items
		WHERE id = $1`

	var it Item
	err := s.db.QueryRowContext(ctx, q, id).Scan(
		&it.ID, &it.Title, &it.Description, &it.Content, &it.SortOrder)
	if errors.Is(err, sql.ErrNoRows) {
		return Item{}, ErrItemNotFound
	}
	if err != nil {
		return Item{}, fmt.Errorf("查询作品失败: %w", err)
	}

	repos, err := s.reposFor(ctx, []string{id})
	if err != nil {
		return Item{}, err
	}
	it.Repos = repos[id]
	return it, nil
}

// Get 返回单个作品（含 repos），用于 CRUD 响应。
func (s *Service) Get(ctx context.Context, userID, id string) (Item, error) {
	const q = `
		SELECT id, title, description, content, sort_order
		FROM portfolio_items
		WHERE id = $1 AND user_id = $2`

	var it Item
	err := s.db.QueryRowContext(ctx, q, id, userID).Scan(
		&it.ID, &it.Title, &it.Description, &it.Content, &it.SortOrder)
	if errors.Is(err, sql.ErrNoRows) {
		return Item{}, ErrItemNotFound
	}
	if err != nil {
		return Item{}, fmt.Errorf("查询作品失败: %w", err)
	}

	repos, err := s.reposFor(ctx, []string{id})
	if err != nil {
		return Item{}, err
	}
	it.Repos = repos[id]
	return it, nil
}

// Create 新建作品（api.md 10.2）。
func (s *Service) Create(ctx context.Context, userID, title, description, content string, sortOrder int) (Item, error) {
	title = strings.TrimSpace(title)
	if title == "" {
		return Item{}, ErrTitleRequired
	}

	var id string
	err := s.db.QueryRowContext(ctx,
		`INSERT INTO portfolio_items (user_id, title, description, content, sort_order)
		 VALUES ($1, $2, $3, $4, $5) RETURNING id`,
		userID, title, description, content, sortOrder).Scan(&id)
	if err != nil {
		return Item{}, fmt.Errorf("创建作品失败: %w", err)
	}
	return s.Get(ctx, userID, id)
}

// UpdateInput 是 PATCH /api/portfolio/:id 的部分更新入参。
type UpdateInput struct {
	Title       *string
	Description *string
	Content     *string
	SortOrder   *int
}

// Update 局部更新作品（api.md 10.3）。
func (s *Service) Update(ctx context.Context, userID, id string, in UpdateInput) (Item, error) {
	// 先确认归属
	if _, err := s.Get(ctx, userID, id); err != nil {
		return Item{}, err
	}

	if in.Title != nil {
		title := strings.TrimSpace(*in.Title)
		if title == "" {
			return Item{}, ErrTitleRequired
		}
		if _, err := s.db.ExecContext(ctx, `UPDATE portfolio_items SET title = $2 WHERE id = $1`, id, title); err != nil {
			return Item{}, fmt.Errorf("更新作品标题失败: %w", err)
		}
	}
	if in.Description != nil {
		if _, err := s.db.ExecContext(ctx, `UPDATE portfolio_items SET description = $2 WHERE id = $1`, id, *in.Description); err != nil {
			return Item{}, fmt.Errorf("更新作品简介失败: %w", err)
		}
	}
	if in.Content != nil {
		if _, err := s.db.ExecContext(ctx, `UPDATE portfolio_items SET content = $2 WHERE id = $1`, id, *in.Content); err != nil {
			return Item{}, fmt.Errorf("更新作品正文失败: %w", err)
		}
	}
	if in.SortOrder != nil {
		if _, err := s.db.ExecContext(ctx, `UPDATE portfolio_items SET sort_order = $2 WHERE id = $1`, id, *in.SortOrder); err != nil {
			return Item{}, fmt.Errorf("更新作品排序失败: %w", err)
		}
	}

	return s.Get(ctx, userID, id)
}

// Delete 删除作品（api.md 10.4），关联仓库由外键级联清理。
func (s *Service) Delete(ctx context.Context, userID, id string) error {
	res, err := s.db.ExecContext(ctx,
		`DELETE FROM portfolio_items WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		return fmt.Errorf("删除作品失败: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("读取删除结果失败: %w", err)
	}
	if n == 0 {
		return ErrItemNotFound
	}
	return nil
}

// RepoInput 是新增链接的入参（docs/v3/api.md 5.1）。
type RepoInput struct {
	URL   string
	Title string
	// IsPrimary 仅对仓库链接有意义；非仓库链接一律 false。
	IsPrimary bool
}

// AddRepo 给作品加一条相关链接（docs/v3/api.md 5.1）。
//
// URL 只接受 http/https 的完整地址；title 留空时后端尽力抓一次页面标题。
func (s *Service) AddRepo(ctx context.Context, userID, itemID string, in RepoInput) (Repo, error) {
	if _, err := s.Get(ctx, userID, itemID); err != nil {
		return Repo{}, err
	}

	link, err := ValidateURL(in.URL)
	if err != nil {
		return Repo{}, err
	}

	title := strings.TrimSpace(in.Title)
	kind := s.RepoKind(link)
	// 仓库链接不需要标题（公开页显示图标）；其他链接在标题为空时抓一次
	if title == "" && kind == "link" {
		title = FetchTitle(ctx, link)
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return Repo{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	var locked string
	if err := tx.QueryRowContext(ctx,
		`SELECT id FROM portfolio_items WHERE id = $1 AND user_id = $2 FOR UPDATE`,
		itemID, userID).Scan(&locked); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Repo{}, ErrItemNotFound
		}
		return Repo{}, fmt.Errorf("锁定作品失败: %w", err)
	}

	if in.IsPrimary {
		var exists bool
		if err := tx.QueryRowContext(ctx,
			`SELECT EXISTS (SELECT 1 FROM portfolio_repos WHERE portfolio_item_id = $1 AND is_primary)`,
			itemID).Scan(&exists); err != nil {
			return Repo{}, fmt.Errorf("查询主链接失败: %w", err)
		}
		if exists {
			return Repo{}, ErrPrimaryExists
		}
	}

	const q = `
		INSERT INTO portfolio_repos (portfolio_item_id, url, title, is_primary)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT DO NOTHING
		RETURNING id`

	var id string
	err = tx.QueryRowContext(ctx, q, itemID, link, title, in.IsPrimary).Scan(&id)
	if errors.Is(err, sql.ErrNoRows) {
		return Repo{}, ErrDuplicateRepo
	}
	if err != nil {
		if isUniqueViolation(err) {
			return Repo{}, ErrPrimaryExists
		}
		return Repo{}, fmt.Errorf("添加链接失败: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return Repo{}, fmt.Errorf("提交事务失败: %w", err)
	}

	return Repo{
		ID:        id,
		URL:       link,
		Title:     title,
		Kind:      kind,
		IsPrimary: in.IsPrimary,
	}, nil
}

// isUniqueViolation 判断错误是否为 PostgreSQL 唯一约束冲突（SQLSTATE 23505）。
// 不引入 pgconn 依赖，直接比对驱动错误文本里的状态码。
func isUniqueViolation(err error) bool {
	if err == nil {
		return false
	}
	return strings.Contains(err.Error(), "23505")
}

// UpdateRepoInput 是 PATCH 链接的入参；指针区分「未出现」。
type UpdateRepoInput struct {
	URL       *string
	Title     *string
	IsPrimary *bool
}

// UpdateRepo 修改链接（docs/v3/api.md 5.2）。
func (s *Service) UpdateRepo(ctx context.Context, userID, itemID, repoID string, in UpdateRepoInput) (Repo, error) {
	var repo Repo
	err := s.db.QueryRowContext(ctx,
		`SELECT id, url, title, is_primary FROM portfolio_repos
		 WHERE id = $1 AND portfolio_item_id = $2`, repoID, itemID).
		Scan(&repo.ID, &repo.URL, &repo.Title, &repo.IsPrimary)
	if errors.Is(err, sql.ErrNoRows) {
		return Repo{}, ErrRepoNotFound
	}
	if err != nil {
		return Repo{}, fmt.Errorf("查询链接失败: %w", err)
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return Repo{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	var locked string
	if err := tx.QueryRowContext(ctx,
		`SELECT id FROM portfolio_items WHERE id = $1 AND user_id = $2 FOR UPDATE`,
		itemID, userID).Scan(&locked); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Repo{}, ErrItemNotFound
		}
		return Repo{}, fmt.Errorf("锁定作品失败: %w", err)
	}

	if in.URL != nil {
		link, err := ValidateURL(*in.URL)
		if err != nil {
			return Repo{}, err
		}
		if _, err := tx.ExecContext(ctx,
			`UPDATE portfolio_repos SET url = $2 WHERE id = $1`, repoID, link); err != nil {
			if isUniqueViolation(err) {
				return Repo{}, ErrDuplicateRepo
			}
			return Repo{}, fmt.Errorf("更新链接地址失败: %w", err)
		}
		repo.URL = link
	}

	if in.Title != nil {
		title := strings.TrimSpace(*in.Title)
		// 非仓库链接允许留空（公开页会退回显示 URL）；仓库链接忽略标题
		if _, err := tx.ExecContext(ctx,
			`UPDATE portfolio_repos SET title = $2 WHERE id = $1`, repoID, title); err != nil {
			return Repo{}, fmt.Errorf("更新链接标题失败: %w", err)
		}
		repo.Title = title
	}

	if in.IsPrimary != nil && *in.IsPrimary {
		var exists bool
		if err := tx.QueryRowContext(ctx,
			`SELECT EXISTS (SELECT 1 FROM portfolio_repos
			 WHERE portfolio_item_id = $1 AND is_primary AND id <> $2)`,
			itemID, repoID).Scan(&exists); err != nil {
			return Repo{}, fmt.Errorf("查询主链接失败: %w", err)
		}
		if exists {
			return Repo{}, ErrPrimaryExists
		}
		if _, err := tx.ExecContext(ctx,
			`UPDATE portfolio_repos SET is_primary = true WHERE id = $1`, repoID); err != nil {
			if isUniqueViolation(err) {
				return Repo{}, ErrPrimaryExists
			}
			return Repo{}, fmt.Errorf("更新主链接失败: %w", err)
		}
		repo.IsPrimary = true
	} else if in.IsPrimary != nil {
		if _, err := tx.ExecContext(ctx,
			`UPDATE portfolio_repos SET is_primary = false WHERE id = $1`, repoID); err != nil {
			return Repo{}, fmt.Errorf("更新主链接失败: %w", err)
		}
		repo.IsPrimary = false
	}

	if err := tx.Commit(); err != nil {
		return Repo{}, fmt.Errorf("提交事务失败: %w", err)
	}

	repo.Kind = s.RepoKind(repo.URL)
	return repo, nil
}

// DeleteRepo 删除仓库（api.md 10.7）。
func (s *Service) DeleteRepo(ctx context.Context, userID, itemID, repoID string) error {
	if _, err := s.Get(ctx, userID, itemID); err != nil {
		return err
	}

	res, err := s.db.ExecContext(ctx,
		`DELETE FROM portfolio_repos WHERE id = $1 AND portfolio_item_id = $2`, repoID, itemID)
	if err != nil {
		return fmt.Errorf("删除仓库失败: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("读取删除结果失败: %w", err)
	}
	if n == 0 {
		return ErrRepoNotFound
	}
	return nil
}

// reposFor 批量取作品的仓库，按主链接优先、平台排序。
func (s *Service) reposFor(ctx context.Context, itemIDs []string) (map[string][]Repo, error) {
	out := make(map[string][]Repo, len(itemIDs))
	if len(itemIDs) == 0 {
		return out, nil
	}

	const q = `
		SELECT portfolio_item_id, id, url, title, is_primary
		FROM portfolio_repos
		WHERE portfolio_item_id = ANY($1)
		ORDER BY is_primary DESC, url`

	rows, err := s.db.QueryContext(ctx, q, itemIDs)
	if err != nil {
		return nil, fmt.Errorf("查询作品仓库失败: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var itemID string
		var r Repo
		if err := rows.Scan(&itemID, &r.ID, &r.URL, &r.Title, &r.IsPrimary); err != nil {
			return nil, fmt.Errorf("扫描作品链接失败: %w", err)
		}
		r.Kind = s.RepoKind(r.URL)
		out[itemID] = append(out[itemID], r)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取作品仓库失败: %w", err)
	}

	for _, id := range itemIDs {
		if out[id] == nil {
			out[id] = []Repo{}
		}
	}
	return out, nil
}

// ---------- HTTP ----------

// Handler 承载作品集接口。
type Handler struct {
	svc *Service
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func fail(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrItemNotFound), errors.Is(err, ErrRepoNotFound):
		httpx.FailNotFound(c)
	case errors.Is(err, ErrDuplicateRepo), errors.Is(err, ErrPrimaryExists):
		httpx.FailConflict(c, err.Error())
	case errors.Is(err, ErrTitleRequired):
		httpx.FailValidation(c, map[string]string{"title": err.Error()})
	case errors.Is(err, ErrInvalidURL):
		httpx.FailValidation(c, map[string]string{"url": err.Error()})
	default:
		httpx.FailInternal(c, err)
	}
}

// ListPublic 实现 GET /api/public/portfolio（api.md 10.1）。
func (h *Handler) ListPublic(c *gin.Context) {
	items, err := h.svc.ListPublic(c.Request.Context())
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, httpx.NewList(items, len(items)))
}

type createRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	Content     string `json:"content"`
	SortOrder   int    `json:"sort_order"`
}

// Create 实现 POST /api/portfolio（api.md 10.2）。
func (h *Handler) Create(c *gin.Context) {
	var req createRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}

	item, err := h.svc.Create(c.Request.Context(), auth.UserID(c), req.Title, req.Description, req.Content, req.SortOrder)
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(201, item)
}

type updateRequest struct {
	Title       *string `json:"title"`
	Description *string `json:"description"`
	Content     *string `json:"content"`
	SortOrder   *int    `json:"sort_order"`
}

// Update 实现 PATCH /api/portfolio/:id（api.md 10.3）。
func (h *Handler) Update(c *gin.Context) {
	var req updateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}

	item, err := h.svc.Update(c.Request.Context(), auth.UserID(c), c.Param("id"),
		UpdateInput{Title: req.Title, Description: req.Description, Content: req.Content, SortOrder: req.SortOrder})
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, item)
}

// Delete 实现 DELETE /api/portfolio/:id（api.md 10.4）。
func (h *Handler) Delete(c *gin.Context) {
	if err := h.svc.Delete(c.Request.Context(), auth.UserID(c), c.Param("id")); err != nil {
		fail(c, err)
		return
	}
	c.Status(204)
}

type repoRequest struct {
	URL       string `json:"url"`
	Title     string `json:"title"`
	IsPrimary bool   `json:"is_primary"`
}

// AddRepo 实现 POST /api/portfolio/:id/repos（api.md 10.5）。
func (h *Handler) AddRepo(c *gin.Context) {
	var req repoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}

	repo, err := h.svc.AddRepo(c.Request.Context(), auth.UserID(c), c.Param("id"),
		RepoInput{URL: req.URL, Title: req.Title, IsPrimary: req.IsPrimary})
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(201, repo)
}

type repoUpdateRequest struct {
	URL       *string `json:"url"`
	Title     *string `json:"title"`
	IsPrimary *bool   `json:"is_primary"`
}

// UpdateRepo 实现 PATCH /api/portfolio/:id/repos/:repoId（api.md 10.6）。
func (h *Handler) UpdateRepo(c *gin.Context) {
	var req repoUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailBadRequest(c, err)
		return
	}

	repo, err := h.svc.UpdateRepo(c.Request.Context(), auth.UserID(c), c.Param("id"), c.Param("repoId"),
		UpdateRepoInput{URL: req.URL, Title: req.Title, IsPrimary: req.IsPrimary})
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, repo)
}

// DeleteRepo 实现 DELETE /api/portfolio/:id/repos/:repoId（api.md 10.7）。
func (h *Handler) DeleteRepo(c *gin.Context) {
	if err := h.svc.DeleteRepo(c.Request.Context(), auth.UserID(c), c.Param("id"), c.Param("repoId")); err != nil {
		fail(c, err)
		return
	}
	c.Status(204)
}

// RegisterRoutes 注册作品集路由（api.md 第十节）。
// Get 实现 GET /api/portfolio/:id（docs/v3/api.md 1.2）：私有域作品详情，含正文。
//
// 私有域列表用的是公开列表接口（不返回正文），编辑器打开作品时需要单独取一次详情。
func (h *Handler) Get(c *gin.Context) {
	item, err := h.svc.Get(c.Request.Context(), auth.UserID(c), c.Param("id"))
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, item)
}

// GetPublic 实现 GET /api/public/portfolio/:id（docs/v3/api.md 2.2）：公开的作品详情，含正文。
func (h *Handler) GetPublic(c *gin.Context) {
	item, err := h.svc.GetPublic(c.Request.Context(), c.Param("id"))
	if err != nil {
		fail(c, err)
		return
	}
	c.JSON(200, item)
}

func RegisterRoutes(r gin.IRouter, h *Handler) {
	r.GET("/api/public/portfolio", h.ListPublic)
	r.GET("/api/public/portfolio/:id", h.GetPublic)

	read := r.Group("/api/portfolio", auth.RequireLogin())
	read.GET("/:id", h.Get)

	write := r.Group("/api/portfolio", auth.RequireWrite())
	write.POST("", h.Create)
	write.PATCH("/:id", h.Update)
	write.DELETE("/:id", h.Delete)
	write.POST("/:id/repos", h.AddRepo)
	write.PATCH("/:id/repos/:repoId", h.UpdateRepo)
	write.DELETE("/:id/repos/:repoId", h.DeleteRepo)
}
