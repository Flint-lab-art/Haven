package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/kairo/haven/internal/audit"
	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/config"
	"github.com/kairo/haven/internal/db"
	"github.com/kairo/haven/internal/notes"
	"github.com/kairo/haven/internal/portfolio"
	"github.com/kairo/haven/internal/search"
	"github.com/kairo/haven/internal/tags"
)

// main 是后端入口。
//
// 配置全部来自环境变量，见 docs/architecture.md 第四节。
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
	notesSvc := notes.NewService(conn)
	tagsSvc := tags.NewService(conn)
	searchSvc := search.NewService(conn)
	portfolioSvc := portfolio.NewService(conn, cfg.GogsBaseURL)

	authHandler := auth.NewHandler(auth.NewService(conn), store, cfg.TotpIssuer, cfg.CookieDomain, cfg.CookieSecure)
	notesHandler := notes.NewHandler(notesSvc)
	auditWriter := audit.NewWriter(conn)

	// 审计事件在业务成功后写，失败只记日志（audit.md 第五节）
	audit.UseAuthHooks(authHandler, auditWriter)
	audit.UseNoteHooks(notesHandler, auditWriter)

	r := newRouter(deps{
		authStore:     store,
		authHandler:   authHandler,
		notesHandler:  notesHandler,
		tagsHandler:   tags.NewHandler(tagsSvc),
		searchHandler: search.NewHandler(searchSvc),
		portfolio:     portfolio.NewHandler(portfolioSvc),
		frontendDir:   cfg.FrontendDir,
	})

	logger.Info("后端启动", "listen_addr", cfg.ListenAddr)
	return r.Run(cfg.ListenAddr)
}
