package auth

import (
	"strings"
	"testing"
	"time"
)

func TestHashPassword(t *testing.T) {
	hash, err := HashPassword("correct-horse-battery")
	if err != nil {
		t.Fatalf("HashPassword 返回错误: %v", err)
	}
	if !strings.HasPrefix(hash, "$2a$12$") {
		t.Errorf("应为 bcrypt cost 12 哈希，实际 %q", hash)
	}
	if !passwordMatches(hash, "correct-horse-battery") {
		t.Error("正确密码应校验通过")
	}
	if passwordMatches(hash, "wrong-password") {
		t.Error("错误密码不应通过")
	}
}

func TestValidatePassword(t *testing.T) {
	cases := []struct {
		name    string
		newPw   string
		oldPw   string
		wantErr bool
	}{
		{name: "太短", newPw: "short", oldPw: "x", wantErr: true},
		{name: "刚好12位", newPw: "123456789012", oldPw: "old", wantErr: false},
		{name: "与旧密码相同", newPw: "123456789012", oldPw: "123456789012", wantErr: true},
		{name: "中文12字", newPw: "密码密码密码密码密码密码", oldPw: "old", wantErr: false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidatePassword(tc.newPw, tc.oldPw)
			if tc.wantErr && err == nil {
				t.Error("应返回错误")
			}
			if !tc.wantErr && err != nil {
				t.Errorf("不应返回错误: %v", err)
			}
		})
	}
}

func TestNewTotpSecret(t *testing.T) {
	secret, uri, err := NewTotpSecret("Haven", "kairo")
	if err != nil {
		t.Fatalf("NewTotpSecret 返回错误: %v", err)
	}
	if len(secret) != 32 {
		t.Errorf("20 字节 base32 无填充应为 32 字符，实际 %d (%q)", len(secret), secret)
	}
	if strings.Contains(secret, "=") {
		t.Errorf("secret 不应含 padding: %q", secret)
	}
	for _, want := range []string{
		"otpauth://totp/Haven:kairo",
		"secret=" + secret,
		"issuer=Haven",
		"digits=6",
		"period=30",
	} {
		if !strings.Contains(uri, want) {
			t.Errorf("otpauth URI 缺少 %q: %s", want, uri)
		}
	}
}

// RFC 6238 附录 B 的 SHA1 测试向量（secret 为 "12345678901234567890"）。
func TestTotpRFC6238Vectors(t *testing.T) {
	// base32("12345678901234567890")
	const secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"

	cases := []struct {
		unix int64
		want string
	}{
		{unix: 59, want: "287082"},
		{unix: 1111111109, want: "081804"},
		{unix: 1111111111, want: "050471"},
		{unix: 1234567890, want: "005924"},
		{unix: 2000000000, want: "279037"},
	}

	for _, tc := range cases {
		at := time.Unix(tc.unix, 0).UTC()
		if !TotpValid(secret, tc.want, at) {
			t.Errorf("TOTP(%d) 应校验通过 %s", tc.unix, tc.want)
		}
		code, err := GenerateTotpCode(secret, at)
		if err != nil {
			t.Fatalf("GenerateTotpCode 返回错误: %v", err)
		}
		if code != tc.want {
			t.Errorf("GenerateTotpCode(%d) = %s，期望 %s", tc.unix, code, tc.want)
		}
	}
}

func TestTotpSkewWindow(t *testing.T) {
	const secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
	base := time.Unix(1111111109, 0).UTC()

	prev, _ := GenerateTotpCode(secret, base.Add(-totpPeriod))
	next, _ := GenerateTotpCode(secret, base.Add(totpPeriod))
	far, _ := GenerateTotpCode(secret, base.Add(5*totpPeriod))

	if !TotpValid(secret, prev, base) {
		t.Error("上一个时间窗的码应通过（容忍漂移）")
	}
	if !TotpValid(secret, next, base) {
		t.Error("下一个时间窗的码应通过（容忍漂移）")
	}
	if TotpValid(secret, far, base) {
		t.Error("超出漂移窗口的码不应通过")
	}
}

func TestTotpInvalidInputs(t *testing.T) {
	const secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
	now := time.Now()

	cases := []struct{ name, secret, code string }{
		{name: "码太短", secret: secret, code: "12345"},
		{name: "码太长", secret: secret, code: "1234567"},
		{name: "非数字", secret: secret, code: "abcdef"},
		{name: "空 secret", secret: "", code: "123456"},
		{name: "非法 base32", secret: "!!!!", code: "123456"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if TotpValid(tc.secret, tc.code, now) {
				t.Error("非法输入不应通过")
			}
		})
	}

	// 前后空白应被容忍
	code, _ := GenerateTotpCode(secret, now)
	if !TotpValid(secret, " "+code+" ", now) {
		t.Error("码前后空白应被裁剪")
	}
}

func TestCookieConstants(t *testing.T) {
	// 这些是文档规定的常量，改动需要先改 docs（architecture.md 第四节）
	if CookieSession != "haven_session" {
		t.Errorf("会话 cookie 名 = %q", CookieSession)
	}
	if CookieTrustedDevice != "haven_trusted_device" {
		t.Errorf("授信设备 cookie 名 = %q", CookieTrustedDevice)
	}
	if SessionTTL != 7*24*time.Hour {
		t.Errorf("会话有效期 = %v", SessionTTL)
	}
	if TrustedDeviceTTL != 30*24*time.Hour {
		t.Errorf("授信设备有效期 = %v", TrustedDeviceTTL)
	}
	if PendingLoginTTL != 5*time.Minute {
		t.Errorf("待验证登录有效期 = %v", PendingLoginTTL)
	}
	if BcryptCost != 12 {
		t.Errorf("bcrypt cost = %d", BcryptCost)
	}
}
