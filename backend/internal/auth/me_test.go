package auth

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

// newMeRouter 挂一个只读的 /me 路由，用来验证 api.md 12.1 的响应字段。
func newMeRouter(store Store) *gin.Engine {
	h := NewHandler(NewService(nil), store, "Haven", "app.example.com", false)
	r := gin.New()
	r.Use(Authenticate(store))
	r.GET("/me", h.Me)
	return r
}

func TestMeAnonymous(t *testing.T) {
	r := newMeRouter(newFakeStore())

	w := do(r, httptest.NewRequest(http.MethodGet, "/me", nil))
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	if body := w.Body.String(); body != `{"anonymous":true}` {
		t.Errorf("匿名响应 = %s", body)
	}
}

// TestMeSessionIncludesTotpEnabled 覆盖 api.md 12.1：会话调用 /api/me 时
// user 里必须带 totp_enabled，前端据此判断设置页的 TOTP 状态。
func TestMeSessionIncludesTotpEnabled(t *testing.T) {
	for _, enabled := range []bool{true, false} {
		store := newFakeStore()
		store.users["user-1"] = User{ID: "user-1", Username: "kairo", TotpEnabled: enabled}

		plain, _ := newSessionToken()
		store.sessions[HashToken(plain)] = Session{
			ID: "sess-1", UserID: "user-1", ExpiresAt: time.Now().Add(time.Hour),
		}

		req := httptest.NewRequest(http.MethodGet, "/me", nil)
		req.AddCookie(&http.Cookie{Name: CookieSession, Value: plain})
		w := do(newMeRouter(store), req)

		if w.Code != http.StatusOK {
			t.Fatalf("状态码 = %d", w.Code)
		}
		var got struct {
			Anonymous bool `json:"anonymous"`
			User      *struct {
				ID          string `json:"id"`
				Username    string `json:"username"`
				TotpEnabled *bool  `json:"totp_enabled"`
			} `json:"user"`
		}
		if err := json.Unmarshal(w.Body.Bytes(), &got); err != nil {
			t.Fatalf("解析响应失败: %v", err)
		}
		if got.Anonymous || got.User == nil {
			t.Fatalf("应返回已登录用户: %s", w.Body.String())
		}
		if got.User.TotpEnabled == nil {
			t.Fatalf("缺少 totp_enabled: %s", w.Body.String())
		}
		if *got.User.TotpEnabled != enabled {
			t.Errorf("totp_enabled = %v，期望 %v", *got.User.TotpEnabled, enabled)
		}
	}
}

// TestMeTokenIncludesScope 覆盖 api.md 12.1 的 Token 分支。
func TestMeTokenIncludesScope(t *testing.T) {
	store := newFakeStore()
	store.users["user-1"] = User{ID: "user-1", Username: "kairo"}

	plain, prefix, _ := newAPIToken(ScopeReadWrite)
	store.tokens[HashToken(plain)] = APIToken{
		ID: "tok-1", UserID: "user-1", Scope: ScopeReadWrite, TokenPrefix: prefix,
	}

	req := httptest.NewRequest(http.MethodGet, "/me", nil)
	req.Header.Set("Authorization", "Bearer "+plain)
	w := do(newMeRouter(store), req)

	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	var got struct {
		AuthType string `json:"auth_type"`
		Scope    string `json:"scope"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &got); err != nil {
		t.Fatalf("解析响应失败: %v", err)
	}
	if got.AuthType != "token" || got.Scope != ScopeReadWrite {
		t.Errorf("auth_type = %q, scope = %q", got.AuthType, got.Scope)
	}
}

// TestVisibilityInjectedForLoggedIn 覆盖 auth.md 6.3：登录用户的可见性条件是
// 「自己的 OR 公开」，且 $1 绑定为当前用户 id。
func TestVisibilityInjectedForLoggedIn(t *testing.T) {
	vis := visibilityFor(Identity{Kind: SessionUser, UserID: "user-1"})
	if vis.Condition != VisibilityOwnedOrPublic {
		t.Fatalf("会话身份的条件 = %q", vis.Condition)
	}
	if len(vis.Args) != 1 || vis.Args[0] != "user-1" {
		t.Fatalf("参数 = %#v，期望 [user-1]", vis.Args)
	}

	tok := visibilityFor(Identity{Kind: TokenUser, UserID: "user-2", Scope: ScopeRead})
	if tok.Condition != VisibilityOwnedOrPublic || len(tok.Args) != 1 || tok.Args[0] != "user-2" {
		t.Fatalf("Token 身份的可见性条件异常: %#v", tok)
	}

	anon := visibilityFor(Identity{Kind: Anonymous})
	if anon.Condition != VisibilityPublic || len(anon.Args) != 0 {
		t.Fatalf("匿名身份的可见性条件异常: %#v", anon)
	}
}

