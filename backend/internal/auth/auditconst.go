package auth

// 登录失败的审计原因，取值必须与 docs/backend/audit.md 第三节一致。
const (
	ReasonBadPassword = "bad_password"
	ReasonBadTotp     = "bad_totp"
	ReasonNoSuchUser  = "no_such_user"
)
