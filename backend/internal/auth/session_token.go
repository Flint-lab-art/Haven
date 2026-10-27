package auth

// 会话的「是否通过过 TOTP」标记。
//
// docs/backend/auth.md 6.2 要求 totp_verified 表示「会话创建时通过过 TOTP」，
// 但 sessions 表（auth.md 第三节）没有该字段。为此在会话记录里串上标记：
//
//	<会话随机串>                  → 未通过 TOTP 创建
//	<会话随机串>:totp             → 通过 TOTP 创建
//
// cookie 里下发明文，数据库存剥离后缀后的 SHA-256。与 pending_logins 的
// trust_device 标记（auth.md 3.1 规则 1）是同一手法：不新增列、明文不落库。
const sessionTotpSuffix = ":totp"

// newSessionTokenFor 生成会话 token，并按需带 TOTP 标记。
func newSessionTokenFor(totpVerified bool) (string, error) {
	tok, err := newSessionToken()
	if err != nil {
		return "", err
	}
	if totpVerified {
		return tok + sessionTotpSuffix, nil
	}
	return tok, nil
}

// splitSessionToken 剥离会话 token 末尾的 TOTP 标记。
// 返回「用于哈希的原始值」与「是否通过过 TOTP」。
func splitSessionToken(plain string) (token string, totpVerified bool) {
	if len(plain) > len(sessionTotpSuffix) && plain[len(plain)-len(sessionTotpSuffix):] == sessionTotpSuffix {
		return plain[:len(plain)-len(sessionTotpSuffix)], true
	}
	return plain, false
}

// sessionLookupHash 计算会话查库用的哈希：先剥离标记，再哈希。
func sessionLookupHash(plain string) string {
	base, _ := splitSessionToken(plain)
	return HashToken(base)
}
