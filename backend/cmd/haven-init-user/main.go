// haven-init-user 创建 Haven 的初始用户（本期唯一账号）。
//
// 依据 docs/backend/auth.md 第九节：本期只有一条 users 记录，由部署时的
// 初始化脚本创建；不提供注册接口，账号创建只能走命令行。
//
// 用法：
//
//	HAVEN_DB_DSN='postgres://haven@127.0.0.1:5432/haven?sslmode=disable' \
//	  go run ./cmd/haven-init-user -username kairo
//
// 密码从标准输入读取一次（不回显到命令行历史），或通过环境变量
// HAVEN_INIT_PASSWORD 提供（便于部署脚本）。密码要求见 docs/api.md 2.7：
// 至少 12 位。bcrypt cost 固定为 12（auth.md 8.1）。

package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
	"golang.org/x/term"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/db"
)

// 与认证包保持一致：bcrypt cost 与密码最小长度只在一个地方定义。
const (
	bcryptCost     = auth.BcryptCost
	minPasswordLen = auth.MinPasswordLen
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "创建用户失败: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	username := flag.String("username", "", "登录名（必填）")
	flag.Parse()

	name := strings.TrimSpace(*username)
	if name == "" {
		return errors.New("必须通过 -username 指定登录名")
	}

	dsn := strings.TrimSpace(os.Getenv("HAVEN_DB_DSN"))
	if dsn == "" {
		return errors.New("未设置 HAVEN_DB_DSN")
	}

	password, err := readPassword()
	if err != nil {
		return err
	}
	if len([]rune(password)) < minPasswordLen {
		return fmt.Errorf("密码至少 %d 位", minPasswordLen)
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return fmt.Errorf("生成密码哈希失败: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	conn, err := db.Open(ctx, dsn)
	if err != nil {
		return err
	}
	defer conn.Close()

	// 不区分大小写判重，与 idx_users_username_lower 一致。
	var exists bool
	if err := conn.QueryRowContext(ctx,
		`SELECT EXISTS (SELECT 1 FROM users WHERE lower(username) = lower($1))`, name,
	).Scan(&exists); err != nil {
		return fmt.Errorf("检查用户是否存在失败: %w", err)
	}
	if exists {
		return fmt.Errorf("用户 %q 已存在，本期只允许一个账号", name)
	}

	var id string
	if err := conn.QueryRowContext(ctx,
		`INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id`,
		name, string(hash),
	).Scan(&id); err != nil {
		return fmt.Errorf("写入用户失败: %w", err)
	}

	fmt.Printf("已创建用户 %s（id=%s，totp_enabled=false）\n", name, id)
	return nil
}

// readPassword 优先读 HAVEN_INIT_PASSWORD，否则从终端读取一次不回显的输入。
func readPassword() (string, error) {
	if pw := os.Getenv("HAVEN_INIT_PASSWORD"); pw != "" {
		return pw, nil
	}

	fmt.Fprint(os.Stderr, "请输入初始密码: ")
	raw, err := term.ReadPassword(int(os.Stdin.Fd()))
	fmt.Fprintln(os.Stderr)
	if err != nil {
		return "", fmt.Errorf("读取密码失败: %w", err)
	}
	return string(raw), nil
}
