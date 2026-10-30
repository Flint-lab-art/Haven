package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// 会话管理（api.md 第三节）。
//
// 会话列表只对会话身份开放，Token 调用返回 403 —— 这条在 handler 层用
// RequireSession 控制；Service 本身不区分调用方身份。

// ErrSessionNotFound 见 service.go。

// SessionSummary 是 GET /api/sessions 的列表项（api.md 3.1）。
type SessionSummary struct {
	ID         string    `json:"id"`
	UserAgent  string    `json:"user_agent"`
	CreatedAt  time.Time `json:"created_at"`
	LastUsedAt time.Time `json:"last_used_at"`
	IsCurrent  bool      `json:"is_current"`
}

// ListSessions 返回当前用户的全部会话，按最近使用倒序。
// currentSessionID 用于标记 is_current（api.md 3.1）。
func (s *Service) ListSessions(ctx context.Context, userID, currentSessionID string) ([]SessionSummary, error) {
	const q = `
		SELECT id, user_agent, created_at, last_used_at
		FROM sessions
		WHERE user_id = $1 AND expires_at > now()
		ORDER BY last_used_at DESC`

	rows, err := s.db.QueryContext(ctx, q, userID)
	if err != nil {
		return nil, fmt.Errorf("查询会话列表失败: %w", err)
	}
	defer rows.Close()

	out := make([]SessionSummary, 0, 4)
	for rows.Next() {
		var item SessionSummary
		if err := rows.Scan(&item.ID, &item.UserAgent, &item.CreatedAt, &item.LastUsedAt); err != nil {
			return nil, fmt.Errorf("扫描会话失败: %w", err)
		}
		item.IsCurrent = item.ID == currentSessionID
		out = append(out, item)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取会话列表失败: %w", err)
	}
	return out, nil
}

// RevokeSession 撤销指定会话（api.md 3.2）。
// 不允许撤销当前会话：api.md 3.2 要求返回 422，引导走登出接口。
func (s *Service) RevokeSession(ctx context.Context, userID, sessionID, currentSessionID string) error {
	if sessionID == currentSessionID {
		return ErrCannotRevokeCurrentSession
	}

	const q = `DELETE FROM sessions WHERE id = $1 AND user_id = $2`
	res, err := s.db.ExecContext(ctx, q, sessionID, userID)
	if err != nil {
		return fmt.Errorf("删除会话失败: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("读取删除结果失败: %w", err)
	}
	if n == 0 {
		// 不存在或不属于当前用户，一律 404（不泄露存在性）
		return ErrSessionNotFound
	}
	return nil
}

// FindSessionOwner 返回会话所属用户与创建时间，供撤销时写审计事件。
// 会话不存在（或不属于该用户）时返回 ErrSessionNotFound。
func (s *Service) FindSessionOwner(ctx context.Context, userID, sessionID string) (time.Time, error) {
	const q = `SELECT created_at FROM sessions WHERE id = $1 AND user_id = $2`
	var createdAt time.Time
	err := s.db.QueryRowContext(ctx, q, sessionID, userID).Scan(&createdAt)
	if errors.Is(err, sql.ErrNoRows) {
		return time.Time{}, ErrSessionNotFound
	}
	if err != nil {
		return time.Time{}, fmt.Errorf("查询会话失败: %w", err)
	}
	return createdAt, nil
}
