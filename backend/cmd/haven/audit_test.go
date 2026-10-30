package main

import (
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"github.com/kairo/haven/internal/auth"
)

// 审计端到端校验：逐条对照 docs/backend/audit.md 第三节的 target_type 与 metadata 形状，
// 以及第二节「只追加、不记录敏感值」的规则。

type auditRow struct {
	EventType     string          `json:"event_type"`
	TargetType    string          `json:"target_type"`
	TargetID      *string         `json:"target_id"`
	ActorUserID   *string         `json:"actor_user_id"`
	ActorUsername string          `json:"actor_username"`
	Metadata      json.RawMessage `json:"metadata"`
}

// auditRows 按写入顺序返回全部审计记录。
func (e *testEnv) auditRows() []auditRow {
	e.t.Helper()
	rows, err := e.store.DB().Query(`
		SELECT event_type, target_type, target_id, actor_user_id, actor_username, metadata
		FROM audit_events ORDER BY created_at, event_type`)
	if err != nil {
		e.t.Fatalf("查询审计事件失败: %v", err)
	}
	defer rows.Close()

	var out []auditRow
	for rows.Next() {
		var r auditRow
		if err := rows.Scan(&r.EventType, &r.TargetType, &r.TargetID, &r.ActorUserID, &r.ActorUsername, &r.Metadata); err != nil {
			e.t.Fatalf("扫描审计事件失败: %v", err)
		}
		out = append(out, r)
	}
	return out
}

// findAudit 返回首个匹配的事件。
func (e *testEnv) findAudit(eventType string) (auditRow, bool) {
	e.t.Helper()
	for _, r := range e.auditRows() {
		if r.EventType == eventType {
			return r, true
		}
	}
	return auditRow{}, false
}

// metaOf 解析 metadata 为 map。
func metaOf(t *testing.T, r auditRow) map[string]any {
	t.Helper()
	var m map[string]any
	if err := json.Unmarshal(r.Metadata, &m); err != nil {
		t.Fatalf("metadata 不是合法 JSON: %v (%s)", err, r.Metadata)
	}
	return m
}

func TestAuditLoginEvents(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")

	// 用户名不存在：actor_user_id 为 NULL，actor_username 存原文（audit.md 规则 2）
	e.do(http.MethodPost, "/api/auth/login", map[string]any{"username": "ghost", "password": "x"})

	r, ok := e.findAudit("login_failure")
	if !ok {
		t.Fatal("用户名不存在应写 login_failure")
	}
	if r.TargetType != "null" {
		t.Errorf("login_failure target_type 应为 'null'，实际 %q", r.TargetType)
	}
	if r.ActorUserID != nil {
		t.Errorf("用户名不存在时 actor_user_id 应为 NULL，实际 %v", *r.ActorUserID)
	}
	if r.ActorUsername != "ghost" {
		t.Errorf("actor_username 应存提交原文，实际 %q", r.ActorUsername)
	}
	if m := metaOf(t, r); m["reason"] != "no_such_user" {
		t.Errorf("用户名不存在时 reason 应为 no_such_user，实际 %v", m)
	}

	// 成功登录
	e.loginNoTotp("kairo", "correct-horse-battery")
	r, ok = e.findAudit("login_success")
	if !ok {
		t.Fatal("登录成功应写 login_success")
	}
	if r.TargetType != "null" {
		t.Errorf("login_success target_type 应为 'null'，实际 %q", r.TargetType)
	}
	if r.ActorUserID == nil || *r.ActorUserID != e.userID {
		t.Error("login_success 应带 actor_user_id")
	}
	if m := metaOf(t, r); m["via"] != "password+totp" {
		t.Errorf("未启用 TOTP 的登录 via 应为 password+totp，实际 %v", m["via"])
	}
}

func TestAuditTrustedDeviceVia(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")

	// trust_device=true 且无 TOTP：via 仍是 password+totp（授信设备是本次新建的）
	w := e.do(http.MethodPost, "/api/auth/login",
		map[string]any{"username": "kairo", "password": "correct-horse-battery", "trust_device": true})
	if w.Code != http.StatusOK {
		t.Fatalf("登录状态码 = %d", w.Code)
	}

	r, ok := e.findAudit("trusted_device_added")
	if !ok {
		t.Fatal("trust_device=true 应写 trusted_device_added")
	}
	if r.TargetType != "trusted_device" {
		t.Errorf("target_type 应为 trusted_device，实际 %q", r.TargetType)
	}
	if r.TargetID == nil || *r.TargetID == "" {
		t.Error("trusted_device_added 应带 target_id")
	}
	// device_name 由 UA 推导（如 Mozilla/5.0），不能是空串以外的任意值
	if m := metaOf(t, r); m["device_name"] == nil || m["device_name"] == "" {
		t.Errorf("metadata 应含非空 device_name，实际 %v", m)
	}
}

func TestAuditTotpEvents(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	cookie := e.loginNoTotp("kairo", "correct-horse-battery")

	secret := enableTotp(t, e, cookie)
	r, ok := e.findAudit("totp_bound")
	if !ok {
		t.Fatal("绑定 TOTP 应写 totp_bound")
	}
	if r.TargetType != "user" || r.TargetID == nil || *r.TargetID != e.userID {
		t.Errorf("totp_bound 应指向该用户，实际 target_type=%q target_id=%v", r.TargetType, r.TargetID)
	}
	if len(metaOf(t, r)) != 0 {
		t.Error("totp_bound 的 metadata 应为空对象")
	}

	// TOTP 错误登录：login_failure reason = bad_totp
	w := e.do(http.MethodPost, "/api/auth/login",
		map[string]any{"username": "kairo", "password": "correct-horse-battery"})
	var step1 map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &step1)
	temp, _ := step1["temp_token"].(string)
	e.do(http.MethodPost, "/api/auth/login/totp", map[string]any{"temp_token": temp, "code": "000000"})

	if r, ok := e.findAuditReason("bad_totp"); !ok {
		t.Errorf("TOTP 错误应写 login_failure reason=bad_totp，实际记录：%+v", e.auditRows())
	} else if r.ActorUsername != "kairo" {
		t.Errorf("bad_totp 的 actor_username 应为 kairo，实际 %q", r.ActorUsername)
	}

	// 用通过 TOTP 的会话关闭 TOTP
	code, _ := auth.GenerateTotpCode(secret, time.Now())
	newCookie := e.loginWithTotp("kairo", "correct-horse-battery", secret)
	_ = code
	disableCode, _ := auth.GenerateTotpCode(secret, time.Now())
	if w := e.do(http.MethodPost, "/api/auth/totp/disable",
		map[string]any{"code": disableCode}, newCookie); w.Code != http.StatusOK {
		t.Fatalf("关闭 TOTP 状态码 = %d: %s", w.Code, w.Body.String())
	}
	if _, ok := e.findAudit("totp_disabled"); !ok {
		t.Error("关闭 TOTP 应写 totp_disabled")
	}
}

// findAuditReason 找 login_failure 且 reason 匹配的事件。
func (e *testEnv) findAuditReason(reason string) (auditRow, bool) {
	e.t.Helper()
	for _, r := range e.auditRows() {
		if r.EventType != "login_failure" {
			continue
		}
		if m := metaOf(e.t, r); m["reason"] == reason {
			return r, true
		}
	}
	return auditRow{}, false
}

func TestAuditTokenEvents(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	cookie := e.loginNoTotp("kairo", "correct-horse-battery")
	secret := enableTotp(t, e, cookie)
	cookie = e.loginWithTotp("kairo", "correct-horse-battery", secret)

	w := e.do(http.MethodPost, "/api/tokens", map[string]any{"name": "cli", "scope": "read"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建 Token 状态码 = %d", w.Code)
	}
	var created map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &created)
	plain, _ := created["token"].(string)
	id, _ := created["id"].(string)

	r, ok := e.findAudit("token_created")
	if !ok {
		t.Fatal("创建 Token 应写 token_created")
	}
	if r.TargetType != "token" || r.TargetID == nil || *r.TargetID != id {
		t.Errorf("token_created 应指向该 Token，实际 target_type=%q target_id=%v", r.TargetType, r.TargetID)
	}

	m := metaOf(t, r)
	if m["name"] != "cli" || m["scope"] != "read" || m["token_prefix"] == nil {
		t.Errorf("token_created metadata 不完整: %v", m)
	}
	// 绝不记录明文（audit.md 规则 5）
	if raw := string(r.Metadata); contains(raw, plain) {
		t.Error("审计 metadata 不能包含 Token 明文")
	}

	if w := e.do(http.MethodDelete, "/api/tokens/"+id, nil, cookie); w.Code != http.StatusNoContent {
		t.Fatalf("撤销 Token 状态码 = %d", w.Code)
	}
	r, ok = e.findAudit("token_revoked")
	if !ok {
		t.Fatal("撤销 Token 应写 token_revoked")
	}
	if r.TargetType != "token" || r.TargetID == nil || *r.TargetID != id {
		t.Errorf("token_revoked 应指向该 Token")
	}
	if raw := string(r.Metadata); contains(raw, plain) {
		t.Error("token_revoked 的 metadata 不能包含明文")
	}
}

func TestAuditSessionAndDeviceRevoke(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")

	// 建两台会话 + 一台授信设备
	w := e.do(http.MethodPost, "/api/auth/login",
		map[string]any{"username": "kairo", "password": "correct-horse-battery", "trust_device": true})
	c1 := sessionCookie(t, w)
	_ = e.loginNoTotp("kairo", "correct-horse-battery")

	// 撤销另一台会话
	w = e.do(http.MethodGet, "/api/sessions", nil, c1)
	var list struct {
		Items []map[string]any `json:"items"`
	}
	_ = json.Unmarshal(w.Body.Bytes(), &list)
	var otherID string
	for _, it := range list.Items {
		if it["is_current"] != true {
			otherID, _ = it["id"].(string)
		}
	}
	if w := e.do(http.MethodDelete, "/api/sessions/"+otherID, nil, c1); w.Code != http.StatusNoContent {
		t.Fatalf("撤销会话状态码 = %d", w.Code)
	}

	r, ok := e.findAudit("session_revoked")
	if !ok {
		t.Fatal("撤销会话应写 session_revoked")
	}
	if r.TargetType != "session" || r.TargetID == nil || *r.TargetID != otherID {
		t.Errorf("session_revoked 应指向被撤销的会话")
	}
	if m := metaOf(t, r); m["session_created_at"] == nil {
		t.Error("session_revoked 的 metadata 应含 session_created_at")
	}

	// 撤销授信设备
	w = e.do(http.MethodGet, "/api/trusted-devices", nil, c1)
	var devs struct {
		Items []map[string]any `json:"items"`
	}
	_ = json.Unmarshal(w.Body.Bytes(), &devs)
	if len(devs.Items) != 1 {
		t.Fatalf("应有 1 台授信设备，实际 %d", len(devs.Items))
	}
	devID, _ := devs.Items[0]["id"].(string)
	if w := e.do(http.MethodDelete, "/api/trusted-devices/"+devID, nil, c1); w.Code != http.StatusNoContent {
		t.Fatalf("撤销设备状态码 = %d", w.Code)
	}

	r, ok = e.findAudit("trusted_device_revoked")
	if !ok {
		t.Fatal("撤销授信设备应写 trusted_device_revoked")
	}
	if r.TargetType != "trusted_device" || r.TargetID == nil || *r.TargetID != devID {
		t.Errorf("trusted_device_revoked 应指向被撤销的设备")
	}
	// device_name 由 UA 推导（如 Mozilla/5.0），不能是空串以外的任意值
	if m := metaOf(t, r); m["device_name"] == nil || m["device_name"] == "" {
		t.Errorf("metadata 应含非空 device_name，实际 %v", m)
	}
}

func TestAuditAppendOnly(t *testing.T) {
	e := newTestEnv(t)
	e.createUser("kairo", "correct-horse-battery")
	e.loginNoTotp("kairo", "correct-horse-battery")

	before := len(e.auditRows())
	if before == 0 {
		t.Fatal("登录后应有审计记录")
	}

	// 没有任何 HTTP 接口能改或删审计（audit.md 第六节：本期不提供 Web 查询界面）
	for _, path := range []string{"/api/audit", "/api/audit-events"} {
		if w := e.do(http.MethodGet, path, nil); w.Code == http.StatusOK {
			t.Errorf("%s 不应存在（本期不提供审计查询接口）", path)
		}
	}
	if after := len(e.auditRows()); after != before {
		t.Errorf("审计记录数量不应变化：%d -> %d", before, after)
	}
}

func contains(s, sub string) bool {
	return len(sub) > 0 && len(s) >= len(sub) && (func() bool {
		for i := 0; i+len(sub) <= len(s); i++ {
			if s[i:i+len(sub)] == sub {
				return true
			}
		}
		return false
	})()
}
