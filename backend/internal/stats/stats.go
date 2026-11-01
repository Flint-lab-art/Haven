// Package stats 提供首页概览所需的统计数据（docs/v5/api.md 第一节）。
//
// 一次请求返回全部聚合结果，前端不用拉全量笔记自行计算。
// 只读、只统计当前用户、统一排除回收站。
package stats

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"
)

// HeatmapDays 是热力图覆盖的天数：近三个月。
//
// 取 91 天而不是半年：早期数据稀疏，半年的格子图大部分是空的。
// 代码常量，不从环境变量读取（docs/v5/conventions.md 第一节第 4 条）。
const HeatmapDays = 91

// RecentLimit 是「最近编辑」返回的条数。
const RecentLimit = 5

// Totals 是总量统计。
type Totals struct {
	Notes       int   `json:"notes"`
	Words       int64 `json:"words"`
	PublicNotes int   `json:"public_notes"`
}

// Week 是本周动态。
type Week struct {
	Created int `json:"created"`
	Updated int `json:"updated"`
}

// HeatmapCell 是热力图的一天。
type HeatmapCell struct {
	Date  string `json:"date"`
	Count int    `json:"count"`
}

// RecentNote 是「最近编辑」的一项。
type RecentNote struct {
	ID         string    `json:"id"`
	Title      string    `json:"title"`
	UpdatedAt  time.Time `json:"updated_at"`
	Visibility string    `json:"visibility"`
}

// Snapshot 是 GET /api/stats 的响应。
type Snapshot struct {
	Totals  Totals        `json:"totals"`
	Week    Week          `json:"week"`
	Heatmap []HeatmapCell `json:"heatmap"`
	Recent  []RecentNote  `json:"recent"`
}

// Service 承载统计逻辑。
type Service struct {
	db  *sql.DB
	now func() time.Time
}

// NewService 构造 Service。
func NewService(db *sql.DB) *Service {
	return &Service{db: db, now: time.Now}
}

// Snapshot 返回当前用户的全部统计数据（docs/v5/api.md 1.1）。
func (s *Service) Snapshot(ctx context.Context, userID string) (Snapshot, error) {
	out := Snapshot{
		Heatmap: []HeatmapCell{},
		Recent:  []RecentNote{},
	}

	if err := s.loadTotals(ctx, userID, &out); err != nil {
		return Snapshot{}, err
	}
	if err := s.loadWeek(ctx, userID, &out); err != nil {
		return Snapshot{}, err
	}
	if err := s.loadHeatmap(ctx, userID, &out); err != nil {
		return Snapshot{}, err
	}
	if err := s.loadRecent(ctx, userID, &out); err != nil {
		return Snapshot{}, err
	}
	return out, nil
}

// loadTotals 统计笔记数、字数与公开数。
//
// 字数用 length(content)：PostgreSQL 的 length 按字符计，中文算 1 个。
func (s *Service) loadTotals(ctx context.Context, userID string, out *Snapshot) error {
	const q = `
		SELECT
			count(*),
			coalesce(sum(length(content)), 0),
			count(*) FILTER (WHERE visibility = 'public' AND published_at IS NOT NULL)
		FROM notes
		WHERE user_id = $1 AND deleted_at IS NULL`

	if err := s.db.QueryRowContext(ctx, q, userID).Scan(
		&out.Totals.Notes, &out.Totals.Words, &out.Totals.PublicNotes); err != nil {
		return fmt.Errorf("统计总量失败: %w", err)
	}
	return nil
}

// loadWeek 统计最近 7 天的新建与编辑数。
//
// 用滚动 7 天而不是自然周：不受「今天是周几」影响，看板每天打开都有意义。
func (s *Service) loadWeek(ctx context.Context, userID string, out *Snapshot) error {
	since := s.now().AddDate(0, 0, -7)

	const q = `
		SELECT
			count(*) FILTER (WHERE created_at >= $2),
			count(*) FILTER (WHERE updated_at >= $2)
		FROM notes
		WHERE user_id = $1 AND deleted_at IS NULL`

	if err := s.db.QueryRowContext(ctx, q, userID, since).Scan(
		&out.Week.Created, &out.Week.Updated); err != nil {
		return fmt.Errorf("统计本周动态失败: %w", err)
	}
	return nil
}

// loadHeatmap 统计近三个月每天的编辑篇数，缺失的日期补 0。
func (s *Service) loadHeatmap(ctx context.Context, userID string, out *Snapshot) error {
	today := startOfDay(s.now())
	from := today.AddDate(0, 0, -(HeatmapDays - 1))

	// 同一天编辑同一篇多次只算 1 次，避免反复保存把格子刷爆
	const q = `
		SELECT (updated_at AT TIME ZONE 'UTC')::date AS day, count(DISTINCT id)
		FROM notes
		WHERE user_id = $1
		  AND deleted_at IS NULL
		  AND updated_at >= $2
		GROUP BY day`

	rows, err := s.db.QueryContext(ctx, q, userID, from)
	if err != nil {
		return fmt.Errorf("统计热力图失败: %w", err)
	}
	defer rows.Close()

	counts := make(map[string]int, HeatmapDays)
	for rows.Next() {
		var day time.Time
		var n int
		if err := rows.Scan(&day, &n); err != nil {
			return fmt.Errorf("扫描热力图失败: %w", err)
		}
		counts[day.Format("2006-01-02")] = n
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("读取热力图失败: %w", err)
	}

	// 补齐完整日期序列，前端不自己补空格子
	cells := make([]HeatmapCell, 0, HeatmapDays)
	for d := from; !d.After(today); d = d.AddDate(0, 0, 1) {
		key := d.Format("2006-01-02")
		cells = append(cells, HeatmapCell{Date: key, Count: counts[key]})
	}
	out.Heatmap = cells
	return nil
}

// loadRecent 取最近编辑的几篇。
func (s *Service) loadRecent(ctx context.Context, userID string, out *Snapshot) error {
	const q = `
		SELECT id, title, updated_at, visibility
		FROM notes
		WHERE user_id = $1 AND deleted_at IS NULL
		ORDER BY updated_at DESC
		LIMIT $2`

	rows, err := s.db.QueryContext(ctx, q, userID, RecentLimit)
	if err != nil {
		return fmt.Errorf("查询最近编辑失败: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var n RecentNote
		if err := rows.Scan(&n.ID, &n.Title, &n.UpdatedAt, &n.Visibility); err != nil {
			return fmt.Errorf("扫描最近编辑失败: %w", err)
		}
		out.Recent = append(out.Recent, n)
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("读取最近编辑失败: %w", err)
	}
	return nil
}

// startOfDay 取当天零点，用于对齐热力图的日期边界。
func startOfDay(t time.Time) time.Time {
	y, m, d := t.Date()
	return time.Date(y, m, d, 0, 0, 0, 0, t.Location())
}

// Handler 承载统计接口。
type Handler struct {
	svc *Service
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// Snapshot 实现 GET /api/stats（docs/v5/api.md 第一节）。
func (h *Handler) Snapshot(c *gin.Context) {
	snap, err := h.svc.Snapshot(c.Request.Context(), auth.UserID(c))
	if err != nil {
		httpx.FailInternal(c, err)
		return
	}
	c.JSON(200, snap)
}

// RegisterRoutes 挂载统计接口。
func RegisterRoutes(r gin.IRouter, h *Handler) {
	read := r.Group("/api/stats", auth.RequireLogin())
	read.GET("", h.Snapshot)
}
