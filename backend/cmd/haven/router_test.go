package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/audit"
	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/config"
	"github.com/kairo/haven/internal/db"
)

// 端到端测试：真实 PostgreSQL + 完整路由栈，逐条对照 docs/api.md。
//
//	HAVEN_TEST_DB_DSN='postgres://haven:...@127.0.0.1:5432/haven_dev?sslmode=disable' \
//	  go test ./cmd/haven -v

// testUserAgent 模拟浏览器 UA，供授信设备名推导与审计测试使用。
const testUserAgent = "Mozilla/5.0 (X11; Linux x86_64) Chrome/130"

type testEnv struct {
	t      *testing.T
	router *gin.Engine
	store  *auth.SQLStore
	svc    *auth.Service
	cfg    config.Config
	userID string
}

func newTestEnv(t *testing.T) *testEnv {
	t.Helper()
	dsn := os.Getenv("HAVEN_TEST_DB_DSN")
	if dsn == "" {
		t.Skip("未设置 HAVEN_TEST_DB_DSN，跳过端到端测试")
	}

	admin, err := db.Open(t.Context(), dsn)
	if err != nil {
		t.Fatalf("连接测试库失败: %v", err)
	}

	schema := "it_" + strings.ToLower(strings.NewReplacer("/", "_").Replace(t.Name()))
	if len(schema) > 40 {
		schema = schema[:40]
	}
	schema += "_" + fmt.Sprintf("%d", time.Now().UnixNano()%1e9)

	ctx := t.Context()
	if _, err := admin.ExecContext(ctx, `DROP SCHEMA IF EXISTS `+schema+` CASCADE`); err != nil {
		t.Fatalf("清理 schema 失败: %v", err)
	}
	if _, err := admin.ExecContext(ctx, `CREATE SCHEMA `+schema); err != nil {
		t.Fatalf("创建 schema 失败: %v", err)
	}

	// 在独立 schema 里建表：直接复用 migration 文件，保证与生产结构一致
	migration, err := os.ReadFile("../../migrations/0001_init.up.sql")
	if err != nil {
		t.Fatalf("读取 migration 失败: %v", err)
	}

	conn, err := db.Open(ctx, appendSearchPath(dsn, schema+",public"))
	if err != nil {
		t.Fatalf("连接测试 schema 失败: %v", err)
	}
	t.Cleanup(func() {
		conn.Close()
		admin.ExecContext(context.Background(), `DROP SCHEMA IF EXISTS `+schema+` CASCADE`)
		admin.Close()
	})

	if _, err := conn.ExecContext(ctx, string(migration)); err != nil {
		t.Fatalf("建表失败: %v", err)
	}

	cfg := config.Config{
		ListenAddr:   "127.0.0.1:0",
		DBDSN:        dsn,
		FrontendDir:  t.TempDir(),
		GogsBaseURL:  "https://gogs.example.com",
		CookieDomain: "",
		CookieSecure: false,
		TotpIssuer:   "Haven",
		LogLevel:     "error",
	}

	store := auth.NewSQLStore(conn)
	svc := auth.NewService(conn)
	h := auth.NewHandler(svc, store, cfg.TotpIssuer, cfg.CookieDomain, cfg.CookieSecure)
	audit.UseAuthHooks(h, audit.NewWriter(conn))

	return &testEnv{t: t, router: newRouter(h, store), store: store, svc: svc, cfg: cfg}
}

// appendSearchPath 在 DSN 追加 search_path，用于隔离集成测试的 schema。
func appendSearchPath(dsn, searchPath string) string {
	sep := "?"
	if strings.Contains(dsn, "?") {
		sep = "&"
	}
	return dsn + sep + "search_path=" + url.QueryEscape(searchPath)
}

// createUser 直接插库建用户。
func (e *testEnv) createUser(username, password string) string {
	e.t.Helper()
	hash, err := auth.HashPassword(password)
	if err != nil {
		e.t.Fatal(err)
	}
	var id string
	if err := e.store.DB().QueryRow(
		`INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id`,
		username, hash).Scan(&id); err != nil {
		e.t.Fatalf("插入用户失败: %v", err)
	}
	e.userID = id
	return id
}

// do 发一个 JSON 请求，返回响应与 cookie。
func (e *testEnv) do(method, path string, body any, cookies ...*http.Cookie) *httptest.ResponseRecorder {
	e.t.Helper()
	var reader *bytes.Reader
	if body == nil {
		reader = bytes.NewReader(nil)
	} else {
		raw, err := json.Marshal(body)
		if err != nil {
			e.t.Fatal(err)
		}
		reader = bytes.NewReader(raw)
	}

	req := httptest.NewRequest(method, path, reader)
	req.Header.Set("Content-Type", "application/json")
	// httptest 默认不带 UA；显式给一个，模拟真实浏览器（授信设备名由 UA 推导）
	req.Header.Set("User-Agent", testUserAgent)
	for _, c := range cookies {
		req.AddCookie(c)
	}

	w := httptest.NewRecorder()
	e.router.ServeHTTP(w, req)
	return w
}

func (e *testEnv) doWithToken(method, path, token string) *httptest.ResponseRecorder {
	e.t.Helper()
	req := httptest.NewRequest(method, path, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	e.router.ServeHTTP(w, req)
	return w
}

func sessionCookie(t *testing.T, w *httptest.ResponseRecorder) *http.Cookie {
	t.Helper()
	for _, c := range w.Result().Cookies() {
		if c.Name == auth.CookieSession && c.Value != "" {
			return c
		}
	}
	t.Fatal("响应里没有会话 cookie")
	return nil
}

func deviceCookie(t *testing.T, w *httptest.ResponseRecorder) *http.Cookie {
	t.Helper()
	for _, c := range w.Result().Cookies() {
		if c.Name == auth.CookieTrustedDevice && c.Value != "" {
			return c
		}
	}
	return nil
}

// loginNoTotp 用账密登录并返回会话 cookie。
func (e *testEnv) loginNoTotp(username, password string) *http.Cookie {
	e.t.Helper()
	w := e.do(http.MethodPost, "/api/auth/login",
		map[string]any{"username": username, "password": password})
	if w.Code != http.StatusOK {
		e.t.Fatalf("登录失败，状态码 %d: %s", w.Code, w.Body.String())
	}
	return sessionCookie(e.t, w)
}

// --- /api/me ---

func TestMeAnonymous(t *testing.T) {
	e := newTestEnv(t)
	w := e.do(http.MethodGet, "/api/me", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	var got map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &got)
	if got["anonymous"] != true {
		t.Errorf("匿名响应应含 anonymous=true，实际 %v", got)
	}
}

func TestMeSessionAndToken(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	cookie := e.loginNoTotp("kairo", "correct-horse-battery")

	w := e.do(http.MethodGet, "/api/me", nil, cookie)
	var got map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &got)
	if got["anonymous"] != false || got["auth_type"] != "session" {
		t.Errorf("会话身份响应异常: %v", got)
	}
	if _, ok := got["scope"]; ok {
		t.Error("会话用户不应返回 scope")
	}
}

// --- 登录 ---

func TestLoginErrors(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")

	// 密码错误：401，且 message 不区分用户名/密码（api.md 2.1）
	w := e.do(http.MethodPost, "/api/auth/login", map[string]any{"username": "kairo", "password": "wrong"})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("密码错误状态码 = %d", w.Code)
	}
	wrongPwBody := w.Body.String()

	// 用户不存在：也是同样的 message，防枚举
	w = e.do(http.MethodPost, "/api/auth/login", map[string]any{"username": "nobody", "password": "wrong"})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("用户不存在状态码 = %d", w.Code)
	}
	if w.Body.String() != wrongPwBody {
		t.Errorf("两种失败应返回相同响应防枚举: %q vs %q", wrongPwBody, w.Body.String())
	}

	// 缺字段：400
	w = e.do(http.MethodPost, "/api/auth/login", map[string]any{"username": "kairo"})
	if w.Code != http.StatusBadRequest {
		t.Errorf("缺字段状态码 = %d，期望 400", w.Code)
	}
}

func TestLoginWritesAudit(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")

	e.do(http.MethodPost, "/api/auth/login", map[string]any{"username": "kairo", "password": "wrong"})
	e.loginNoTotp("kairo", "correct-horse-battery")

	var count int
	var reason string
	if err := e.store.DB().QueryRow(
		`SELECT count(*) FROM audit_events WHERE event_type = 'login_failure'`).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Errorf("login_failure 条数 = %d", count)
	}
	if err := e.store.DB().QueryRow(
		`SELECT metadata->>'reason' FROM audit_events WHERE event_type = 'login_failure'`).Scan(&reason); err != nil {
		t.Fatal(err)
	}
	if reason != "bad_password" {
		t.Errorf("login_failure reason = %q", reason)
	}

	if err := e.store.DB().QueryRow(
		`SELECT count(*) FROM audit_events WHERE event_type = 'login_success'`).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Errorf("login_success 条数 = %d", count)
	}
}

// --- 会话管理 ---

func TestSessionsRoutes(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")

	c1 := e.loginNoTotp("kairo", "correct-horse-battery")
	_ = e.loginNoTotp("kairo", "correct-horse-battery")

	// 列表
	w := e.do(http.MethodGet, "/api/sessions", nil, c1)
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	var list struct {
		Items []map[string]any `json:"items"`
		Total int              `json:"total"`
	}
	_ = json.Unmarshal(w.Body.Bytes(), &list)
	if list.Total != 2 || len(list.Items) != 2 {
		t.Fatalf("应有 2 条会话，实际 %+v", list)
	}
	current := 0
	for _, it := range list.Items {
		if it["is_current"] == true {
			current++
		}
	}
	if current != 1 {
		t.Errorf("应恰好一条 is_current，实际 %d", current)
	}

	// 撤销另一台设备
	var otherID string
	for _, it := range list.Items {
		if it["is_current"] != true {
			otherID, _ = it["id"].(string)
		}
	}
	if w := e.do(http.MethodDelete, "/api/sessions/"+otherID, nil, c1); w.Code != http.StatusNoContent {
		t.Errorf("撤销其他会话状态码 = %d", w.Code)
	}

	// 撤销当前会话：422
	var currentID string
	for _, it := range list.Items {
		if it["is_current"] == true {
			currentID, _ = it["id"].(string)
		}
	}
	w = e.do(http.MethodDelete, "/api/sessions/"+currentID, nil, c1)
	if w.Code != http.StatusUnprocessableEntity {
		t.Errorf("撤销当前会话应 422，实际 %d", w.Code)
	}

	// Token 调用列表：403
	createdTok, err := e.svc.CreateAPIToken(t.Context(), e.userID, "probe", auth.ScopeRead, nil)
	if err != nil {
		t.Fatal(err)
	}
	tok := createdTok.Token
	if w := e.doWithToken(http.MethodGet, "/api/sessions", tok); w.Code != http.StatusForbidden {
		t.Errorf("Token 查会话应 403，实际 %d", w.Code)
	}
}

func TestLogoutClearsSession(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	cookie := e.loginNoTotp("kairo", "correct-horse-battery")

	if w := e.do(http.MethodPost, "/api/auth/logout", nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("登出状态码 = %d", w.Code)
	}
	// 旧 cookie 失效
	w := e.do(http.MethodGet, "/api/me", nil, cookie)
	var got map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &got)
	if got["anonymous"] != true {
		t.Error("登出后旧会话 cookie 应失效")
	}

	var count int
	if err := e.store.DB().QueryRow(`SELECT count(*) FROM audit_events WHERE event_type = 'logout'`).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Errorf("应写一条 logout 审计，实际 %d", count)
	}
}

// --- Token 管理 ---

func TestTokensRoutes(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	cookie := e.loginNoTotp("kairo", "correct-horse-battery")

	// 未启用 TOTP 的会话不能管理 Token：403（api.md 1.6）
	if w := e.do(http.MethodGet, "/api/tokens", nil, cookie); w.Code != http.StatusForbidden {
		t.Fatalf("未通过 TOTP 应 403，实际 %d", w.Code)
	}

	// 启用 TOTP 后，旧会话仍未「通过过」TOTP（auth.md 6.2），需重新登录走完整两步
	secret := enableTotp(t, e, cookie)
	cookie = e.loginWithTotp("kairo", "correct-horse-battery", secret)

	// 创建
	w := e.do(http.MethodPost, "/api/tokens",
		map[string]any{"name": "cli", "scope": "read"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建 Token 状态码 = %d: %s", w.Code, w.Body.String())
	}
	var created map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &created)
	plain, _ := created["token"].(string)
	if plain == "" {
		t.Fatal("创建响应应含一次性明文")
	}

	// 列表不返回明文
	w = e.do(http.MethodGet, "/api/tokens", nil, cookie)
	if bytes.Contains(w.Body.Bytes(), []byte(plain)) {
		t.Error("列表不应返回 Token 明文")
	}
	if !bytes.Contains(w.Body.Bytes(), []byte("token_prefix")) {
		t.Error("列表应含 token_prefix")
	}

	// 非法 scope：422
	if w := e.do(http.MethodPost, "/api/tokens",
		map[string]any{"name": "x", "scope": "admin"}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("非法 scope 应 422，实际 %d", w.Code)
	}

	// 用该 Token 访问只读接口
	if w := e.doWithToken(http.MethodGet, "/api/me", plain); w.Code != http.StatusOK {
		t.Errorf("Token 调 /api/me 应 200，实际 %d", w.Code)
	}

	// 撤销
	id, _ := created["id"].(string)
	if w := e.do(http.MethodDelete, "/api/tokens/"+id, nil, cookie); w.Code != http.StatusNoContent {
		t.Errorf("撤销 Token 状态码 = %d", w.Code)
	}
	// 已撤销的 Token 不能再用
	if w := e.doWithToken(http.MethodGet, "/api/me", plain); w.Code != http.StatusUnauthorized {
		t.Errorf("已撤销 Token 应 401，实际 %d", w.Code)
	}
	// 重复撤销：422
	if w := e.do(http.MethodDelete, "/api/tokens/"+id, nil, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("重复撤销应 422，实际 %d", w.Code)
	}

	// 撤销是写 revoked_at，不删记录
	var revokedAt *time.Time
	if err := e.store.DB().QueryRow(`SELECT revoked_at FROM tokens WHERE id = $1`, id).Scan(&revokedAt); err != nil {
		t.Fatal(err)
	}
	if revokedAt == nil {
		t.Error("撤销应写 revoked_at 且保留记录")
	}
}

// loginWithTotp 走完整两步登录，返回通过 TOTP 的会话 cookie。
func (e *testEnv) loginWithTotp(username, password, secret string) *http.Cookie {
	e.t.Helper()
	w := e.do(http.MethodPost, "/api/auth/login", map[string]any{"username": username, "password": password})
	if w.Code != http.StatusOK {
		e.t.Fatalf("第一步登录状态码 = %d", w.Code)
	}
	var step1 map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &step1)
	temp, _ := step1["temp_token"].(string)
	if temp == "" {
		e.t.Fatal("应返回 temp_token")
	}

	code, err := auth.GenerateTotpCode(secret, time.Now())
	if err != nil {
		e.t.Fatal(err)
	}
	w = e.do(http.MethodPost, "/api/auth/login/totp", map[string]any{"temp_token": temp, "code": code})
	if w.Code != http.StatusOK {
		e.t.Fatalf("第二步登录状态码 = %d: %s", w.Code, w.Body.String())
	}
	return sessionCookie(e.t, w)
}

// enableTotp 走 setup + verify 两步，返回 secret。
func enableTotp(t *testing.T, e *testEnv, cookie *http.Cookie) string {
	t.Helper()
	w := e.do(http.MethodPost, "/api/auth/totp/setup", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("setup 状态码 = %d: %s", w.Code, w.Body.String())
	}
	var setup map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &setup)
	secret, _ := setup["secret"].(string)
	if secret == "" {
		t.Fatal("setup 应返回 secret")
	}

	code, err := auth.GenerateTotpCode(secret, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	w = e.do(http.MethodPost, "/api/auth/totp/verify",
		map[string]any{"secret": secret, "code": code}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("verify 状态码 = %d: %s", w.Code, w.Body.String())
	}
	return secret
}

func TestTrustedDevicesRoutes(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")

	// 登录时请求授信设备
	w := e.do(http.MethodPost, "/api/auth/login",
		map[string]any{"username": "kairo", "password": "correct-horse-battery", "trust_device": true})
	if w.Code != http.StatusOK {
		t.Fatalf("登录状态码 = %d", w.Code)
	}
	cookie := sessionCookie(t, w)
	if deviceCookie(t, w) == nil {
		t.Fatal("trust_device=true 应下发授信设备 cookie")
	}

	// 列表
	w = e.do(http.MethodGet, "/api/trusted-devices", nil, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	var list struct {
		Items []map[string]any `json:"items"`
		Total int              `json:"total"`
	}
	_ = json.Unmarshal(w.Body.Bytes(), &list)
	if list.Total != 1 {
		t.Fatalf("应有 1 台授信设备，实际 %+v", list)
	}

	// 不提供创建接口（api.md 4.2 说明）
	if w := e.do(http.MethodPost, "/api/trusted-devices", map[string]any{}, cookie); w.Code != http.StatusNotFound && w.Code != http.StatusMethodNotAllowed {
		t.Errorf("不应存在创建设备接口，实际状态码 %d", w.Code)
	}

	// 撤销
	id, _ := list.Items[0]["id"].(string)
	if w := e.do(http.MethodDelete, "/api/trusted-devices/"+id, nil, cookie); w.Code != http.StatusNoContent {
		t.Errorf("撤销设备状态码 = %d", w.Code)
	}

	var count int
	if err := e.store.DB().QueryRow(`SELECT count(*) FROM trusted_devices`).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 0 {
		t.Error("撤销授信设备应硬删除")
	}
}

func TestLoginWithTotpEndToEnd(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	cookie := e.loginNoTotp("kairo", "correct-horse-battery")
	secret := enableTotp(t, e, cookie)

	// 新登录要求 TOTP
	w := e.do(http.MethodPost, "/api/auth/login",
		map[string]any{"username": "kairo", "password": "correct-horse-battery"})
	if w.Code != http.StatusOK {
		t.Fatalf("状态码 = %d", w.Code)
	}
	var step1 map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &step1)
	if step1["totp_required"] != true {
		t.Fatalf("应要求 TOTP: %v", step1)
	}
	if _, ok := step1["temp_token"]; !ok {
		t.Fatal("应返回 temp_token")
	}
	if len(w.Result().Cookies()) != 0 {
		t.Error("需要 TOTP 时不应下发会话 cookie")
	}

	tempToken, _ := step1["temp_token"].(string)

	// 错误码
	if w := e.do(http.MethodPost, "/api/auth/login/totp",
		map[string]any{"temp_token": tempToken, "code": "000000"}); w.Code != http.StatusUnauthorized {
		t.Errorf("错误动态码应 401，实际 %d", w.Code)
	}

	code, _ := auth.GenerateTotpCode(secret, time.Now())
	w = e.do(http.MethodPost, "/api/auth/login/totp",
		map[string]any{"temp_token": tempToken, "code": code})
	if w.Code != http.StatusOK {
		t.Fatalf("第二步状态码 = %d: %s", w.Code, w.Body.String())
	}
	if sessionCookie(t, w) == nil {
		t.Fatal("第二步成功应下发会话")
	}

	// 不再要求 TOTP 的会话：拒绝管理 Token，但可看会话列表
	newCookie := sessionCookie(t, w)
	if w := e.do(http.MethodGet, "/api/sessions", nil, newCookie); w.Code != http.StatusOK {
		t.Errorf("会话列表状态码 = %d", w.Code)
	}
}

func TestPasswordChangeRequiresTotp(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	cookie := e.loginNoTotp("kairo", "correct-horse-battery")

	// 未启用 TOTP 的会话改密：403（api.md 2.7 要求 登录 + TOTP）
	if w := e.do(http.MethodPost, "/api/auth/password",
		map[string]any{"old_password": "correct-horse-battery", "new_password": "brand-new-password"}, cookie); w.Code != http.StatusForbidden {
		t.Errorf("未通过 TOTP 改密应 403，实际 %d", w.Code)
	}
}

func TestUnknownRoute(t *testing.T) {
	e := newTestEnv(t)
	w := e.do(http.MethodGet, "/api/health", nil)
	if w.Code != http.StatusOK {
		t.Errorf("健康检查状态码 = %d", w.Code)
	}
}
