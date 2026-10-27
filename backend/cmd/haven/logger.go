package main

import (
	"log/slog"
	"os"
)

// newLogger 按配置的日志级别构造结构化日志器，输出到 stderr。
//
// 见 docs/architecture.md 5.7：日志走标准库 log/slog，
// 不得记录请求体、笔记内容、密码或 Token。
func newLogger(level string) *slog.Logger {
	var lv slog.Level
	switch level {
	case "debug":
		lv = slog.LevelDebug
	case "warn":
		lv = slog.LevelWarn
	case "error":
		lv = slog.LevelError
	default:
		lv = slog.LevelInfo
	}

	return slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: lv}))
}
