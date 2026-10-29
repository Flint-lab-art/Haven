// Package config 负责从环境变量加载并校验后端配置。
//
// 依据 docs/architecture.md 第四节：所有配置通过环境变量提供，
// 不引入配置文件；缺失必填项时拒绝启动。
//
// cookie 名、有效期、bcrypt cost 等常量不在此暴露，直接写在代码里。
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Config 是后端启动所需的全部配置。
type Config struct {
	// 必填
	ListenAddr   string // HAVEN_LISTEN_ADDR
	DBDSN        string // HAVEN_DB_DSN
	FrontendDir  string // HAVEN_FRONTEND_DIR
	GogsBaseURL  string // HAVEN_GOGS_BASE_URL
	CookieDomain string // HAVEN_COOKIE_DOMAIN

	// 可选，带默认值
	CookieSecure bool   // HAVEN_COOKIE_SECURE，默认 true
	TotpIssuer   string // HAVEN_TOTP_ISSUER，默认 Haven
	LogLevel     string // HAVEN_LOG_LEVEL，默认 info
}

// Load 从环境变量读取并校验配置。
// 任一必填项缺失或取值非法都返回错误，由调用方拒绝启动。
func Load() (Config, error) {
	var cfg Config
	var missing []string

	cfg.ListenAddr = strings.TrimSpace(os.Getenv("HAVEN_LISTEN_ADDR"))
	if cfg.ListenAddr == "" {
		missing = append(missing, "HAVEN_LISTEN_ADDR")
	}

	cfg.DBDSN = strings.TrimSpace(os.Getenv("HAVEN_DB_DSN"))
	if cfg.DBDSN == "" {
		missing = append(missing, "HAVEN_DB_DSN")
	}

	cfg.FrontendDir = strings.TrimSpace(os.Getenv("HAVEN_FRONTEND_DIR"))
	if cfg.FrontendDir == "" {
		missing = append(missing, "HAVEN_FRONTEND_DIR")
	}

	cfg.GogsBaseURL = strings.TrimSpace(strings.TrimSuffix(os.Getenv("HAVEN_GOGS_BASE_URL"), "/"))
	if cfg.GogsBaseURL == "" {
		missing = append(missing, "HAVEN_GOGS_BASE_URL")
	}

	cfg.CookieDomain = strings.TrimSpace(os.Getenv("HAVEN_COOKIE_DOMAIN"))
	if cfg.CookieDomain == "" {
		missing = append(missing, "HAVEN_COOKIE_DOMAIN")
	}

	if len(missing) > 0 {
		return Config{}, fmt.Errorf("缺少必填环境变量: %s", strings.Join(missing, ", "))
	}

	cfg.CookieSecure = true
	if raw := strings.TrimSpace(os.Getenv("HAVEN_COOKIE_SECURE")); raw != "" {
		v, err := strconv.ParseBool(raw)
		if err != nil {
			return Config{}, fmt.Errorf("HAVEN_COOKIE_SECURE 取值非法 %q，应为 true 或 false", raw)
		}
		cfg.CookieSecure = v
	}

	cfg.TotpIssuer = strings.TrimSpace(os.Getenv("HAVEN_TOTP_ISSUER"))
	if cfg.TotpIssuer == "" {
		cfg.TotpIssuer = "Haven"
	}

	cfg.LogLevel = strings.ToLower(strings.TrimSpace(os.Getenv("HAVEN_LOG_LEVEL")))
	if cfg.LogLevel == "" {
		cfg.LogLevel = "info"
	}
	switch cfg.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		return Config{}, fmt.Errorf("HAVEN_LOG_LEVEL 取值非法 %q，应为 debug / info / warn / error", cfg.LogLevel)
	}

	return cfg, nil
}
