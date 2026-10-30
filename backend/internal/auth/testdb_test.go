package auth

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"github.com/kairo/haven/internal/db"
)

// 集成测试的隔离方式：每个用例在自己的 PostgreSQL schema 里跑。
//
// 平铺的表名加上 search_path 切换，既能复用 0001_init.up.sql，又不会让并发的
// TRUNCATE 互相踩踏（`go test ./...` 会并行跑不同包，同包内也可能并发）。
//
//	HAVEN_TEST_DB_DSN='postgres://haven:...@127.0.0.1:5432/haven_dev?sslmode=disable' \
//	  go test ./... -v

// newSchemaService 在独占 schema 里建表，返回已切到该 schema 的 Service 与连接。
func newSchemaService(t *testing.T) *Service {
	t.Helper()
	admin, dsn := openTestDB(t)

	schema := fmt.Sprintf("test_%s", sanitize(t.Name()))

	ctx := context.Background()
	if _, err := admin.ExecContext(ctx, `DROP SCHEMA IF EXISTS `+schema+` CASCADE`); err != nil {
		t.Fatalf("清理测试 schema 失败: %v", err)
	}
	if _, err := admin.ExecContext(ctx, `CREATE SCHEMA `+schema); err != nil {
		t.Fatalf("创建测试 schema 失败: %v", err)
	}

	// 在该 schema 内重建全部表：search_path 切到新 schema，
	// pg_trgm 建在 public 并由 search_path 继承。
	conn, err := db.Open(ctx, dsnWithSchema(dsn, schema+",public"))
	if err != nil {
		t.Fatalf("连接测试 schema 失败: %v", err)
	}
	t.Cleanup(func() {
		conn.Close()
		admin.ExecContext(context.Background(), `DROP SCHEMA IF EXISTS `+schema+` CASCADE`)
		admin.Close()
	})

	migration := readAuthTestMigrations(t)
	if _, err := conn.ExecContext(ctx, migration); err != nil {
		t.Fatalf("在测试 schema 内建表失败: %v", err)
	}

	return NewService(conn)
}

// readAuthTestMigrations 按文件名顺序拼接全部 up migration。
func readAuthTestMigrations(t *testing.T) string {
	t.Helper()
	dir := "migrations"
	if _, err := os.Stat(dir); err != nil {
		dir = "../../migrations"
	}

	files, err := filepath.Glob(filepath.Join(dir, "*.up.sql"))
	if err != nil {
		t.Fatalf("查找 migration 失败: %v", err)
	}
	sort.Strings(files)

	var b strings.Builder
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			t.Fatalf("读取 migration 失败: %v", err)
		}
		b.Write(data)
		b.WriteString("\n")
	}
	return b.String()
}

// openTestDB 打开与测试库的连接，未设置 HAVEN_TEST_DB_DSN 时跳过。
func openTestDB(t *testing.T) (*sql.DB, string) {
	t.Helper()
	dsn := os.Getenv("HAVEN_TEST_DB_DSN")
	if dsn == "" {
		t.Skip("未设置 HAVEN_TEST_DB_DSN，跳过数据库集成测试")
	}

	conn, err := db.Open(context.Background(), dsn)
	if err != nil {
		t.Fatalf("连接测试库失败: %v", err)
	}
	t.Cleanup(func() { conn.Close() })
	return conn, dsn
}

// dsnWithSchema 在 DSN 上追加 search_path。
func dsnWithSchema(dsn, searchPath string) string {
	u, err := url.Parse(dsn)
	if err != nil {
		sep := "?"
		if strings.Contains(dsn, "?") {
			sep = "&"
		}
		return dsn + sep + "search_path=" + url.QueryEscape(searchPath)
	}
	q := u.Query()
	q.Set("search_path", searchPath)
	u.RawQuery = q.Encode()
	return u.String()
}

// randomSuffix 给 schema 名加一个短随机后缀，避免 -count>1 时重名。
func randomSuffix() string {
	buf := make([]byte, 4)
	_, _ = rand.Read(buf)
	return hex.EncodeToString(buf)
}

// sanitize 把测试名变成合法的 schema 片段（只留小写字母数字下划线，限长 40）。
func sanitize(name string) string {
	var b strings.Builder
	for _, r := range strings.ToLower(name) {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9', r == '_':
			b.WriteRune(r)
		default:
			b.WriteRune('_')
		}
	}
	out := b.String()
	if len(out) > 40 {
		out = out[:40]
	}
	return out
}
