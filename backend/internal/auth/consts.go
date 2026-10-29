package auth

// 认证相关的常量。依据 docs/architecture.md 第四节「常量（不进配置）」：
// 这些值直接写在代码里，不通过环境变量暴露，避免误配。

import "time"

const (
	// CookieSession 是会话 cookie 名（auth.md 第三节）。
	CookieSession = "haven_session"
	// CookieTrustedDevice 是授信设备 cookie 名（auth.md 第四节）。
	CookieTrustedDevice = "haven_trusted_device"

	// SessionTTL 是会话有效期，固定 7 天，不做滑动续期（auth.md 第三节规则 4）。
	SessionTTL = 7 * 24 * time.Hour
	// TrustedDeviceTTL 是授信设备有效期，30 天（auth.md 第四节规则 3）。
	TrustedDeviceTTL = 30 * 24 * time.Hour
	// PendingLoginTTL 是待验证登录有效期，5 分钟（auth.md 3.1 规则 2）。
	PendingLoginTTL = 5 * time.Minute

	// Token scope 两档（auth.md 第五节规则 4）。
	ScopeRead      = "read"
	ScopeReadWrite = "read_write"
)

// BcryptCost 固定 12（auth.md 8.1）。
const BcryptCost = 12

// MinPasswordLen 是新密码最小长度（api.md 2.7）。
const MinPasswordLen = 12
