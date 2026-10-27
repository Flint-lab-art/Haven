package auth

import (
	"errors"
	"time"

	"github.com/gin-gonic/gin"
)

// 可见性过滤条件（auth.md 6.3）。
//
// 所有读接口必须使用这里算出的条件，不得各自拼 visibility 判断
// （conventions.md 第四节、auth.md 6.3）。
const (
	// VisibilityPublic 是「公开可见」的唯一判定条件。
	VisibilityPublic = `visibility = 'public' AND published_at IS NOT NULL`

	// VisibilityOwnedOrPublic 供已登录用户使用：自己的 OR 公开。
	// 使用方需把 $1 绑定为当前用户 id。
	VisibilityOwnedOrPublic = `(user_id = $1) OR (` + VisibilityPublic + `)`
)

// 注入 *gin.Context 的键。
const (
	ctxKeyIdentity   = "identity"
	ctxKeyVisibility = "visibility"
)

// Visibility 是中间件算出的数据可见性条件。
//
// Condition 是可直接拼进 WHERE 的 SQL 片段，Args 是对应的参数。
// 私有读与写操作在此基础上还要叠加 user_id 过滤（auth.md 6.4）。
type Visibility struct {
	// Condition 为空的含义是「不可见任何数据」，调用方应直接返回空列表或 404。
	Condition string
	Args      []any
}

// Visibility 从 gin context 取出可见性条件。
func CurrentVisibility(c *gin.Context) Visibility {
	if v, ok := c.Get(ctxKeyVisibility); ok {
		if vis, ok := v.(Visibility); ok {
			return vis
		}
	}
	return Visibility{}
}

// CurrentIdentity 从 gin context 取出身份，缺失时视为匿名。
func CurrentIdentity(c *gin.Context) Identity {
	if v, ok := c.Get(ctxKeyIdentity); ok {
		if id, ok := v.(Identity); ok {
			return id
		}
	}
	return Identity{Kind: Anonymous}
}

// visibilityFor 按身份计算可见性条件（auth.md 6.3）。
func visibilityFor(id Identity) Visibility {
	if !id.IsLoggedIn() {
		return Visibility{Condition: VisibilityPublic}
	}
	return Visibility{
		Condition: VisibilityOwnedOrPublic,
		Args:      []any{id.UserID},
	}
}

// Authenticate 是身份识别中间件（auth.md 6.1）。
//
// 顺序：
//  1. Authorization: Bearer 优先于 cookie，Token 匹配失败直接 401；
//  2. 否则查会话 cookie；会话无效视为未登录，继续往后走；
//  3. 否则匿名。
//
// 本中间件只识别身份并注入 context，不做接口级权限判定，
// 权限由 RequireLogin / RequireWrite / RequireTotpVerified 负责（auth.md 6.2）。
func Authenticate(store Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		identity := Identity{Kind: Anonymous}

		if raw := bearerToken(c); raw != "" {
			tok, err := store.FindTokenByHash(ctx, HashToken(raw))
			switch {
			case errors.Is(err, ErrNotFound):
				// Token 无效：直接拒绝，不退回 cookie 身份（auth.md 6.1 第 1 步）
				abortUnauthorized(c)
				return
			case err != nil:
				abortInternal(c, err)
				return
			}
			if !tokenUsable(tok, time.Now()) {
				abortUnauthorized(c)
				return
			}
			identity = Identity{Kind: TokenUser, UserID: tok.UserID, Scope: tok.Scope}
			// 刷新使用时间属于尽力而为，失败不影响请求
			_ = store.TouchToken(ctx, tok.ID, time.Now())
			c.Set(ctxKeyTokenID, tok.ID)
		} else {
			// gin 的 Context.Cookie 返回 (string, error)：err 非空表示没有该 cookie
			raw, cookieErr := c.Cookie(CookieSession)
			if cookieErr == nil && raw != "" {
				// 会话 token 可能带 TOTP 标记，必须先剥离再哈希（见 session_token.go）
				base, totpVerified := splitSessionToken(raw)
				sess, loadErr := store.FindSessionByHash(ctx, HashToken(base))
				switch {
				case errors.Is(loadErr, ErrNotFound):
					// 会话无效：视为未登录（auth.md 6.1 第 2 步）
				case loadErr != nil:
					abortInternal(c, loadErr)
					return
				default:
					identity = Identity{
						Kind:         SessionUser,
						UserID:       sess.UserID,
						TotpVerified: totpVerified,
					}
					_ = store.TouchSession(ctx, sess.ID, time.Now())
					// 会话 id 需注入 context：撤销当前会话、标记 is_current 与登出都依赖它
					c.Set(ctxKeySessionID, sess.ID)
				}
			}
		}

		c.Set(ctxKeyIdentity, identity)
		c.Set(ctxKeyVisibility, visibilityFor(identity))
		c.Next()
	}
}

// RequireLogin 要求已登录（会话或任意 Token），否则 401（auth.md 6.2）。
func RequireLogin() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !CurrentIdentity(c).IsLoggedIn() {
			abortUnauthorized(c)
			return
		}
		c.Next()
	}
}

// RequireWrite 要求写权限：会话，或 scope = read_write 的 Token；
// read Token 返回 403（auth.md 6.2）。
func RequireWrite() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := CurrentIdentity(c)
		if !id.IsLoggedIn() {
			abortUnauthorized(c)
			return
		}
		if id.Kind == TokenUser && id.Scope != ScopeReadWrite {
			abortForbidden(c)
			return
		}
		c.Next()
	}
}

// RequireTotpVerified 要求会话在创建时通过过 TOTP。
// Token 一律 403；会话未通过 TOTP 也 403（auth.md 6.2、api.md 1.6）。
func RequireTotpVerified() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := CurrentIdentity(c)
		if !id.IsLoggedIn() {
			abortUnauthorized(c)
			return
		}
		if id.Kind != SessionUser || !id.TotpVerified {
			abortForbidden(c)
			return
		}
		c.Next()
	}
}

// RequireSession 要求调用方是会话身份，Token 一律 403。
//
// 凭证类资源（会话 / 授信设备 / Token / TOTP / 密码）只允许 Web 会话操作
// （auth.md 第七节说明；api.md 三、四、五节各接口的「Token 调用返回 403」）。
func RequireSession() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := CurrentIdentity(c)
		if !id.IsLoggedIn() {
			abortUnauthorized(c)
			return
		}
		if id.Kind != SessionUser {
			abortForbidden(c)
			return
		}
		c.Next()
	}
}

// bearerToken 取出 Authorization: Bearer 的值；格式不对视为未提供。
func bearerToken(c *gin.Context) string {
	header := c.GetHeader("Authorization")
	const prefix = "Bearer "
	if len(header) <= len(prefix) || header[:len(prefix)] != prefix {
		return ""
	}
	return header[len(prefix):]
}

// tokenUsable 判断 Token 是否可用于鉴权（auth.md 6.1）：
// 未撤销且未过期。
func tokenUsable(t APIToken, now time.Time) bool {
	if t.RevokedAt != nil {
		return false
	}
	if t.ExpiresAt != nil && !t.ExpiresAt.After(now) {
		return false
	}
	return true
}

// abortUnauthorized / abortForbidden / abortInternal 走统一错误响应。
// 具体响应构造函数在 internal/httpx，这里通过注册的回调解耦，避免包循环。
var (
	unauthorizedHandler = defaultAbort(401, "unauthorized", "未登录或凭证无效")
	forbiddenHandler    = defaultAbort(403, "forbidden", "权限不足")
	internalHandler     = defaultAbort(500, "internal_error", "服务端错误")
)

// SetErrorHandlers 注入统一错误响应（由 internal/httpx 在启动时调用）。
func SetErrorHandlers(unauthorized, forbidden, internal func(c *gin.Context, err error)) {
	if unauthorized != nil {
		unauthorizedHandler = func(c *gin.Context, err error) { unauthorized(c, err) }
	}
	if forbidden != nil {
		forbiddenHandler = func(c *gin.Context, err error) { forbidden(c, err) }
	}
	if internal != nil {
		internalHandler = func(c *gin.Context, err error) { internal(c, err) }
	}
}

func abortUnauthorized(c *gin.Context)        { unauthorizedHandler(c, nil) }
func abortForbidden(c *gin.Context)           { forbiddenHandler(c, nil) }
func abortInternal(c *gin.Context, err error) { internalHandler(c, err) }

func defaultAbort(status int, code, msg string) func(*gin.Context, error) {
	return func(c *gin.Context, _ error) {
		c.AbortWithStatusJSON(status, gin.H{"error": code, "message": msg})
	}
}
