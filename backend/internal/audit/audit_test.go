package audit

import (
	"context"
	"os"
	"testing"

	"github.com/kairo/haven/internal/db"
)

func TestRecordRequiresDB(t *testing.T) {
	// 未初始化数据库时 record 应返回错误，而 Record 只记日志不 panic
	w := NewWriter(nil)
	if err := w.record(context.Background(), Event{EventType: EventLogout}); err == nil {
		t.Error("未初始化时应返回错误")
	}
	w.Record(context.Background(), Event{EventType: EventLogout})
}

// 集成测试：需要真实的 PostgreSQL（已跑 0001_init.up.sql）。
//
//	HAVEN_TEST_DB_DSN='postgres://haven:...@127.0.0.1:5432/haven_dev?sslmode=disable' \
//	  go test ./internal/audit/ -v
func openTestWriter(t *testing.T) (*Writer, func()) {
	t.Helper()
	dsn := os.Getenv("HAVEN_TEST_DB_DSN")
	if dsn == "" {
		t.Skip("未设置 HAVEN_TEST_DB_DSN，跳过数据库集成测试")
	}

	conn, err := db.Open(context.Background(), dsn)
	if err != nil {
		t.Fatalf("连接测试库失败: %v", err)
	}
	if _, err := conn.Exec(`TRUNCATE audit_events CASCADE`); err != nil {
		t.Fatalf("清理审计表失败: %v", err)
	}
	return NewWriter(conn), func() { conn.Close() }
}

func TestRecordAppendsEvents(t *testing.T) {
	w, closeDB := openTestWriter(t)
	defer closeDB()
	ctx := context.Background()

	// 无对象事件：target_type 应写成字符串 'null'
	w.Record(ctx, Event{
		ActorUsername: "kairo",
		EventType:     EventLoginSuccess,
		Metadata:      map[string]any{"via": "password+totp"},
		IP:            "127.0.0.1",
		UserAgent:     "test-agent",
	})

	if err := w.record(ctx, Event{
		ActorUsername: "kairo",
		EventType:     EventLogout,
	}); err != nil {
		t.Fatalf("record 返回错误: %v", err)
	}

	var count int
	var targetType string
	var ip string
	if err := w.db.QueryRow(`SELECT count(*) FROM audit_events`).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 2 {
		t.Errorf("应写入 2 条事件，实际 %d", count)
	}

	if err := w.db.QueryRow(
		`SELECT target_type, ip FROM audit_events WHERE event_type = $1`, EventLoginSuccess).
		Scan(&targetType, &ip); err != nil {
		t.Fatal(err)
	}
	if targetType != TargetNull {
		t.Errorf("无对象的 target_type 应为 %q，实际 %q", TargetNull, targetType)
	}
	if ip != "127.0.0.1" {
		t.Errorf("ip = %q", ip)
	}
}

func TestRecordMetadataJSON(t *testing.T) {
	w, closeDB := openTestWriter(t)
	defer closeDB()

	if err := w.record(context.Background(), Event{
		EventType:     EventTokenCreated,
		TargetType:    TargetToken,
		ActorUsername: "kairo",
		Metadata: map[string]any{
			"name":         "cli",
			"scope":        "read",
			"token_prefix": "haven_ro",
		},
	}); err != nil {
		t.Fatalf("record 返回错误: %v", err)
	}

	var name, scope string
	if err := w.db.QueryRow(
		`SELECT metadata->>'name', metadata->>'scope' FROM audit_events WHERE event_type = $1`,
		EventTokenCreated).Scan(&name, &scope); err != nil {
		t.Fatal(err)
	}
	if name != "cli" || scope != "read" {
		t.Errorf("metadata 解析异常: name=%q scope=%q", name, scope)
	}
}

func TestRecordRejectsUnknownEventType(t *testing.T) {
	w, closeDB := openTestWriter(t)
	defer closeDB()

	// CHECK 约束兜底：文档未列的事件类型必须写不进去（audit.md 第三节「新增事件类型必须同步更新 CHECK」）
	if err := w.record(context.Background(), Event{EventType: "bogus_event"}); err == nil {
		t.Error("未定义的事件类型应被 CHECK 约束拒绝")
	}
}
