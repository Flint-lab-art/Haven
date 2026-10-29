package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// API Token 管理（api.md 第五节 / auth.md 第五节）。
//
// 规则要点：
//   - 明文只在创建时返回一次，之后只能看到 token_prefix；
//   - 撤销 = 写 revoked_at，不删除记录；
//   - Token 不能管理凭证类资源，由 handler 层的 RequireTotpVerified 拦截。

// ErrTokenNotFound 表示 Token 不存在或不属于当前用户（404）。
var ErrTokenNotFound = errors.New("Token 不存在")

// ErrTokenAlreadyRevoked 表示 Token 已撤销（422，api.md 5.3）。
var ErrTokenAlreadyRevoked = errors.New("Token 已撤销")

// APITokenSummary 是 GET /api/tokens 的列表项（api.md 5.1）。
// 不包含明文，也不包含 token_hash。
type APITokenSummary struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	TokenPrefix string     `json:"token_prefix"`
	Scope       string     `json:"scope"`
	ExpiresAt   *time.Time `json:"expires_at"`
	LastUsedAt  *time.Time `json:"last_used_at"`
	RevokedAt   *time.Time `json:"revoked_at"`
	CreatedAt   time.Time  `json:"created_at"`
}

// CreatedAPIToken 是 POST /api/tokens 的响应（api.md 5.2），含一次性明文。
type CreatedAPIToken struct {
	APITokenSummary
	Token string `json:"token"`
}

// ListAPITokens 返回当前用户的全部 Token（含已撤销），按创建时间倒序。
func (s *Service) ListAPITokens(ctx context.Context, userID string) ([]APITokenSummary, error) {
	const q = `
		SELECT id, name, token_prefix, scope, expires_at, last_used_at, revoked_at, created_at
		FROM tokens
		WHERE user_id = $1
		ORDER BY created_at DESC`

	rows, err := s.db.QueryContext(ctx, q, userID)
	if err != nil {
		return nil, fmt.Errorf("查询 Token 列表失败: %w", err)
	}
	defer rows.Close()

	out := make([]APITokenSummary, 0, 4)
	for rows.Next() {
		var item APITokenSummary
		if err := rows.Scan(
			&item.ID, &item.Name, &item.TokenPrefix, &item.Scope,
			&item.ExpiresAt, &item.LastUsedAt, &item.RevokedAt, &item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("扫描 Token 失败: %w", err)
		}
		out = append(out, item)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取 Token 列表失败: %w", err)
	}
	return out, nil
}

// CreateAPIToken 创建 Token 并返回一次性明文（api.md 5.2）。
// expiresAt 为 nil 表示永不过期（auth.md 第五节规则 5）。
func (s *Service) CreateAPIToken(ctx context.Context, userID, name, scope string, expiresAt *time.Time) (CreatedAPIToken, error) {
	if err := ValidateScope(scope); err != nil {
		return CreatedAPIToken{}, err
	}

	token, prefix, err := newAPIToken(scope)
	if err != nil {
		return CreatedAPIToken{}, err
	}

	const q = `
		INSERT INTO tokens (user_id, name, token_hash, token_prefix, scope, expires_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`

	var id string
	var createdAt time.Time
	if err := s.db.QueryRowContext(ctx, q,
		userID, name, HashToken(token), prefix, scope, expiresAt,
	).Scan(&id, &createdAt); err != nil {
		return CreatedAPIToken{}, fmt.Errorf("创建 Token 失败: %w", err)
	}

	return CreatedAPIToken{
		APITokenSummary: APITokenSummary{
			ID:          id,
			Name:        name,
			TokenPrefix: prefix,
			Scope:       scope,
			ExpiresAt:   expiresAt,
			CreatedAt:   createdAt,
		},
		Token: token,
	}, nil
}

// RevokeAPIToken 撤销 Token：写 revoked_at，不删记录（api.md 5.3）。
// 返回 Token 名与前缀，供写审计事件（audit.md 第三节）。
func (s *Service) RevokeAPIToken(ctx context.Context, userID, tokenID string) (APITokenSummary, error) {
	const findQ = `
		SELECT id, name, token_prefix, scope, expires_at, last_used_at, revoked_at, created_at
		FROM tokens WHERE id = $1 AND user_id = $2`

	var item APITokenSummary
	err := s.db.QueryRowContext(ctx, findQ, tokenID, userID).Scan(
		&item.ID, &item.Name, &item.TokenPrefix, &item.Scope,
		&item.ExpiresAt, &item.LastUsedAt, &item.RevokedAt, &item.CreatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return APITokenSummary{}, ErrTokenNotFound
	}
	if err != nil {
		return APITokenSummary{}, fmt.Errorf("查询 Token 失败: %w", err)
	}
	if item.RevokedAt != nil {
		return APITokenSummary{}, ErrTokenAlreadyRevoked
	}

	const q = `UPDATE tokens SET revoked_at = now() WHERE id = $1 AND user_id = $2 AND revoked_at IS NULL`
	if _, err := s.db.ExecContext(ctx, q, tokenID, userID); err != nil {
		return APITokenSummary{}, fmt.Errorf("撤销 Token 失败: %w", err)
	}

	revokedAt := s.now()
	item.RevokedAt = &revokedAt
	return item, nil
}

// ValidateScope 校验 scope 取值（auth.md 第五节规则 4）。
func ValidateScope(scope string) error {
	switch scope {
	case ScopeRead, ScopeReadWrite:
		return nil
	default:
		return fmt.Errorf("scope 只能取 %s 或 %s", ScopeRead, ScopeReadWrite)
	}
}

// createTokenForTest 直接建一个可用 Token 并返回明文，仅供测试使用。
func createTokenForTest(ctx context.Context, db *sql.DB, userID, scope string) (string, error) {
	token, prefix, err := newAPIToken(scope)
	if err != nil {
		return "", err
	}
	_, err = db.ExecContext(ctx,
		`INSERT INTO tokens (user_id, name, token_hash, token_prefix, scope)
		 VALUES ($1, 'test', $2, $3, $4)`,
		userID, HashToken(token), prefix, scope)
	if err != nil {
		return "", err
	}
	return token, nil
}
