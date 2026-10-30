package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"strings"
)

// 凭证生成与哈希工具。
//
// 依据 docs/backend/auth.md：
//   - 会话 / 授信设备 / 临时登录 token 都是「随机 32 字节，base64url 编码后下发，
//     数据库只存 SHA-256 哈希」（auth.md 第三节规则 1、3.1 规则 1、第四节规则 1）；
//   - API Token 格式为 haven_<scope>_<32字节随机串base64url>，同样只存哈希，
//     另存明文前 8 位 token_prefix 用于展示（auth.md 第五节规则 2、3）。
//
// 注意：token_prefix 是明文前缀，不是哈希。它的唯一用途是设置页展示，
// 鉴权时必须查 token_hash，不解析前缀（auth.md 第五节规则 2）。

// tokenBytes 是各类 token 的随机字节数，固定 32。
const tokenBytes = 32

// tokenPrefixLen 是 tokens.token_prefix 的长度，即明文前 8 位。
const tokenPrefixLen = 8

// 固定前缀段，便于用户和日志识别 token 类型（不含敏感信息）。
const (
	sessionTokenPrefix   = "haven_sess_"
	deviceTokenPrefix    = "haven_dev_"
	pendingTokenPrefix   = "haven_pend_"
	apiTokenReadPrefix   = "haven_ro_"
	apiTokenWritePrefix  = "haven_rw_"
	pendingTrustSuffixOn = ":1"
)

// randomToken 生成 base64url 编码的随机串（32 字节）。
func randomToken() (string, error) {
	buf := make([]byte, tokenBytes)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("生成随机 token 失败: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

// newSessionToken 生成会话 token 明文。调用方只把明文写进 cookie，库里存 HashToken 结果。
func newSessionToken() (string, error) {
	tok, err := randomToken()
	if err != nil {
		return "", err
	}
	return sessionTokenPrefix + tok, nil
}

// newDeviceToken 生成授信设备 token 明文（cookie haven_trusted_device）。
func newDeviceToken() (string, error) {
	tok, err := randomToken()
	if err != nil {
		return "", err
	}
	return deviceTokenPrefix + tok, nil
}

// newPendingToken 生成待验证登录的临时 token 明文。
//
// trustDevice 表示第一步登录请求里的 trust_device。按 auth.md 3.1 规则 1，
// 该标记拼接在明文末尾（如 <随机串>:1），不单独落库；校验时先剥离后缀再哈希。
// 注意 suffix 必须在哈希之前剥离，所以临时 token 的哈希覆盖的是**去掉后缀后的值**。
func newPendingToken(trustDevice bool) (string, error) {
	tok, err := randomToken()
	if err != nil {
		return "", err
	}
	out := pendingTokenPrefix + tok
	if trustDevice {
		out += pendingTrustSuffixOn
	}
	return out, nil
}

// splitPendingToken 剥离临时 token 末尾的 trust_device 标记，
// 返回「用于哈希的原始值」与「是否请求授信设备」。
//
// 对不含后缀的值原样返回，trustDevice 为 false。这样即便调用方传入已剥离过的值也安全。
func splitPendingToken(plain string) (token string, trustDevice bool) {
	if strings.HasSuffix(plain, pendingTrustSuffixOn) {
		return strings.TrimSuffix(plain, pendingTrustSuffixOn), true
	}
	return plain, false
}

// newAPIToken 按 scope 生成 API Token 明文，并返回展示用的前缀。
//
// scope 只允许 read / read_write，其余取值由调用方的校验层拦截（返回 422）。
func newAPIToken(scope string) (token string, prefix string, err error) {
	var p string
	switch scope {
	case "read":
		p = apiTokenReadPrefix
	case "read_write":
		p = apiTokenWritePrefix
	default:
		return "", "", fmt.Errorf("非法的 token scope %q", scope)
	}

	tok, err := randomToken()
	if err != nil {
		return "", "", err
	}
	token = p + tok
	return token, truncatePrefix(token), nil
}

// truncatePrefix 取明文前 tokenPrefixLen 个字节作为展示前缀。
//
// 前缀段本身都是 ASCII，且长度固定，因此按字节截断不会切坏多字节字符。
func truncatePrefix(token string) string {
	if len(token) <= tokenPrefixLen {
		return token
	}
	return token[:tokenPrefixLen]
}

// HashToken 计算 token 的 SHA-256 哈希（小写十六进制），用于落库与按 token_hash 查询。
//
// 对临时 token，调用方必须先经 splitPendingToken 剥离 trust_device 后缀再哈希。
func HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

// secureEqual 用恒定时间比较两个字符串，避免通过耗时差异推断内容。
func secureEqual(a, b string) bool {
	return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}
