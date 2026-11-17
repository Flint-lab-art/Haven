#!/usr/bin/env bash
#
# 打包脚本。
#
# 产物形态：前端的 dist 会被复制进 backend/src/main/resources/static/，
# 后端打成可执行 jar，一个文件同时提供 API 与前端静态资源。
#
# 用法：
#   ./scripts/build.sh all         # 清空 static → 构建前端并复制 → 打包 jar
#   ./scripts/build.sh backend     # 只打包 jar（保留现有 static）
#   ./scripts/build.sh frontend    # 只构建前端并复制到 static
#
# 说明：
#   - all 会先删除 static 下的全部内容，避免旧哈希文件残留；
#   - backend 不碰 static，适合「已经 build 过前端、只改了后端」的场景；
#   - frontend 不打包 jar，适合只想更新静态资源的场景；
#   - 两个子命令都会先校验版本号（来源：根目录 VERSION 文件）。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
STATIC_DIR="$BACKEND_DIR/src/main/resources/static"

if [ -t 1 ]; then
  info() { printf '\033[36m[build]\033[0m %s\n' "$*"; }
  ok()   { printf '\033[32m[build]\033[0m %s\n' "$*"; }
  err()  { printf '\033[31m[build]\033[0m %s\n' "$*" >&2; }
else
  info() { printf '[build] %s\n' "$*"; }
  ok()   { printf '[build] %s\n' "$*"; }
  err()  { printf '[build] %s\n' "$*" >&2; }
fi

usage() {
  # 打印文件头注释（从第 2 行到第一处非注释行）
  awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"
}


TARGET="${1:-}"
case "$TARGET" in
  all|backend|frontend) ;;
  ""|-h|--help) usage; exit 0 ;;
  *)
    err "未知参数：$TARGET"
    usage
    exit 1
    ;;
esac

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "缺少命令：$1"
    exit 1
  }
}

# ---------------------------------------------------------------------------
# 前端：构建并复制 dist → backend static
# ---------------------------------------------------------------------------
build_frontend() {
  require_cmd pnpm
  [ -d "$FRONTEND_DIR" ] || { err "找不到 frontend 目录"; exit 1; }

  # package.json 的 version 由 scripts/version.sh 维护，这里确保与 VERSION 一致
  "$ROOT_DIR/scripts/version.sh" check >/dev/null || {
    err "版本号不一致，先执行 ./scripts/version.sh sync"
    exit 1
  }

  cd "$FRONTEND_DIR"
  if [ ! -d node_modules ]; then
    info "node_modules 不存在，先安装依赖"
    pnpm install
  fi

  info "构建前端（vue-tsc 类型检查 + vite build）"
  pnpm build

  [ -f "$FRONTEND_DIR/dist/index.html" ] || {
    err "前端构建产物缺失：$FRONTEND_DIR/dist/index.html"
    exit 1
  }

  info "清空 $STATIC_DIR"
  mkdir -p "$STATIC_DIR"
  # 用 find + rm 而不是 rm -rf 目录本身，避免权限/挂载点问题
  find "$STATIC_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

  info "复制 dist → static"
  cp -R "$FRONTEND_DIR/dist/." "$STATIC_DIR/"
  ok "前端已就位：$STATIC_DIR"
}

# ---------------------------------------------------------------------------
# 后端：打包 jar（内含当时 static 里的内容）
# ---------------------------------------------------------------------------
build_backend() {
  [ -d "$BACKEND_DIR" ] || { err "找不到 backend 目录"; exit 1; }

  # 版本号只有一个来源（根目录 VERSION），这里兜底防止有人手改了 pom / package.json
  "$ROOT_DIR/scripts/version.sh" check || {
    err "版本号不一致，先执行 ./scripts/version.sh sync"
    exit 1
  }

  if [ ! -f "$STATIC_DIR/index.html" ]; then
    info "提示：static 里没有 index.html，打出来的 jar 将不包含前端页面"
  fi

  cd "$BACKEND_DIR"
  info "打包后端（clean package，跳过测试；测试请用 ./scripts/test.sh）"
  ./mvnw clean package -DskipTests

  JAR=$(ls -1t target/*.jar 2>/dev/null | grep -v -- '-sources\.jar$' | head -n 1 || true)
  [ -n "$JAR" ] || { err "未找到打包产物"; exit 1; }
  ok "后端产物：$BACKEND_DIR/$JAR"
  JAR_SIZE=$(du -h "$JAR" | cut -f1)
  ok "大小：$JAR_SIZE"
}

case "$TARGET" in
  all)
    build_frontend
    build_backend
    ok "全部完成"
    ;;
  frontend)
    build_frontend
    ;;
  backend)
    build_backend
    ;;
esac
