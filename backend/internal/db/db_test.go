package db

import (
	"context"
	"os"
	"testing"
	"time"
)

// TestOpen 需要真实的 PostgreSQL，未设置 HAVEN_TEST_DB_DSN 时跳过。
//
// 本地跑法：
//
//	HAVEN_TEST_DB_DSN='postgres://haven:xxx@127.0.0.1:5432/haven?sslmode=disable' \
//	  go test ./internal/db/... -v
func TestOpen(t *testing.T) {
	dsn := os.Getenv("HAVEN_TEST_DB_DSN")
	if dsn == "" {
		t.Skip("未设置 HAVEN_TEST_DB_DSN，跳过数据库集成测试")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	conn, err := Open(ctx, dsn)
	if err != nil {
		t.Fatalf("Open() 返回错误: %v", err)
	}
	defer conn.Close()

	var one int
	if err := conn.QueryRowContext(ctx, "SELECT 1").Scan(&one); err != nil {
		t.Fatalf("查询失败: %v", err)
	}
	if one != 1 {
		t.Errorf("SELECT 1 返回 %d", one)
	}
}

func TestOpenInvalidDSN(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if _, err := Open(ctx, "postgres://nouser@127.0.0.1:1/nodb?sslmode=disable&connect_timeout=2"); err == nil {
		t.Fatal("无法连接的 DSN 应返回错误")
	}
}
