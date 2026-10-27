// Package auth 实现认证与授权。
//
// 依据 docs/backend/auth.md：
//   - 凭证生成与哈希（token.go）
//   - 身份识别与授权中间件
//   - 会话、待验证登录、授信设备、API Token 的存取
//
// 约定：*gin.Context 只出现在中间件与 handler 层；
// 业务函数只接受标准 context.Context（docs/architecture.md 5.2）。
package auth

import (
	"context"

	"errors"
	"time"
)

// 与 database/sql 交互时统一的错误。
var (
	// ErrNotFound 表示记录不存在（或已过期、已撤销），调用方按 404 / 401 处理。
	ErrNotFound = errors.New("auth: 记录不存在")
)

// Identity 是授权中间件识别出的请求身份（auth.md 6.1）。
//
// 三个维度：身份种类、Token 的 scope、会话是否通过过 TOTP。
type Identity struct {
	Kind   IdentityKind
	UserID string
	// Scope 仅对 TokenUser 有意义，取值 read / read_write。
	Scope string
	// TotpVerified 仅对 SessionUser 有意义：会话创建时是否通过过 TOTP（auth.md 6.2）。
	TotpVerified bool
}

// IdentityKind 对应 auth.md 6.1 的三种身份。
type IdentityKind int

const (
	// Anonymous 未登录。零值，便于在 context 缺失时安全降级。
	Anonymous IdentityKind = iota
	// SessionUser 通过会话 cookie 登录的用户。
	SessionUser
	// TokenUser 通过 Authorization: Bearer 鉴权的 API Token 用户。
	TokenUser
)

func (k IdentityKind) String() string {
	switch k {
	case SessionUser:
		return "session"
	case TokenUser:
		return "token"
	default:
		return "anonymous"
	}
}

// IsLoggedIn 表示该身份是否已知（会话或 Token）。
func (i Identity) IsLoggedIn() bool {
	return i.Kind == SessionUser || i.Kind == TokenUser
}

// String 返回身份种类的可读名称，用于日志与 /api/me 的 auth_type。
func (i Identity) String() string {
	return i.Kind.String()
}

// Session 是 sessions 表的一行（auth.md 第三节）。
type Session struct {
	ID         string
	UserID     string
	TokenHash  string
	ExpiresAt  time.Time
	LastUsedAt time.Time
	UserAgent  string
	CreatedAt  time.Time
	// TotpVerified 记录会话创建时是否通过过 TOTP。
	// auth.md 6.2 要求「仅 SessionUser 且会话创建时通过过 TOTP」才满足 totp_verified。
	TotpVerified bool
}

// TrustedDevice 是 trusted_devices 表的一行（auth.md 第四节）。
type TrustedDevice struct {
	ID         string
	UserID     string
	TokenHash  string
	DeviceName string
	ExpiresAt  time.Time
	LastUsedAt time.Time
	CreatedAt  time.Time
}

// APIToken 是 tokens 表的一行（auth.md 第五节）。
type APIToken struct {
	ID          string
	UserID      string
	Name        string
	TokenHash   string
	TokenPrefix string
	Scope       string
	ExpiresAt   *time.Time
	LastUsedAt  *time.Time
	RevokedAt   *time.Time
	CreatedAt   time.Time
}

// Store 是鉴权相关的数据访问接口。
//
// 实现放在本包的 sqlstore.go，手写 SQL（architecture.md 5.1）。
// 单独抽接口是为了让中间件与业务逻辑可以在不连库的情况下测试。
type Store interface {
	// FindSessionByHash 查未过期的会话；不存在或已过期返回 ErrNotFound。
	FindSessionByHash(ctx context.Context, tokenHash string) (Session, error)
	// TouchSession 更新 last_used_at，不延长 expires_at（auth.md 第三节规则 5）。
	TouchSession(ctx context.Context, id string, at time.Time) error
	// DeleteSession 撤销会话：硬删除（auth.md 第三节规则 7）。
	DeleteSession(ctx context.Context, id string) error

	// FindTokenByHash 查已撤销 / 过期时间也一并返回，由调用方判定。
	FindTokenByHash(ctx context.Context, tokenHash string) (APIToken, error)
	// TouchToken 更新 tokens.last_used_at。
	TouchToken(ctx context.Context, id string, at time.Time) error

	// GetUser 按 id 取用户；不存在返回 ErrNotFound。
	GetUser(ctx context.Context, id string) (User, error)
}
