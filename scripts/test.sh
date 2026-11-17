#!/usr/bin/env bash
#
# 单元测试脚本。
#
# 用法：
#   ./scripts/test.sh all        # 前后端都跑
#   ./scripts/test.sh backend    # 只跑后端（含 spotless / checkstyle）
#   ./scripts/test.sh frontend   # 只跑前端（vue-tsc + vitest + Playwright E2E）
#   ./scripts/test.sh e2e        # 只跑 Playwright E2E（会自动构建 jar）
#
# 后端测试不读写开发库：默认在本地 PostgreSQL 上建临时 schema，
# 详见 docs/testing.md。需要容器时：
#   HAVEN_TEST_MODE=container ./scripts/test.sh backend
#
# E2E 需要先构建产物（会自动执行 build.sh all），并在独立 schema `haven_e2e` 上跑，
# 同样不碰开发库。首次运行需要下载浏览器：
#   pnpm --dir frontend exec playwright install chromium

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

if [ -t 1 ]; then
  info() { printf '\033[36m[test]\033[0m %s\n' "$*"; }
  ok()   { printf '\033[32m[test]\033[0m %s\n' "$*"; }
  err()  { printf '\033[31m[test]\033[0m %s\n' "$*" >&2; }
else
  info() { printf '[test] %s\n' "$*"; }
  ok()   { printf '[test] %s\n' "$*"; }
  err()  { printf '[test] %s\n' "$*" >&2; }
fi

usage() {
  # 打印文件头注释（从第 2 行到第一处非注释行）
  awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"
}


TARGET="${1:-}"
case "$TARGET" in
  all|backend|frontend|e2e) ;;
  ""|-h|--help) usage; exit 0 ;;
  *)
    err "未知参数：$TARGET"
    usage
    exit 1
    ;;
esac

EXIT_CODE=0

# 版本号一致性最先检查：不一致时后面的构建结果没有意义
info "版本号一致性"
"$ROOT_DIR/scripts/version.sh" check || {
  err "版本号不一致：执行 ./scripts/version.sh sync 修复"
  EXIT_CODE=1
}

run_backend() {
  [ -d "$BACKEND_DIR" ] || { err "找不到 backend 目录"; return 1; }
  cd "$BACKEND_DIR"

  info "格式检查（spotless）"
  ./mvnw spotless:check || { err "spotless 失败，可执行 ./mvnw spotless:apply 自动修复"; EXIT_CODE=1; }

  info "静态检查（checkstyle）"
  ./mvnw checkstyle:check || { err "checkstyle 失败"; EXIT_CODE=1; }

  info "运行后端测试"
  if [ "${HAVEN_TEST_MODE:-}" = "container" ]; then
    info "测试数据库：Testcontainers"
    ./mvnw test -Dhaven.test.mode=container || EXIT_CODE=1
  else
    info "测试数据库：本地 PostgreSQL 临时 schema（不读写 dev_db 业务表）"
    ./mvnw test || EXIT_CODE=1
  fi
}

run_frontend() {
  require_pnpm() {
    command -v pnpm >/dev/null 2>&1 || { err "缺少命令：pnpm"; return 1; }
  }
  require_pnpm || return 1
  [ -d "$FRONTEND_DIR" ] || { err "找不到 frontend 目录"; return 1; }
  cd "$FRONTEND_DIR"

  if [ ! -d node_modules ]; then
    info "node_modules 不存在，先安装依赖"
    pnpm install || { err "依赖安装失败"; return 1; }
  fi

  info "类型检查（vue-tsc）"
  pnpm exec vue-tsc -b || { err "类型检查失败"; EXIT_CODE=1; }

  info "运行前端测试（vitest）"
  pnpm test || EXIT_CODE=1

  info "运行端到端测试（Playwright）"
  run_e2e || EXIT_CODE=1
}

# E2E 跑在打包后的真实产物上（不是 Vite dev server），
# 所以必须先有 jar。webServer 由 Playwright 配置自己拉起和关闭。
run_e2e() {
  require_pnpm() {
    command -v pnpm >/dev/null 2>&1 || { err "缺少命令：pnpm"; return 1; }
  }
  require_pnpm || return 1
  [ -d "$FRONTEND_DIR" ] || { err "找不到 frontend 目录"; return 1; }

  info "准备 E2E 产物（后端 jar + 前端 dist）"
  "$ROOT_DIR/scripts/build.sh" all || { err "构建失败，E2E 无法运行"; return 1; }

  cd "$FRONTEND_DIR"
  if [ ! -d node_modules ]; then
    info "node_modules 不存在，先安装依赖"
    pnpm install || { err "依赖安装失败"; return 1; }
  fi

  info "运行 Playwright（独立 schema haven_e2e，不影响开发库）"
  pnpm e2e || return 1
}

case "$TARGET" in
  all)
    run_backend
    run_frontend
    ;;
  backend)  run_backend ;;
  frontend) run_frontend ;;
  e2e)      run_e2e || EXIT_CODE=1 ;;
esac

echo
if [ "$EXIT_CODE" -eq 0 ]; then
  ok "全部通过"
else
  err "有检查未通过"
fi
exit "$EXIT_CODE"
