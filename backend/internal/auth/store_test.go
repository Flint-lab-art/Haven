package auth

import (
	"context"
	"strings"
	"testing"
	"time"
)

// fakeStore 是 Store 的内存实现，供中间件与业务逻辑的单测使用。
type fakeStore struct {
	sessions map[string]Session // token_hash -> session
	tokens   map[string]APIToken
	users    map[string]User

	touchedSessions []string
	touchedTokens   []string
	deletedSessions []string
}

func newFakeStore() *fakeStore {
	return &fakeStore{
		sessions: make(map[string]Session),
		tokens:   make(map[string]APIToken),
		users:    make(map[string]User),
	}
}

func (f *fakeStore) FindSessionByHash(_ context.Context, tokenHash string) (Session, error) {
	s, ok := f.sessions[tokenHash]
	if !ok {
		return Session{}, ErrNotFound
	}
	return s, nil
}

func (f *fakeStore) TouchSession(_ context.Context, id string, _ time.Time) error {
	f.touchedSessions = append(f.touchedSessions, id)
	return nil
}

func (f *fakeStore) DeleteSession(_ context.Context, id string) error {
	f.deletedSessions = append(f.deletedSessions, id)
	return nil
}

func (f *fakeStore) FindTokenByHash(_ context.Context, tokenHash string) (APIToken, error) {
	t, ok := f.tokens[tokenHash]
	if !ok {
		return APIToken{}, ErrNotFound
	}
	return t, nil
}

func (f *fakeStore) TouchToken(_ context.Context, id string, _ time.Time) error {
	f.touchedTokens = append(f.touchedTokens, id)
	return nil
}

func (f *fakeStore) GetUser(_ context.Context, id string) (User, error) {
	u, ok := f.users[id]
	if !ok {
		return User{}, ErrNotFound
	}
	return u, nil
}

var _ Store = (*fakeStore)(nil)

// HashTokenForTest 暴露「剥离会话标记后再哈希」的行为，供中间件测试构造 key。
func HashTokenForTest(plain string) string {
	base, _ := splitSessionToken(plain)
	return base
}

func TestHashTokenConsistency(t *testing.T) {
	// 相同输入必须得到相同哈希，用于按 token_hash 查库。
	if HashToken("abc") != HashToken("abc") {
		t.Error("同一输入的哈希应一致")
	}
}

func TestSplitPendingTokenEdgeCases(t *testing.T) {
	cases := []struct {
		in    string
		token string
		trust bool
	}{
		{in: "haven_pend_xyz", token: "haven_pend_xyz", trust: false},
		{in: "haven_pend_xyz:1", token: "haven_pend_xyz", trust: true},
		{in: "haven_pend_xyz:0", token: "haven_pend_xyz:0", trust: false},
		{in: ":1", token: "", trust: true},
		{in: "", token: "", trust: false},
	}

	for _, tc := range cases {
		tok, trust := splitPendingToken(tc.in)
		if tok != tc.token || trust != tc.trust {
			t.Errorf("splitPendingToken(%q) = (%q, %v)，期望 (%q, %v)",
				tc.in, tok, trust, tc.token, tc.trust)
		}
	}
}

func TestIdentityString(t *testing.T) {
	if got := Anonymous.String(); got != "anonymous" {
		t.Errorf("Anonymous.String() = %q", got)
	}
	if got := SessionUser.String(); got != "session" {
		t.Errorf("SessionUser.String() = %q", got)
	}
	if got := TokenUser.String(); got != "token" {
		t.Errorf("TokenUser.String() = %q", got)
	}
}

func TestIdentityIsLoggedIn(t *testing.T) {
	if (Identity{Kind: Anonymous}).IsLoggedIn() {
		t.Error("Anonymous 不应算已登录")
	}
	if !(Identity{Kind: SessionUser}).IsLoggedIn() {
		t.Error("SessionUser 应算已登录")
	}
	if !(Identity{Kind: TokenUser}).IsLoggedIn() {
		t.Error("TokenUser 应算已登录")
	}
}

func TestTruncatePrefix(t *testing.T) {
	if got := truncatePrefix("abc"); got != "abc" {
		t.Errorf("短于前缀长度的应原样返回，实际 %q", got)
	}
	if got := truncatePrefix("haven_ro_abcdefghij"); got != "haven_ro" {
		t.Errorf("应截取前 8 位，实际 %q", got)
	}
	if strings.HasPrefix(truncatePrefix("haven_ro_abcdefghij"), "haven_ro_") {
		t.Error("前 8 位不应包含 scope 后的随机串")
	}
}
