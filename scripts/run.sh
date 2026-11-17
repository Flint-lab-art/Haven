#!/usr/bin/env bash
#
# 本地开发启动脚本。
#
# 为什么只需要跑后端：
#   构建时前端的 dist 会被复制进 backend/src/main/resources/static/，
#   后端同时提供 API 与静态资源，前后端同源，不需要单独起 Vite 开发服务器。
#   所以本地开发只要 ./scripts/run.sh 一条命令。
#
# 用法：
#   ./scripts/run.sh               # 直接启动（使用 dev profile）
#   ./scripts/run.sh --clean       # 先清理 target 再启动
#   ./scripts/run.sh -Dxxx=yyy     # 透传额外参数给 Maven
#
# 可用环境变量（都会原样传给 Spring Boot）：
#   SPRING_PROFILES_ACTIVE   profile，默认 dev
#   DB_URL / DB_USERNAME / DB_PASSWORD   数据源覆盖
#   HAVEN_PRIVATE_HOSTS      私有域域名
#   HAVEN_UPLOAD_DIR         上传目录
#   HAVEN_TIME_ZONE          业务时区

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"

# 输出用颜色（非终端时不加颜色，避免日志里出现转义符）
if [ -t 1 ]; then
  info() { printf '\033[36m[run]\033[0m %s\n' "$*"; }
  warn() { printf '\033[33m[run]\033[0m %s\n' "$*"; }
  err()  { printf '\033[31m[run]\033[0m %s\n' "$*" >&2; }
else
  info() { printf '[run] %s\n' "$*"; }
  warn() { printf '[run] %s\n' "$*"; }
  err()  { printf '[run] %s\n' "$*" >&2; }
fi

usage() {
  # 打印文件头注释（从第 2 行到第一处非注释行）
  awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"
}

CLEAN=0
EXTRA_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) EXTRA_ARGS+=("$arg") ;;
  esac
done

if [ ! -d "$BACKEND_DIR" ]; then
  err "找不到 backend 目录：$BACKEND_DIR"
  exit 1
fi

if [ ! -x "$BACKEND_DIR/mvnw" ]; then
  err "找不到 Maven Wrapper：$BACKEND_DIR/mvnw"
  exit 1
fi

cd "$BACKEND_DIR"

# 提示静态资源是否已就绪：没有的话后端会把所有前端路由落成 404
STATIC_DIR="$BACKEND_DIR/src/main/resources/static"
if [ ! -f "$STATIC_DIR/index.html" ]; then
  warn "静态资源目录为空，前端页面会 404。"
  warn "先执行 ./scripts/build.sh all（或 build.sh frontend）把前端产物复制进来。"
fi

PROFILE="${SPRING_PROFILES_ACTIVE:-dev}"
info "profile = $PROFILE"
info "数据源   = ${DB_URL:-（使用 application-dev.yaml 的默认值）}"

GOALS=(spring-boot:run)
[ "$CLEAN" -eq 1 ] && GOALS=(clean "${GOALS[@]}")

if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
  info "额外参数 = ${EXTRA_ARGS[*]}"
  exec ./mvnw "${GOALS[@]}" "${EXTRA_ARGS[@]}"
else
  exec ./mvnw "${GOALS[@]}"
fi
