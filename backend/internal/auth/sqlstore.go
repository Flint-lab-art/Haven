package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// SQLStore 是基于 database/sql 的 Store 实现，手写 SQL（architecture.md 5.1）。
type SQLStore struct {
	db *sql.DB
}

// NewSQLStore 构造 SQLStore。
func NewSQLStore(db *sql.DB) *SQLStore {
	return &SQLStore{db: db}
}

// DB 暴露底层连接池，供 main 装配迁移检查与测试使用。
func (s *SQLStore) DB() *sql.DB { return s.db }

// FindSessionByHash 按 token_hash 查未过期的会话（auth.md 6.1）。
func (s *SQLStore) FindSessionByHash(ctx context.Context, tokenHash string) (Session, error) {
	const q = `
		SELECT id, user_id, token_hash, expires_at, last_used_at, user_agent, created_at
		FROM sessions
		WHERE token_hash = $1 AND expires_at > now()`

	var sess Session
	err := s.db.QueryRowContext(ctx, q, tokenHash).Scan(
		&sess.ID, &sess.UserID, &sess.TokenHash,
		&sess.ExpiresAt, &sess.LastUsedAt, &sess.UserAgent, &sess.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return Session{}, ErrNotFound
	}
	if err != nil {
		return Session{}, fmt.Errorf("查询会话失败: %w", err)
	}
	return sess, nil
}

// TouchSession 更新 last_used_at，不延长 expires_at（auth.md 第三节规则 5）。
func (s *SQLStore) TouchSession(ctx context.Context, id string, at time.Time) error {
	const q = `UPDATE sessions SET last_used_at = $2 WHERE id = $1`
	if _, err := s.db.ExecContext(ctx, q, id, at); err != nil {
		return fmt.Errorf("更新会话时间失败: %w", err)
	}
	return nil
}

// DeleteSession 撤销会话：硬删除（auth.md 第三节规则 7）。
func (s *SQLStore) DeleteSession(ctx context.Context, id string) error {
	const q = `DELETE FROM sessions WHERE id = $1`
	if _, err := s.db.ExecContext(ctx, q, id); err != nil {
		return fmt.Errorf("删除会话失败: %w", err)
	}
	return nil
}

// FindTokenByHash 按 token_hash 查 Token，包含已撤销 / 已过期的记录，由调用方判定。
func (s *SQLStore) FindTokenByHash(ctx context.Context, tokenHash string) (APIToken, error) {
	const q = `
		SELECT id, user_id, name, token_hash, token_prefix, scope,
		       expires_at, last_used_at, revoked_at, created_at
		FROM tokens
		WHERE token_hash = $1`

	var t APIToken
	err := s.db.QueryRowContext(ctx, q, tokenHash).Scan(
		&t.ID, &t.UserID, &t.Name, &t.TokenHash, &t.TokenPrefix, &t.Scope,
		&t.ExpiresAt, &t.LastUsedAt, &t.RevokedAt, &t.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return APIToken{}, ErrNotFound
	}
	if err != nil {
		return APIToken{}, fmt.Errorf("查询 Token 失败: %w", err)
	}
	return t, nil
}

// TouchToken 更新 last_used_at。
func (s *SQLStore) TouchToken(ctx context.Context, id string, at time.Time) error {
	const q = `UPDATE tokens SET last_used_at = $2 WHERE id = $1`
	if _, err := s.db.ExecContext(ctx, q, id, at); err != nil {
		return fmt.Errorf("更新 Token 时间失败: %w", err)
	}
	return nil
}

// GetUser 按 id 取用户（不含密码哈希与 TOTP secret，够 /api/me 使用）。
func (s *SQLStore) GetUser(ctx context.Context, id string) (User, error) {
	const q = `SELECT id, username, password_hash, coalesce(totp_secret, ''), totp_enabled
	           FROM users WHERE id = $1`

	var u User
	err := s.db.QueryRowContext(ctx, q, id).Scan(
		&u.ID, &u.Username, &u.PasswordHash, &u.TotpSecret, &u.TotpEnabled)
	if errors.Is(err, sql.ErrNoRows) {
		return User{}, ErrNotFound
	}
	if err != nil {
		return User{}, fmt.Errorf("查询用户失败: %w", err)
	}
	return u, nil
}

// 编译期断言。
var _ Store = (*SQLStore)(nil)
