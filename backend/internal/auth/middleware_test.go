package auth

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func init() { gin.SetMode(gin.TestMode) }

func newTestRouter(store Store) *gin.Engine {
	r := gin.New()
	r.Use(Authenticate(store))

	r.GET("/whoami", func(c *gin.Context) {
		id := CurrentIdentity(c)
		c.JSON(http.StatusOK, gin.H{
			"kind":          id.String(),
			"user_id":       id.UserID,
			"scope":         id.Scope,
			"totp_verified": id.TotpVerified,
		})
	})
	return r
}

func do(r *gin.Engine, req *http.Request) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w
}

func TestAuthenticateAnonymous(t *testing.T) {
	store := newFakeStore()
	r := newTestRouter(store)

	w := do(r, httptest.NewRequest(http.MethodGet, "/whoami", nil))
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	if body := w.Body.String(); body != `{"kind":"anonymous","scope":"","totp_verified":false,"user_id":""}` {
		t.Errorf("匿名身份响应异常: %s", body)
	}
}

func TestAuthenticateSession(t *testing.T) {
	store := newFakeStore()
	plain, _ := newSessionToken()
	store.sessions[HashToken(plain)] = Session{
		ID: "sess-1", UserID: "user-1", ExpiresAt: time.Now().Add(time.Hour),
	}

	r := newTestRouter(store)
	req := httptest.NewRequest(http.MethodGet, "/whoami", nil)
	req.AddCookie(&http.Cookie{Name: CookieSession, Value: plain})

	w := do(r, req)
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	if len(store.touchedSessions) != 1 || store.touchedSessions[0] != "sess-1" {
		t.Error("有效会话应刷新 last_used_at")
	}
}

func TestAuthenticateInvalidSessionIsAnonymous(t *testing.T) {
	store := newFakeStore()
	r := newTestRouter(store)

	req := httptest.NewRequest(http.MethodGet, "/whoami", nil)
	req.AddCookie(&http.Cookie{Name: CookieSession, Value: "garbage"})

	w := do(r, req)
	if w.Code != http.StatusOK {
		t.Fatalf("无效会话应视为匿名，状态码 = %d", w.Code)
	}
	if got := w.Body.String(); got != `{"kind":"anonymous","scope":"","totp_verified":false,"user_id":""}` {
		t.Errorf("无效会话应降级为匿名: %s", got)
	}
}

func TestAuthenticateToken(t *testing.T) {
	store := newFakeStore()
	plain, _, _ := newAPIToken(ScopeRead)
	store.tokens[HashToken(plain)] = APIToken{
		ID: "tok-1", UserID: "user-1", Scope: ScopeRead,
	}

	r := newTestRouter(store)
	req := httptest.NewRequest(http.MethodGet, "/whoami", nil)
	req.Header.Set("Authorization", "Bearer "+plain)

	w := do(r, req)
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	if len(store.touchedTokens) != 1 {
		t.Error("有效 Token 应刷新 last_used_at")
	}
}

func TestAuthenticateRevokedOrExpiredToken(t *testing.T) {
	past := time.Now().Add(-time.Hour)
	future := time.Now().Add(time.Hour)

	cases := []struct {
		name  string
		token APIToken
	}{
		{name: "已撤销", token: APIToken{RevokedAt: &past}},
		{name: "已过期", token: APIToken{ExpiresAt: &past}},
		{name: "撤销时间为零值以外", token: APIToken{ExpiresAt: &future, RevokedAt: &past}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			store := newFakeStore()
			plain, _, _ := newAPIToken(ScopeRead)
			tc.token.ID, tc.token.UserID, tc.token.Scope = "tok-1", "user-1", ScopeRead
			store.tokens[HashToken(plain)] = tc.token

			r := newTestRouter(store)
			req := httptest.NewRequest(http.MethodGet, "/whoami", nil)
			req.Header.Set("Authorization", "Bearer "+plain)

			w := do(r, req)
			if w.Code != http.StatusUnauthorized {
				t.Errorf("状态码 = %d，期望 401", w.Code)
			}
		})
	}
}

func TestAuthenticateInvalidTokenDoesNotFallbackToCookie(t *testing.T) {
	store := newFakeStore()
	sessToken, _ := newSessionToken()
	store.sessions[HashToken(sessToken)] = Session{ID: "sess-1", UserID: "user-1"}

	r := newTestRouter(store)
	req := httptest.NewRequest(http.MethodGet, "/whoami", nil)
	req.Header.Set("Authorization", "Bearer bogus")
	req.AddCookie(&http.Cookie{Name: CookieSession, Value: sessToken})

	w := do(r, req)
	// auth.md 6.1：Token 匹配失败返回 401，不退回 cookie
	if w.Code != http.StatusUnauthorized {
		t.Errorf("非法 Bearer 应立即 401，实际 %d", w.Code)
	}
}

func TestBearerOverridesCookie(t *testing.T) {
	store := newFakeStore()
	sessToken, _ := newSessionToken()
	store.sessions[HashToken(sessToken)] = Session{ID: "sess-1", UserID: "session-user"}
	token, _, _ := newAPIToken(ScopeReadWrite)
	store.tokens[HashToken(token)] = APIToken{ID: "tok-1", UserID: "token-user", Scope: ScopeReadWrite}

	r := newTestRouter(store)
	req := httptest.NewRequest(http.MethodGet, "/whoami", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	req.AddCookie(&http.Cookie{Name: CookieSession, Value: sessToken})

	w := do(r, req)
	if got := w.Body.String(); !contains(got, `"user_id":"token-user"`) || !contains(got, `"kind":"token"`) {
		t.Errorf("Bearer 应优先于 cookie: %s", got)
	}
}

func contains(s, sub string) bool {
	return len(s) >= len(sub) && (s == sub || len(sub) == 0 || indexOf(s, sub) >= 0)
}

func indexOf(s, sub string) int {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return i
		}
	}
	return -1
}

func TestRequireHelpers(t *testing.T) {
	store := newFakeStore()
	// 通过过 TOTP 的会话 token 带 :totp 标记，查库时先剥离再哈希（session_token.go）
	verified, _ := newSessionTokenFor(true)
	store.sessions[HashToken(HashTokenForTest(verified))] = Session{ID: "s", UserID: "u", ExpiresAt: time.Now().Add(time.Hour)}
	notVerified, _ := newSessionToken()
	store.sessions[HashToken(notVerified)] = Session{ID: "s2", UserID: "u", TotpVerified: false, ExpiresAt: time.Now().Add(time.Hour)}
	readToken, _, _ := newAPIToken(ScopeRead)
	store.tokens[HashToken(readToken)] = APIToken{ID: "t1", UserID: "u", Scope: ScopeRead}

	newRouter := func(mw gin.HandlerFunc) *gin.Engine {
		r := gin.New()
		r.Use(Authenticate(store), mw)
		r.GET("/p", func(c *gin.Context) { c.Status(http.StatusOK) })
		return r
	}

	withCookie := func(name string) *http.Request {
		req := httptest.NewRequest(http.MethodGet, "/p", nil)
		req.AddCookie(&http.Cookie{Name: CookieSession, Value: name})
		return req
	}

	withToken := func(tok string) *http.Request {
		req := httptest.NewRequest(http.MethodGet, "/p", nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		return req
	}

	t.Run("RequireLogin", func(t *testing.T) {
		r := newRouter(RequireLogin())
		if c := do(r, httptest.NewRequest(http.MethodGet, "/p", nil)).Code; c != http.StatusUnauthorized {
			t.Errorf("匿名应 401，实际 %d", c)
		}
		if c := do(r, withCookie(verified)).Code; c != http.StatusOK {
			t.Errorf("会话应放行，实际 %d", c)
		}
		if c := do(r, withToken(readToken)).Code; c != http.StatusOK {
			t.Errorf("Token 应放行，实际 %d", c)
		}
	})

	t.Run("RequireWrite", func(t *testing.T) {
		r := newRouter(RequireWrite())
		if c := do(r, httptest.NewRequest(http.MethodGet, "/p", nil)).Code; c != http.StatusUnauthorized {
			t.Errorf("匿名应 401，实际 %d", c)
		}
		if c := do(r, withToken(readToken)).Code; c != http.StatusForbidden {
			t.Errorf("read Token 写操作应 403，实际 %d", c)
		}
		if c := do(r, withCookie(notVerified)).Code; c != http.StatusOK {
			t.Errorf("会话写操作应放行，实际 %d", c)
		}
	})

	t.Run("RequireTotpVerified", func(t *testing.T) {
		r := newRouter(RequireTotpVerified())
		if c := do(r, withCookie(notVerified)).Code; c != http.StatusForbidden {
			t.Errorf("未通过 TOTP 的会话应 403，实际 %d", c)
		}
		if c := do(r, withToken(readToken)).Code; c != http.StatusForbidden {
			t.Errorf("Token 应 403，实际 %d", c)
		}
		if c := do(r, withCookie(verified)).Code; c != http.StatusOK {
			t.Errorf("通过 TOTP 的会话应放行，实际 %d", c)
		}
	})
}

func TestVisibilityFor(t *testing.T) {
	anon := visibilityFor(Identity{Kind: Anonymous})
	if anon.Condition != VisibilityPublic || len(anon.Args) != 0 {
		t.Errorf("匿名可见性条件异常: %+v", anon)
	}

	user := visibilityFor(Identity{Kind: SessionUser, UserID: "u1"})
	if user.Condition != VisibilityOwnedOrPublic {
		t.Errorf("登录用户可见性条件异常: %+v", user)
	}
	if len(user.Args) != 1 || user.Args[0] != "u1" {
		t.Errorf("登录用户可见性参数异常: %+v", user.Args)
	}

	// Token 与会话的可见性规则相同（auth.md 6.3）
	tok := visibilityFor(Identity{Kind: TokenUser, UserID: "u1", Scope: ScopeRead})
	if tok.Condition != user.Condition {
		t.Error("Token 与 Session 的可见性条件应一致")
	}
}
