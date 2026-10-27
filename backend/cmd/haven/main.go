package main

import (
	"log/slog"
	"os"

	"github.com/gin-gonic/gin"
)

// main 是后端入口。
//
// 配置全部来自环境变量，见 docs/architecture.md 第四节；
// 本期只完成启动骨架：读取配置、初始化日志、注册健康检查。
// 数据库连接、鉴权中间件与各领域路由按 TODO.md 后续条目接入。
func main() {
	if err := run(); err != nil {
		slog.Error("服务启动失败", "err", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := loadConfig()
	if err != nil {
		return err
	}

	logger := newLogger(cfg.LogLevel)
	slog.SetDefault(logger)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())

	r.GET("/api/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	logger.Info("后端启动", "listen_addr", cfg.ListenAddr)
	return r.Run(cfg.ListenAddr)
}
