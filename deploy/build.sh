#!/usr/bin/env bash
# Haven 构建脚本：把后端二进制与前端静态文件产物集中到 deploy/out/。
#
# 依据 docs/architecture.md 第七节：后端同时托管前端静态文件，
# 因此部署产物只需要一份二进制 + 一份 dist。
#
# 用法：
#   deploy/build.sh                 构建后端 + 前端
#   deploy/build.sh --backend-only  只构建后端（前端未调好时用这个）
#   deploy/build.sh --frontend-only 只构建前端
#
# 产物：
#   deploy/out/bin/haven            后端二进制
#   deploy/out/bin/haven-init-user  初始化唯一账号的一次性工具
#   deploy/out/frontend/dist/       前端静态文件
#   deploy/out/migrations/          SQL migration
#   deploy/out/migrate.sh           migration 执行脚本
#
# 环境变量（均可选）：
#   HAVEN_BUILD_DIR  输出目录，默认 <repo>/deploy/out
#   HAVEN_GO_BIN     go 可执行文件，默认 go
#
# 脚本不负责安装到 /opt/haven，也不重启服务，见 deploy/README.md。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${HAVEN_BUILD_DIR:-$REPO_ROOT/deploy/out}"
GO_BIN="${HAVEN_GO_BIN:-go}"

build_backend=1
build_frontend=1

for arg in "$@"; do
  case "$arg" in
    --backend-only)  build_frontend=0 ;;
    --frontend-only) build_backend=0 ;;
    -h|--help)       sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $arg（--help 查看用法）" >&2; exit 2 ;;
  esac
done

if [ "$build_backend" -eq 1 ]; then
  echo "==> 构建后端"
  mkdir -p "$OUT_DIR/bin"
  (
    cd "$REPO_ROOT/backend"
    CGO_ENABLED=0 "$GO_BIN" build -trimpath -ldflags="-s -w" \
      -o "$OUT_DIR/bin/haven" ./cmd/haven
    CGO_ENABLED=0 "$GO_BIN" build -trimpath -ldflags="-s -w" \
      -o "$OUT_DIR/bin/haven-init-user" ./cmd/haven-init-user
  )
  echo "    $OUT_DIR/bin/haven"
  echo "    $OUT_DIR/bin/haven-init-user"
fi

if [ "$build_frontend" -eq 1 ]; then
  echo "==> 构建前端"
  if [ ! -d "$REPO_ROOT/frontend/node_modules" ]; then
    ( cd "$REPO_ROOT/frontend" && pnpm install --frozen-lockfile )
  fi
  ( cd "$REPO_ROOT/frontend" && pnpm build )
  rm -rf "$OUT_DIR/frontend"
  mkdir -p "$OUT_DIR/frontend"
  cp -a "$REPO_ROOT/frontend/dist" "$OUT_DIR/frontend/dist"
  echo "    $OUT_DIR/frontend/dist"
fi

# migration 与执行脚本一起打包，方便服务器上独立运行（不依赖仓库）
rm -rf "$OUT_DIR/migrations"
cp -a "$REPO_ROOT/backend/migrations" "$OUT_DIR/migrations"
cp -a "$REPO_ROOT/deploy/migrate.sh" "$OUT_DIR/migrate.sh"
chmod +x "$OUT_DIR/migrate.sh"

echo
echo "构建完成：$OUT_DIR"
