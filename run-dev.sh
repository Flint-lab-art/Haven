#!/usr/bin/env bash
# 本地开发启动脚本。
#
# 用法：
#   ./run-dev.sh          启动后端（127.0.0.1:8080）
#   ./run-dev.sh build    先构建前端再启动
#
# 前置：PostgreSQL 已建好 haven_dev 库并执行过 migrations/0001_init.up.sql，
# 且已用 cmd/haven-init-user 建过账号。详见 README 或 AGENTS.md。

set -euo pipefail

cd "$(dirname "$0")/backend"

# 本地开发用的默认值，均可被外部环境变量覆盖
export HAVEN_LISTEN_ADDR="${HAVEN_LISTEN_ADDR:-127.0.0.1:8080}"
export HAVEN_DB_DSN="${HAVEN_DB_DSN:-postgres://haven:haven_dev_pw@127.0.0.1:5432/haven_dev?sslmode=disable}"
export HAVEN_FRONTEND_DIR="${HAVEN_FRONTEND_DIR:-$(cd ../frontend && pwd)/dist}"
export HAVEN_GOGS_BASE_URL="${HAVEN_GOGS_BASE_URL:-https://gogs.example.com}"
# 本地是 HTTP + localhost，cookie 不能用 Secure、Domain 必须与访问地址一致
export HAVEN_COOKIE_SECURE="${HAVEN_COOKIE_SECURE:-false}"
export HAVEN_COOKIE_DOMAIN="${HAVEN_COOKIE_DOMAIN:-localhost}"
export HAVEN_LOG_LEVEL="${HAVEN_LOG_LEVEL:-debug}"

if [[ "${1:-}" == "build" ]]; then
  (cd ../frontend && pnpm build)
fi

echo "启动 Haven 后端"
echo "  监听      http://${HAVEN_LISTEN_ADDR}"
echo "  前端目录  ${HAVEN_FRONTEND_DIR}"
echo "  访问地址  http://localhost:${HAVEN_LISTEN_ADDR##*:}/"
echo
exec go run ./cmd/haven
