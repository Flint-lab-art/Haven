// Package db 负责建立后端到 PostgreSQL 的连接池。
//
// 数据库是唯一真值源（docs/overview.md），访问方式为 database/sql 加
// pgx 驱动、手写 SQL（docs/architecture.md 5.1），不引入 ORM。
package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib" // 注册 "pgx" 驱动
)

// Open 创建连接池并做一次连通性检查，失败即返回错误，由调用方拒绝启动。
func Open(ctx context.Context, dsn string) (*sql.DB, error) {
	conn, err := sql.Open("pgx", dsn)
	if err != nil {
		return nil, fmt.Errorf("打开数据库连接失败: %w", err)
	}

	// 连接池与单连接超时：自用单机部署，连接数不宜放大。
	conn.SetMaxOpenConns(10)
	conn.SetMaxIdleConns(5)
	conn.SetConnMaxLifetime(time.Hour)

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := conn.PingContext(pingCtx); err != nil {
		conn.Close()
		return nil, fmt.Errorf("数据库连通性检查失败: %w", err)
	}

	return conn, nil
}
