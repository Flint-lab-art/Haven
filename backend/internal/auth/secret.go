package auth

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha1"
	"encoding/base32"
	"encoding/binary"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// 密码与 TOTP 的编解码与校验。依据 docs/backend/auth.md 第八节。
//
//   - 密码用 bcrypt，cost 固定 12；
//   - TOTP 按 RFC 6238（HMAC-SHA1、6 位、30 秒步长），secret 明文存储（auth.md 8.2）；
//   - 校验允许前后各一个时间窗，容忍轻微时钟漂移；这不改变 30 秒的有效期语义。

const (
	totpDigits = 6
	totpPeriod = 30 * time.Second
	// totpSkew 允许的时间窗漂移，单位：步长。1 表示接受上一个和下一个 30 秒窗口。
	totpSkew = 1
)

// MinPasswordLen 见 docs/api.md 2.7（已定义在 consts.go）。

// 审计用的登录途径（audit.md 第三节 login_success 的 metadata.via）。
const (
	auditViaTotp          = "password+totp"
	auditViaTrustedDevice = "password+trusted_device"
)

// HashPassword 用 bcrypt 生成密码哈希，cost 固定 12（auth.md 8.1）。
func HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), BcryptCost)
	if err != nil {
		return "", fmt.Errorf("生成密码哈希失败: %w", err)
	}
	return string(hash), nil
}

// passwordMatches 用恒定时间比较校验密码。
func passwordMatches(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

// ErrPasswordTooShort / ErrPasswordSameAsOld 是密码策略错误，
// handler 层据此返回 422 validation_failed（api.md 2.7）。
var (
	ErrPasswordTooShort  = fmt.Errorf("新密码至少 %d 位", MinPasswordLen)
	ErrPasswordSameAsOld = errors.New("新密码不能与旧密码相同")
)

// ValidatePassword 校验新密码：至少 MinPasswordLen 位，且不能与旧密码相同（api.md 2.7）。
func ValidatePassword(newPassword, oldPassword string) error {
	if len([]rune(newPassword)) < MinPasswordLen {
		return ErrPasswordTooShort
	}
	if newPassword == oldPassword {
		return ErrPasswordSameAsOld
	}
	return nil
}

// IsPasswordPolicyError 判断错误是否属于密码策略问题（应返回 422）。
func IsPasswordPolicyError(err error) bool {
	return errors.Is(err, ErrPasswordTooShort) || errors.Is(err, ErrPasswordSameAsOld)
}

// NewTotpSecret 生成新的 TOTP 密钥（base32 无填充，20 字节 = 160 位，RFC 4226 推荐长度），
// 并返回可被验证器扫描的 otpauth URI（api.md 2.4）。
func NewTotpSecret(issuer, username string) (secret, uri string, err error) {
	buf := make([]byte, 20)
	if _, err := rand.Read(buf); err != nil {
		return "", "", fmt.Errorf("生成 TOTP 密钥失败: %w", err)
	}

	secret = base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(buf)

	// otpauth://totp/<issuer>:<username>?secret=...&issuer=<issuer>
	label := url.PathEscape(issuer + ":" + username)
	q := url.Values{}
	q.Set("secret", secret)
	q.Set("issuer", issuer)
	q.Set("algorithm", "SHA1")
	q.Set("digits", fmt.Sprint(totpDigits))
	q.Set("period", fmt.Sprint(int(totpPeriod.Seconds())))

	return secret, "otpauth://totp/" + label + "?" + q.Encode(), nil
}

// TotpValid 校验 6 位动态码，允许 totpSkew 个步长的时间漂移。
func TotpValid(secret, code string, now time.Time) bool {
	code = strings.TrimSpace(code)
	if len(code) != totpDigits {
		return false
	}
	if secret == "" {
		return false
	}

	key, err := base32.StdEncoding.WithPadding(base32.NoPadding).DecodeString(strings.ToUpper(secret))
	if err != nil {
		return false
	}

	counter := now.Unix() / int64(totpPeriod.Seconds())
	for offset := -int64(totpSkew); offset <= int64(totpSkew); offset++ {
		want, err := hotp(key, uint64(counter+offset))
		if err != nil {
			return false
		}
		// 恒定时间比较，避免通过耗时差异逐位猜码
		if secureEqual(want, code) {
			return true
		}
	}
	return false
}

// hotp 按 RFC 4226 计算 HOTP 值，格式化为 6 位十进制字符串。
func hotp(key []byte, counter uint64) (string, error) {
	var buf [8]byte
	binary.BigEndian.PutUint64(buf[:], counter)

	mac := hmac.New(sha1.New, key)
	if _, err := mac.Write(buf[:]); err != nil {
		return "", fmt.Errorf("计算 TOTP 失败: %w", err)
	}
	sum := mac.Sum(nil)

	// 动态截断（RFC 4226 5.3）
	offset := sum[len(sum)-1] & 0x0f
	value := binary.BigEndian.Uint32(sum[offset:offset+4]) & 0x7fffffff

	return fmt.Sprintf("%0*d", totpDigits, value%1_000_000), nil
}

// GenerateTotpCode 生成指定时刻的动态码，仅供测试与本地调试使用。
func GenerateTotpCode(secret string, at time.Time) (string, error) {
	key, err := base32.StdEncoding.WithPadding(base32.NoPadding).DecodeString(strings.ToUpper(secret))
	if err != nil {
		return "", fmt.Errorf("解码 TOTP 密钥失败: %w", err)
	}
	return hotp(key, uint64(at.Unix()/int64(totpPeriod.Seconds())))
}
