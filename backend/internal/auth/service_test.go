package auth

import (
	"context"
	"database/sql"
	"testing"
	"time"
)

// 集成测试：见 testdb_test.go 的 schema 隔离说明。

// createTestUser 插入一个测试用户，返回 id。
// createTestUser 插入一个测试用户，返回 id。
func createTestUser(t *testing.T, svc *Service, username, password string, totpEnabled bool) string {
	t.Helper()
	hash, err := HashPassword(password)
	if err != nil {
		t.Fatal(err)
	}

	var totpSecret any
	if totpEnabled {
		secret, _, err := NewTotpSecret("Haven", username)
		if err != nil {
			t.Fatal(err)
		}
		totpSecret = secret
	}

	var id string
	err = svc.db.QueryRow(
		`INSERT INTO users (username, password_hash, totp_secret, totp_enabled)
		 VALUES ($1, $2, $3, $4) RETURNING id`,
		username, hash, totpSecret, totpEnabled).Scan(&id)
	if err != nil {
		t.Fatalf("插入测试用户失败: %v", err)
	}
	return id
}

func totpSecretOf(t *testing.T, svc *Service, userID string) string {
	t.Helper()
	var secret sql.NullString
	if err := svc.db.QueryRow(`SELECT totp_secret FROM users WHERE id = $1`, userID).Scan(&secret); err != nil {
		t.Fatal(err)
	}
	return secret.String
}

func TestServiceLoginWithoutTotp(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", false)

	res, err := svc.Login(ctx, "kairo", "correct-horse-battery", false, "", "test-agent")
	if err != nil {
		t.Fatalf("Login 返回错误: %v", err)
	}
	if res.TotpRequired {
		t.Error("未启用 TOTP 时不应要求第二步")
	}
	if res.SessionToken == "" {
		t.Fatal("应下发会话 token")
	}
	if res.DeviceToken != "" {
		t.Error("未请求 trust_device 时不应下发设备 token")
	}
	if res.AuditVia != auditViaTotp {
		t.Errorf("审计 via = %q", res.AuditVia)
	}

	// 会话已落库，且只存哈希
	var count int
	if err := svc.db.QueryRow(`SELECT count(*) FROM sessions WHERE user_id = $1`, userID).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Errorf("sessions 行数 = %d", count)
	}
	var storedHash string
	if err := svc.db.QueryRow(`SELECT token_hash FROM sessions WHERE user_id = $1`, userID).Scan(&storedHash); err != nil {
		t.Fatal(err)
	}
	if storedHash == res.SessionToken {
		t.Error("数据库不应存会话 token 明文")
	}
	if storedHash != HashToken(res.SessionToken) {
		t.Error("token_hash 应为明文的 SHA-256")
	}
}

func TestServiceLoginWrongPassword(t *testing.T) {
	svc := newSchemaService(t)
	createTestUser(t, svc, "kairo", "correct-horse-battery", false)

	if _, err := svc.Login(context.Background(), "kairo", "wrong", false, "", ""); err != ErrInvalidCredentials {
		t.Errorf("错误密码应返回 ErrInvalidCredentials，实际 %v", err)
	}
	if _, err := svc.Login(context.Background(), "nobody", "whatever", false, "", ""); err != ErrInvalidCredentials {
		t.Errorf("不存在的用户应返回 ErrInvalidCredentials（防枚举），实际 %v", err)
	}
}

func TestServiceLoginRequiresTotp(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", true)
	if totpSecretOf(t, svc, userID) == "" {
		t.Fatal("启用 TOTP 的用户应已有 secret")
	}

	res, err := svc.Login(ctx, "kairo", "correct-horse-battery", false, "", "")
	if err != nil {
		t.Fatalf("Login 返回错误: %v", err)
	}
	if !res.TotpRequired || res.TempToken == "" {
		t.Fatalf("应要求 TOTP 并返回 temp_token，实际 %+v", res)
	}
	if res.SessionToken != "" {
		t.Error("需要 TOTP 时不应下发会话")
	}

	var pending int
	if err := svc.db.QueryRow(`SELECT count(*) FROM pending_logins`).Scan(&pending); err != nil {
		t.Fatal(err)
	}
	if pending != 1 {
		t.Errorf("pending_logins 行数 = %d", pending)
	}
}

func TestServiceLoginTotpFlow(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", true)
	secret := totpSecretOf(t, svc, userID)

	// trust_device=true：标记应编进 temp_token，不落库
	res, err := svc.Login(ctx, "kairo", "correct-horse-battery", true, "", "")
	if err != nil {
		t.Fatalf("Login 返回错误: %v", err)
	}
	if _, trust := splitPendingToken(res.TempToken); !trust {
		t.Fatal("trust_device=true 时 temp_token 应带授信标记")
	}
	// pending_logins 表没有 trust_device 列（auth.md 3.1），确认列未被误加
	cols, err := tableColumns(svc, "pending_logins")
	if err != nil {
		t.Fatal(err)
	}
	for _, c := range cols {
		if c == "trust_device" {
			t.Error("pending_logins 不应有 trust_device 列")
		}
	}

	code, err := GenerateTotpCode(secret, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	final, err := svc.LoginTotp(ctx, res.TempToken, code, "test-agent")
	if err != nil {
		t.Fatalf("LoginTotp 返回错误: %v", err)
	}
	if final.SessionToken == "" {
		t.Error("第二步成功应下发会话")
	}
	if final.DeviceToken == "" {
		t.Error("第一步请求了 trust_device，第二步成功应下发授信设备")
	}
	if final.AuditVia != auditViaTotp {
		t.Errorf("审计 via = %q", final.AuditVia)
	}

	var pending int
	if err := svc.db.QueryRow(`SELECT count(*) FROM pending_logins`).Scan(&pending); err != nil {
		t.Fatal(err)
	}
	if pending != 0 {
		t.Error("第二步成功后应删除 pending_logins 记录")
	}
}

func TestServiceLoginBadTotpKeepsPending(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	createTestUser(t, svc, "kairo", "correct-horse-battery", true)

	res, err := svc.Login(ctx, "kairo", "correct-horse-battery", false, "", "")
	if err != nil {
		t.Fatal(err)
	}

	if _, err := svc.LoginTotp(ctx, res.TempToken, "000000", ""); err != ErrBadTotp {
		t.Errorf("错误动态码应返回 ErrBadTotp，实际 %v", err)
	}

	// auth.md 3.1 规则 5：失败不计数，记录保留
	var pending int
	if err := svc.db.QueryRow(`SELECT count(*) FROM pending_logins`).Scan(&pending); err != nil {
		t.Fatal(err)
	}
	if pending != 1 {
		t.Error("动态码错误时 pending_logins 应保留以便重试")
	}
}

func TestServiceLoginExpiredPending(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	createTestUser(t, svc, "kairo", "correct-horse-battery", true)

	res, err := svc.Login(ctx, "kairo", "correct-horse-battery", false, "", "")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.db.Exec(`UPDATE pending_logins SET expires_at = now() - interval '1 second'`); err != nil {
		t.Fatal(err)
	}

	if _, err := svc.LoginTotp(ctx, res.TempToken, "123456", ""); err != ErrPendingExpired {
		t.Errorf("过期临时 token 应返回 ErrPendingExpired，实际 %v", err)
	}
}

func TestServiceTrustedDeviceSkipsTotp(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", true)
	secret := totpSecretOf(t, svc, userID)

	// 先正常走两步，拿到授信设备
	res, err := svc.Login(ctx, "kairo", "correct-horse-battery", true, "", "")
	if err != nil {
		t.Fatal(err)
	}
	code, _ := GenerateTotpCode(secret, time.Now())
	final, err := svc.LoginTotp(ctx, res.TempToken, code, "")
	if err != nil {
		t.Fatal(err)
	}

	// 再登录：带授信设备 cookie，应直接完成
	second, err := svc.Login(ctx, "kairo", "correct-horse-battery", false, final.DeviceToken, "")
	if err != nil {
		t.Fatalf("带授信设备登录失败: %v", err)
	}
	if second.TotpRequired {
		t.Error("授信设备有效时不应要求 TOTP")
	}
	if second.AuditVia != auditViaTrustedDevice {
		t.Errorf("审计 via = %q", second.AuditVia)
	}

	// 授信设备不免密
	if _, err := svc.Login(ctx, "kairo", "wrong", false, final.DeviceToken, ""); err != ErrInvalidCredentials {
		t.Errorf("授信设备不应免除密码，实际 %v", err)
	}
}

func TestServiceTotpSetupVerifyDisable(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", false)

	secret, uri, err := svc.SetupTotp(userID, "Haven")
	if err != nil {
		t.Fatalf("SetupTotp 返回错误: %v", err)
	}
	if secret == "" || uri == "" {
		t.Fatal("应返回 secret 与 otpauth URI")
	}
	// api.md 2.4：secret 此时未落库
	if got := totpSecretOf(t, svc, userID); got != "" {
		t.Errorf("setup 阶段不应落库，实际 %q", got)
	}

	code, _ := GenerateTotpCode(secret, time.Now())

	// 错误码
	if err := svc.VerifyTotp(ctx, userID, secret, "000000"); err != ErrBadTotp {
		t.Errorf("错误动态码应返回 ErrBadTotp，实际 %v", err)
	}

	if err := svc.VerifyTotp(ctx, userID, secret, code); err != nil {
		t.Fatalf("VerifyTotp 返回错误: %v", err)
	}
	if got := totpSecretOf(t, svc, userID); got != secret {
		t.Errorf("verify 后应落库，期望 %q，实际 %q", secret, got)
	}

	// 已启用时重复 setup 应 409
	if _, _, err := svc.SetupTotp(userID, "Haven"); err != ErrTotpAlreadyEnabled {
		t.Errorf("重复 setup 应返回 ErrTotpAlreadyEnabled，实际 %v", err)
	}

	// 加一台授信设备，disable 时应被删除
	if _, err := svc.db.Exec(
		`INSERT INTO trusted_devices (user_id, token_hash, device_name, expires_at, last_used_at)
		 VALUES ($1, 'devhash', 'test', now() + interval '30 days', now())`, userID); err != nil {
		t.Fatal(err)
	}

	if err := svc.DisableTotp(ctx, userID, code); err != nil {
		t.Fatalf("DisableTotp 返回错误: %v", err)
	}

	var devices int
	if err := svc.db.QueryRow(`SELECT count(*) FROM trusted_devices WHERE user_id = $1`, userID).Scan(&devices); err != nil {
		t.Fatal(err)
	}
	if devices != 0 {
		t.Error("关闭 TOTP 应删除全部授信设备")
	}
	if got := totpSecretOf(t, svc, userID); got != "" {
		t.Error("关闭 TOTP 应清空 totp_secret")
	}
}

func TestServiceChangePasswordCascade(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", true)
	secret := totpSecretOf(t, svc, userID)

	// 造两条会话、一台授信设备、一个 Token
	for i := 0; i < 2; i++ {
		if _, err := svc.db.Exec(
			`INSERT INTO sessions (user_id, token_hash, expires_at, last_used_at)
			 VALUES ($1, $2, now() + interval '7 days', now())`, userID, HashToken("sess"+string(rune('a'+i)))); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := svc.db.Exec(
		`INSERT INTO trusted_devices (user_id, token_hash, device_name, expires_at, last_used_at)
		 VALUES ($1, 'devhash', 'x', now() + interval '30 days', now())`, userID); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.db.Exec(
		`INSERT INTO tokens (user_id, name, token_hash, token_prefix, scope)
		 VALUES ($1, 'cli', 'tokhash', 'haven_ro', 'read')`, userID); err != nil {
		t.Fatal(err)
	}

	code, _ := GenerateTotpCode(secret, time.Now())
	if err := svc.ChangePassword(ctx, userID, "correct-horse-battery", "brand-new-password", code); err != nil {
		t.Fatalf("ChangePassword 返回错误: %v", err)
	}

	var sessions, devices, tokens int
	if err := svc.db.QueryRow(`SELECT count(*) FROM sessions WHERE user_id = $1`, userID).Scan(&sessions); err != nil {
		t.Fatal(err)
	}
	if err := svc.db.QueryRow(`SELECT count(*) FROM trusted_devices WHERE user_id = $1`, userID).Scan(&devices); err != nil {
		t.Fatal(err)
	}
	if err := svc.db.QueryRow(`SELECT count(*) FROM tokens WHERE user_id = $1`, userID).Scan(&tokens); err != nil {
		t.Fatal(err)
	}

	if sessions != 0 {
		t.Error("改密后应删除全部会话")
	}
	if devices != 0 {
		t.Error("改密后应删除全部授信设备")
	}
	if tokens != 1 {
		t.Error("改密不应删除 Token（auth.md 8.3）")
	}

	// 新密码可用，旧密码失效
	if _, err := svc.Login(ctx, "kairo", "brand-new-password", false, "", ""); err != nil {
		t.Errorf("新密码应能登录: %v", err)
	}
	if _, err := svc.Login(ctx, "kairo", "correct-horse-battery", false, "", ""); err != ErrInvalidCredentials {
		t.Error("旧密码应失效")
	}
}

func TestServiceChangePasswordValidation(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", false)

	if err := svc.ChangePassword(ctx, userID, "correct-horse-battery", "short", ""); err == nil {
		t.Error("过短的新密码应报错")
	}
	if err := svc.ChangePassword(ctx, userID, "wrong-old", "brand-new-password", ""); err != ErrInvalidCredentials {
		t.Errorf("原密码错误应返回 ErrInvalidCredentials，实际 %v", err)
	}
	if err := svc.ChangePassword(ctx, userID, "correct-horse-battery", "correct-horse-battery", ""); err == nil {
		t.Error("新密码与旧密码相同应报错")
	}
}

func TestServiceLogout(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", false)

	res, err := svc.Login(ctx, "kairo", "correct-horse-battery", false, "", "")
	if err != nil {
		t.Fatal(err)
	}

	var sessionID string
	if err := svc.db.QueryRow(`SELECT id FROM sessions WHERE user_id = $1`, userID).Scan(&sessionID); err != nil {
		t.Fatal(err)
	}

	if err := svc.Logout(ctx, sessionID); err != nil {
		t.Fatalf("Logout 返回错误: %v", err)
	}

	var count int
	if err := svc.db.QueryRow(`SELECT count(*) FROM sessions WHERE user_id = $1`, userID).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 0 {
		t.Error("登出应删除会话")
	}

	// 会话凭证不再可用
	if _, err := NewSQLStore(svc.db).FindSessionByHash(ctx, HashToken(res.SessionToken)); err != ErrNotFound {
		t.Errorf("登出后的会话应查不到，实际 %v", err)
	}
}

func TestSQLStoreSessionExpiry(t *testing.T) {
	svc := newSchemaService(t)
	ctx := context.Background()
	userID := createTestUser(t, svc, "kairo", "correct-horse-battery", false)

	store := NewSQLStore(svc.db)
	token, _ := newSessionToken()

	if _, err := svc.db.Exec(
		`INSERT INTO sessions (user_id, token_hash, expires_at, last_used_at)
		 VALUES ($1, $2, now() - interval '1 second', now())`, userID, HashToken(token)); err != nil {
		t.Fatal(err)
	}

	if _, err := store.FindSessionByHash(ctx, HashToken(token)); err != ErrNotFound {
		t.Errorf("过期会话应查不到，实际 %v", err)
	}
}

func tableColumns(svc *Service, table string) ([]string, error) {
	rows, err := svc.db.Query(
		`SELECT column_name FROM information_schema.columns
		 WHERE table_name = $1 AND table_schema = current_schema()
		 ORDER BY ordinal_position`,
		table)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []string
	for rows.Next() {
		var c string
		if err := rows.Scan(&c); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}
