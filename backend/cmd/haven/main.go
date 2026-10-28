package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/kairo/haven/internal/audit"
	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/config"
	"github.com/kairo/haven/internal/db"
)

// main 是后端入口。
//
// 配置全部来自环境变量，见 docs/architecture.md 第四节；
// 当前已接入：配置、日志、数据库、认证与授权（docs/api.md 第二至五、十一节）。
// 静态托管与其余领域路由按 TODO.md 后续条目接入。
func main() {
	if err := run(); err != nil {
		slog.Error("服务启动失败", "err", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	logger := newLogger(cfg.LogLevel)
	slog.SetDefault(logger)

	conn, err := db.Open(context.Background(), cfg.DBDSN)
	if err != nil {
		return err
	}
	defer conn.Close()
	logger.Info("数据库连接就绪")

	store := auth.NewSQLStore(conn)
	svc := auth.NewService(conn)
	handler := auth.NewHandler(svc, store, cfg.TotpIssuer, cfg.CookieDomain, cfg.CookieSecure)

	// 审计事件在业务成功后写，失败只记日志（audit.md 第五节）
	audit.UseAuthHooks(handler, audit.NewWriter(conn))

	r := newRouter(handler, store)

	logger.Info("后端启动", "listen_addr", cfg.ListenAddr)
	return r.Run(cfg.ListenAddr)
}
