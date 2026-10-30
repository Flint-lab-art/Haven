package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
)

// 登录 / TOTP / 密码相关的业务逻辑。
//
// 依据 docs/backend/auth.md：
//   - 第二节：两步登录流程；
//   - 第三节：会话，7 天，硬删除；
//   - 3.1：pending_logins，5 分钟；trust_device 拼在临时 token 明文末尾，不落库；
//   - 第四节：授信设备，30 天，免 TOTP 不免密；
//   - 第八节：bcrypt、TOTP secret 明文存储、改密后的级联。

// 业务错误类型，由 handler 层映射成 api.md 1.4 的 HTTP 状态码。
var (
	// ErrInvalidCredentials 用户名或密码错误（401）。message 统一，防枚举（api.md 2.1）。
	ErrInvalidCredentials = errors.New("用户名或密码错误")
	// ErrPendingExpired 临时 token 无效或已过期（401）。
	ErrPendingExpired = errors.New("登录已超时，请重新登录")
	// ErrNoSuchUser 用户名不存在。对外与 ErrInvalidCredentials 同样返回 401 + 同一 message，
	// 仅在审计里用 reason=no_such_user 区分（audit.md 第三节）。
	ErrNoSuchUser = errors.New("用户名不存在")
	// ErrBadTotp 动态码错误（401）。
	ErrBadTotp = errors.New("动态码错误")
	// ErrTotpAlreadyEnabled TOTP 已启用（409）。
	ErrTotpAlreadyEnabled = errors.New("已启用 TOTP")
	// ErrTotpNotEnabled 尚未启用 TOTP（422）。
	ErrTotpNotEnabled = errors.New("尚未启用 TOTP")
	// ErrSessionNotFound 会话不存在或不属于当前用户（404）。
	ErrSessionNotFound = errors.New("会话不存在")
	// ErrCannotRevokeCurrentSession 不能撤销当前会话（422，api.md 3.2）。
	ErrCannotRevokeCurrentSession = errors.New("请使用登出接口撤销当前会话")
)

// User 是 users 表在鉴权层的完整视图（auth.md 第九节）。
type User struct {
	ID           string
	Username     string
	PasswordHash string
	TotpSecret   string
	TotpEnabled  bool
}

// LoginResult 是 POST /api/auth/login 的领域结果（api.md 2.1）。
type LoginResult struct {
	User         UserBrief
	TotpRequired bool
	// TempToken 仅在 TotpRequired 时非空。
	TempToken string
	// SessionToken / DeviceToken 是下发 cookie 的明文，仅在不需 TOTP 时非空。
	SessionToken string
	DeviceToken  string
	// DeviceID / DeviceName 是新建授信设备的信息，供写 trusted_device_added 审计。
	DeviceID   string
	DeviceName string
	// AuditVia 用于写 login_success 审计（audit.md 第三节）。
	// 不需要 TOTP 时也要写，值为 password+totp 或 password+trusted_device。
	AuditVia string
}

// UserBrief 是响应里的 {id, username}（api.md 2.1）。
type UserBrief struct {
	ID       string `json:"id"`
	Username string `json:"username"`
}

// Service 承载认证业务逻辑，不依赖 gin。
type Service struct {
	db  *sql.DB
	now func() time.Time
}

// NewService 构造 Service。
func NewService(db *sql.DB) *Service {
	return &Service{db: db, now: time.Now}
}

// Login 执行第二步之前的第一步：校验账密，再决定是否直接建会话。
//
// 流程见 auth.md 2.1：
//  1. 账密错误 → ErrInvalidCredentials；
//  2. 未启用 TOTP → 直接建会话；
//  3. 启用 TOTP 但授信设备有效 → 跳过 TOTP，直接建会话；
//  4. 否则 → 建 pending_logins 并返回临时 token。
func (s *Service) Login(ctx context.Context, username, password string, trustDevice bool, trustedDeviceCookie, userAgent string) (LoginResult, error) {
	user, err := s.findUserByUsername(ctx, username)
	if errors.Is(err, ErrNotFound) {
		// 区分出来只为写审计的 reason=no_such_user；
		// 对外响应仍统一为「用户名或密码错误」，不泄露账号是否存在
		return LoginResult{}, ErrNoSuchUser
	}
	if err != nil {
		return LoginResult{}, err
	}

	if !passwordMatches(user.PasswordHash, password) {
		return LoginResult{}, ErrInvalidCredentials
	}

	now := s.now()

	// 未启用 TOTP：第一步即完成登录
	if !user.TotpEnabled {
		res, err := s.issueSession(ctx, user, trustDevice, userAgent, now)
		if err != nil {
			return LoginResult{}, err
		}
		res.AuditVia = auditViaTotp
		return res, nil
	}

	// 启用 TOTP：先看授信设备是否有效。授信设备不免密，只免 TOTP（auth.md 2.3）
	if trustedDeviceCookie != "" {
		ok, err := s.trustedDeviceValid(ctx, user.ID, trustedDeviceCookie, now)
		if err != nil {
			return LoginResult{}, err
		}
		if ok {
			res, err := s.issueSession(ctx, user, trustDevice, userAgent, now)
			if err != nil {
				return LoginResult{}, err
			}
			res.AuditVia = auditViaTrustedDevice
			return res, nil
		}
	}

	// 需要 TOTP：建 pending_logins，trust_device 编进临时 token 明文
	tempToken, err := newPendingToken(trustDevice)
	if err != nil {
		return LoginResult{}, err
	}
	hashedToken, _ := splitPendingToken(tempToken)

	// 顺手清理该用户已过期的待验证记录（auth.md 3.1 规则 3 允许）
	if _, err := s.db.ExecContext(ctx,
		`DELETE FROM pending_logins WHERE user_id = $1 AND expires_at <= now()`, user.ID); err != nil {
		return LoginResult{}, fmt.Errorf("清理过期待验证登录失败: %w", err)
	}

	if _, err := s.db.ExecContext(ctx,
		`INSERT INTO pending_logins (user_id, token_hash, expires_at) VALUES ($1, $2, $3)`,
		user.ID, HashToken(hashedToken), now.Add(PendingLoginTTL)); err != nil {
		return LoginResult{}, fmt.Errorf("创建待验证登录失败: %w", err)
	}

	return LoginResult{
		User:         UserBrief{ID: user.ID, Username: user.Username},
		TotpRequired: true,
		TempToken:    tempToken,
	}, nil
}

// LoginTotp 执行第二步：校验临时 token 与动态码（api.md 2.2 / auth.md 2.2）。
func (s *Service) LoginTotp(ctx context.Context, tempToken, code, userAgent string) (LoginResult, error) {
	// auth.md 3.1 规则 1：先剥离 trust_device 后缀，再哈希查库
	base, trustDevice := splitPendingToken(tempToken)

	now := s.now()
	var userID string
	err := s.db.QueryRowContext(ctx,
		`SELECT user_id FROM pending_logins WHERE token_hash = $1 AND expires_at > now()`,
		HashToken(base),
	).Scan(&userID)
	if errors.Is(err, sql.ErrNoRows) {
		return LoginResult{}, ErrPendingExpired
	}
	if err != nil {
		return LoginResult{}, fmt.Errorf("查询待验证登录失败: %w", err)
	}

	user, err := s.findUserByID(ctx, userID)
	if err != nil {
		return LoginResult{}, err
	}

	if !TotpValid(user.TotpSecret, code, now) {
		// auth.md 3.1 规则 5：不做失败计数，记录保留到过期
		return LoginResult{}, ErrBadTotp
	}

	if _, err := s.db.ExecContext(ctx,
		`DELETE FROM pending_logins WHERE token_hash = $1`, HashToken(base)); err != nil {
		return LoginResult{}, fmt.Errorf("删除待验证登录失败: %w", err)
	}

	res, err := s.issueSessionWithFlags(ctx, user, trustDevice, userAgent, true, now)
	if err != nil {
		return LoginResult{}, err
	}
	res.AuditVia = auditViaTotp
	return res, nil
}

// Logout 删除当前会话；Token 调用无实际操作（api.md 2.3）。
func (s *Service) Logout(ctx context.Context, sessionID string) error {
	if sessionID == "" {
		return nil
	}
	const q = `DELETE FROM sessions WHERE id = $1`
	if _, err := s.db.ExecContext(ctx, q, sessionID); err != nil {
		return fmt.Errorf("删除会话失败: %w", err)
	}
	return nil
}

// SetupTotp 生成新的 TOTP secret 与 otpauth URI，但**不落库**（api.md 2.4）。
func (s *Service) SetupTotp(userID, issuer string) (secret, uri string, err error) {
	user, err := s.findUserByID(context.Background(), userID)
	if err != nil {
		return "", "", err
	}
	if user.TotpEnabled {
		return "", "", ErrTotpAlreadyEnabled
	}

	secret, uri, err = NewTotpSecret(issuer, user.Username)
	if err != nil {
		return "", "", err
	}
	return secret, uri, nil
}

// VerifyTotp 校验并落库 secret，置 totp_enabled = true（api.md 2.5）。
func (s *Service) VerifyTotp(ctx context.Context, userID, secret, code string) error {
	user, err := s.findUserByID(ctx, userID)
	if err != nil {
		return err
	}
	if user.TotpEnabled {
		return ErrTotpAlreadyEnabled
	}
	if !TotpValid(secret, code, s.now()) {
		return ErrBadTotp
	}

	const q = `UPDATE users SET totp_secret = $2, totp_enabled = true, updated_at = now() WHERE id = $1`
	if _, err := s.db.ExecContext(ctx, q, userID, secret); err != nil {
		return fmt.Errorf("保存 TOTP secret 失败: %w", err)
	}
	return nil
}

// DisableTotp 关闭 TOTP 并删除该用户全部授信设备（api.md 2.6 / auth.md）。
func (s *Service) DisableTotp(ctx context.Context, userID, code string) error {
	user, err := s.findUserByID(ctx, userID)
	if err != nil {
		return err
	}
	if !user.TotpEnabled {
		return ErrTotpNotEnabled
	}
	if !TotpValid(user.TotpSecret, code, s.now()) {
		return ErrBadTotp
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	if _, err := tx.ExecContext(ctx,
		`UPDATE users SET totp_secret = NULL, totp_enabled = false, updated_at = now() WHERE id = $1`,
		userID); err != nil {
		return fmt.Errorf("关闭 TOTP 失败: %w", err)
	}
	// 授信设备的存在意义是免 TOTP，关闭后必须一并删除（api.md 2.6 备注）
	if _, err := tx.ExecContext(ctx,
		`DELETE FROM trusted_devices WHERE user_id = $1`, userID); err != nil {
		return fmt.Errorf("删除授信设备失败: %w", err)
	}

	return tx.Commit()
}

// ChangePassword 修改密码：同事务内删全部会话与授信设备，不删 Token（auth.md 8.3）。
func (s *Service) ChangePassword(ctx context.Context, userID, oldPassword, newPassword, totpCode string) error {
	user, err := s.findUserByID(ctx, userID)
	if err != nil {
		return err
	}
	if !passwordMatches(user.PasswordHash, oldPassword) {
		return ErrInvalidCredentials
	}
	if user.TotpEnabled && !TotpValid(user.TotpSecret, totpCode, s.now()) {
		return ErrBadTotp
	}
	if err := ValidatePassword(newPassword, oldPassword); err != nil {
		return err
	}

	hash, err := HashPassword(newPassword)
	if err != nil {
		return err
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	if _, err := tx.ExecContext(ctx,
		`UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1`,
		userID, hash); err != nil {
		return fmt.Errorf("更新密码失败: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM sessions WHERE user_id = $1`, userID); err != nil {
		return fmt.Errorf("删除会话失败: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM trusted_devices WHERE user_id = $1`, userID); err != nil {
		return fmt.Errorf("删除授信设备失败: %w", err)
	}
	// 刻意不删 tokens（auth.md 8.3 第 3 条）

	return tx.Commit()
}

// issueSessionWithFlags 与 issueSession 相同，额外指定会话是否带 TOTP 标记。
//
// login_success 的 via 决定标记：
//   - password+totp              → 会话通过过 TOTP
//   - password+trusted_device    → 授信设备只免 TOTP，会话本身未通过过 TOTP
//   - 未启用 TOTP                → 未通过过 TOTP
func (s *Service) issueSessionWithFlags(ctx context.Context, user User, trustDevice bool, userAgent string, totpVerified bool, now time.Time) (LoginResult, error) {
	sessionToken, err := newSessionTokenFor(totpVerified)
	if err != nil {
		return LoginResult{}, err
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return LoginResult{}, fmt.Errorf("开启事务失败: %w", err)
	}
	defer tx.Rollback()

	base, _ := splitSessionToken(sessionToken)
	if _, err := tx.ExecContext(ctx,
		`INSERT INTO sessions (user_id, token_hash, expires_at, last_used_at, user_agent)
		 VALUES ($1, $2, $3, $4, $5)`,
		user.ID, HashToken(base), now.Add(SessionTTL), now, userAgent); err != nil {
		return LoginResult{}, fmt.Errorf("创建会话失败: %w", err)
	}

	res := LoginResult{
		User:         UserBrief{ID: user.ID, Username: user.Username},
		TotpRequired: false,
		SessionToken: sessionToken,
	}

	if trustDevice {
		deviceToken, err := newDeviceToken()
		if err != nil {
			return LoginResult{}, err
		}
		name := deviceNameFromUA(userAgent)
		var deviceID string
		if err := tx.QueryRowContext(ctx,
			`INSERT INTO trusted_devices (user_id, token_hash, device_name, expires_at, last_used_at)
			 VALUES ($1, $2, $3, $4, $5) RETURNING id`,
			user.ID, HashToken(deviceToken), name, now.Add(TrustedDeviceTTL), now).Scan(&deviceID); err != nil {
			return LoginResult{}, fmt.Errorf("创建授信设备失败: %w", err)
		}
		res.DeviceToken = deviceToken
		res.DeviceID = deviceID
		res.DeviceName = name
	}

	if err := tx.Commit(); err != nil {
		return LoginResult{}, fmt.Errorf("提交事务失败: %w", err)
	}
	return res, nil
}

// issueSession 创建会话，供未启用 TOTP / 授信设备路径复用（未通过 TOTP）。
func (s *Service) issueSession(ctx context.Context, user User, trustDevice bool, userAgent string, now time.Time) (LoginResult, error) {
	return s.issueSessionWithFlags(ctx, user, trustDevice, userAgent, false, now)
}

// trustedDeviceValid 校验授信设备：未过期、哈希匹配、属于该用户（auth.md 2.1）。
// 匹配成功会刷新 last_used_at。
func (s *Service) trustedDeviceValid(ctx context.Context, userID, cookieValue string, now time.Time) (bool, error) {
	const q = `SELECT id FROM trusted_devices WHERE user_id = $1 AND token_hash = $2 AND expires_at > now()`
	var id string
	err := s.db.QueryRowContext(ctx, q, userID, HashToken(cookieValue)).Scan(&id)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("查询授信设备失败: %w", err)
	}
	if _, err := s.db.ExecContext(ctx,
		`UPDATE trusted_devices SET last_used_at = $2 WHERE id = $1`, id, now); err != nil {
		return false, fmt.Errorf("更新授信设备时间失败: %w", err)
	}
	return true, nil
}

func (s *Service) findUserByUsername(ctx context.Context, username string) (User, error) {
	// username 不区分大小写（auth.md 第九节规则 3）
	const q = `SELECT id, username, password_hash, coalesce(totp_secret, ''), totp_enabled
	           FROM users WHERE lower(username) = lower($1)`
	return s.scanUser(s.db.QueryRowContext(ctx, q, strings.TrimSpace(username)))
}

func (s *Service) findUserByID(ctx context.Context, id string) (User, error) {
	const q = `SELECT id, username, password_hash, coalesce(totp_secret, ''), totp_enabled
	           FROM users WHERE id = $1`
	return s.scanUser(s.db.QueryRowContext(ctx, q, id))
}

func (s *Service) scanUser(row *sql.Row) (User, error) {
	var u User
	err := row.Scan(&u.ID, &u.Username, &u.PasswordHash, &u.TotpSecret, &u.TotpEnabled)
	if errors.Is(err, sql.ErrNoRows) {
		return User{}, ErrNotFound
	}
	if err != nil {
		return User{}, fmt.Errorf("查询用户失败: %w", err)
	}
	return u, nil
}

// pendingUsername 用 pending_logins 的哈希反查用户名，供失败审计使用。
func (s *Service) pendingUsername(ctx context.Context, tokenHash string) (string, error) {
	const q = `
		SELECT u.username
		FROM pending_logins p
		JOIN users u ON u.id = p.user_id
		WHERE p.token_hash = $1`
	var name string
	if err := s.db.QueryRowContext(ctx, q, tokenHash).Scan(&name); err != nil {
		return "", fmt.Errorf("查询待验证登录用户名失败: %w", err)
	}
	return name, nil
}

// deviceNameFromUA 从 UA 里取一个粗略可读的设备名，作为 trusted_devices.device_name 的默认值。
// 用户可在设置页后续改名；这里只避免留空串（auth.md 第四节字段默认 ”）。
func deviceNameFromUA(ua string) string {
	if ua == "" {
		return ""
	}
	for _, sep := range []string{" ", "/"} {
		if i := strings.Index(ua, sep); i > 0 {
			return ua[:i]
		}
	}
	return ua
}
