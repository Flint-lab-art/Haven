package config

import (
	"strings"
	"testing"
)

// setAll 设置一组完整的必填环境变量，供各用例在此基础上调整。
func setAll(t *testing.T) {
	t.Helper()
	t.Setenv("HAVEN_LISTEN_ADDR", "127.0.0.1:8080")
	t.Setenv("HAVEN_DB_DSN", "postgres://haven@127.0.0.1:5432/haven?sslmode=disable")
	t.Setenv("HAVEN_FRONTEND_DIR", "/opt/haven/frontend/dist")
	t.Setenv("HAVEN_GOGS_BASE_URL", "https://gogs.example.com")
	t.Setenv("HAVEN_COOKIE_DOMAIN", "app.example.com")
}

func TestLoadDefaults(t *testing.T) {
	setAll(t)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() 返回错误: %v", err)
	}

	if !cfg.CookieSecure {
		t.Error("HAVEN_COOKIE_SECURE 未设置时应默认 true")
	}
	if cfg.TotpIssuer != "Haven" {
		t.Errorf("HAVEN_TOTP_ISSUER 默认为 Haven，实际 %q", cfg.TotpIssuer)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("HAVEN_LOG_LEVEL 默认为 info，实际 %q", cfg.LogLevel)
	}
}

func TestLoadMissingRequired(t *testing.T) {
	setAll(t)
	t.Setenv("HAVEN_DB_DSN", "")
	t.Setenv("HAVEN_COOKIE_DOMAIN", "   ")

	_, err := Load()
	if err == nil {
		t.Fatal("缺少必填项时应返回错误")
	}
	// 应一次性列出全部缺失项，而不是只报第一个
	for _, name := range []string{"HAVEN_DB_DSN", "HAVEN_COOKIE_DOMAIN"} {
		if !strings.Contains(err.Error(), name) {
			t.Errorf("错误信息应包含 %s，实际 %q", name, err.Error())
		}
	}
}

func TestLoadCookieSecureFalse(t *testing.T) {
	setAll(t)
	t.Setenv("HAVEN_COOKIE_SECURE", "false")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() 返回错误: %v", err)
	}
	if cfg.CookieSecure {
		t.Error("HAVEN_COOKIE_SECURE=false 时应为 false")
	}
}

func TestLoadInvalidCookieSecure(t *testing.T) {
	setAll(t)
	t.Setenv("HAVEN_COOKIE_SECURE", "yes-please")

	if _, err := Load(); err == nil {
		t.Fatal("非法的 HAVEN_COOKIE_SECURE 应返回错误")
	}
}

func TestLoadLogLevel(t *testing.T) {
	cases := []struct {
		raw     string
		want    string
		wantErr bool
	}{
		{raw: "", want: "info"},
		{raw: "DEBUG", want: "debug"},
		{raw: "warn", want: "warn"},
		{raw: "error", want: "error"},
		{raw: "verbose", wantErr: true},
	}

	for _, tc := range cases {
		t.Run(tc.raw, func(t *testing.T) {
			setAll(t)
			t.Setenv("HAVEN_LOG_LEVEL", tc.raw)

			cfg, err := Load()
			if tc.wantErr {
				if err == nil {
					t.Fatalf("HAVEN_LOG_LEVEL=%q 应返回错误", tc.raw)
				}
				return
			}
			if err != nil {
				t.Fatalf("Load() 返回错误: %v", err)
			}
			if cfg.LogLevel != tc.want {
				t.Errorf("HAVEN_LOG_LEVEL=%q 解析为 %q，期望 %q", tc.raw, cfg.LogLevel, tc.want)
			}
		})
	}
}

func TestLoadTrimsTrailingSlash(t *testing.T) {
	setAll(t)
	t.Setenv("HAVEN_GOGS_BASE_URL", "https://gogs.example.com/")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() 返回错误: %v", err)
	}
	// 作品集 URL 由 GogsBaseURL + "/" + repo_path 拼接，末尾斜杠必须去掉
	if cfg.GogsBaseURL != "https://gogs.example.com" {
		t.Errorf("GogsBaseURL 应去掉末尾斜杠，实际 %q", cfg.GogsBaseURL)
	}
}
