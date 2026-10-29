#!/usr/bin/env bash
# Haven 本地改完代码后的「构建 + 安装 + 重启」脚本。
#
# 用法：
#   deploy/reload.sh                  只重建后端并重启 haven 服务
#   deploy/reload.sh --with-frontend  同时构建前端并安装到 /opt/haven/frontend/dist
#   deploy/reload.sh --migrate        先执行 migration，再构建重启
#   deploy/reload.sh --migrate --with-frontend
#
# 环境变量：
#   HAVEN_DB_DSN           migration 用的 DSN；不设置时尝试从 /etc/haven/haven.env 读取
#   HAVEN_SERVICE          systemd 服务名，默认 haven
#   HAVEN_INSTALL_ROOT     安装目录，默认 /opt/haven
#   HAVEN_RUN_USER         服务运行账号，默认 haven（用于安装文件属主）
#   HAVEN_HEALTH_URL       启动后的健康检查地址，默认 http://127.0.0.1:8080/api/health
#
# 说明：
#   - 安装 /opt/haven/bin/haven 与重启服务需要 sudo；
#   - 不传 --with-frontend 时不碰前端（本地通常由 Vite dev server 提供页面）。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE="${HAVEN_SERVICE:-haven}"
INSTALL_ROOT="${HAVEN_INSTALL_ROOT:-/opt/haven}"
RUN_USER="${HAVEN_RUN_USER:-haven}"
RUN_GROUP="${HAVEN_RUN_GROUP:-$RUN_USER}"
HEALTH_URL="${HAVEN_HEALTH_URL:-http://127.0.0.1:8080/api/health}"

do_migrate=0
with_frontend=0

for arg in "$@"; do
  case "$arg" in
    --migrate)        do_migrate=1 ;;
    --with-frontend)  with_frontend=1 ;;
    -h|--help)
      awk 'NR > 1 { if ($0 ~ /^#/) { sub(/^# ?/, ""); print } else exit }' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "未知参数: $arg（--help 查看用法）" >&2
      exit 2
      ;;
  esac
done

# 提前要一次 sudo 密码，避免构建完才停下来
sudo -v

read_dsn() {
  if [ -n "${HAVEN_DB_DSN:-}" ]; then
    printf '%s' "$HAVEN_DB_DSN"
    return 0
  fi

  local file="/etc/haven/haven.env"
  [ -e "$file" ] || return 1

  local raw
  if [ -r "$file" ]; then
    raw="$(sed -n 's/^[[:space:]]*\(export[[:space:]]\{1,\}\)\?HAVEN_DB_DSN=//p' "$file" | head -1)"
  else
    raw="$(sudo sed -n 's/^[[:space:]]*\(export[[:space:]]\{1,\}\)\?HAVEN_DB_DSN=//p' "$file" | head -1)"
  fi

  raw="${raw%\"}"
  raw="${raw#\"}"
  raw="${raw%\'}"
  raw="${raw#\'}"
  printf '%s' "$raw"
}

if [ "$do_migrate" -eq 1 ]; then
  echo "==> 执行 migration"
  DSN="$(read_dsn || true)"
  if [ -z "$DSN" ]; then
    echo "找不到 HAVEN_DB_DSN；请先 export HAVEN_DB_DSN=... 再运行" >&2
    exit 1
  fi
  HAVEN_DB_DSN="$DSN" "$REPO_ROOT/deploy/migrate.sh" up
fi

echo "==> 构建后端"
"$REPO_ROOT/deploy/build.sh" --backend-only

if [ "$with_frontend" -eq 1 ]; then
  echo "==> 构建前端"
  "$REPO_ROOT/deploy/build.sh" --frontend-only
fi

echo "==> 安装二进制到 $INSTALL_ROOT/bin/haven"
sudo install -d -o "$RUN_USER" -g "$RUN_GROUP" "$INSTALL_ROOT/bin"
sudo install -o "$RUN_USER" -g "$RUN_GROUP" -m 0755 \
  "$REPO_ROOT/deploy/out/bin/haven" "$INSTALL_ROOT/bin/haven"

if [ "$with_frontend" -eq 1 ]; then
  echo "==> 安装前端到 $INSTALL_ROOT/frontend/dist"
  sudo install -d -o "$RUN_USER" -g "$RUN_GROUP" "$INSTALL_ROOT/frontend"
  sudo rm -rf "$INSTALL_ROOT/frontend/dist"
  sudo cp -a "$REPO_ROOT/deploy/out/frontend/dist" "$INSTALL_ROOT/frontend/dist"
  sudo chown -R "$RUN_USER:$RUN_GROUP" "$INSTALL_ROOT/frontend"
fi

echo "==> 重启 $SERVICE"
sudo systemctl restart "$SERVICE"
sleep 1

if sudo systemctl is-active --quiet "$SERVICE"; then
  echo "    $SERVICE 正在运行"
else
  echo "    $SERVICE 启动失败，最近日志：" >&2
  sudo journalctl -u "$SERVICE" -n 30 --no-pager >&2 || true
  exit 1
fi

if command -v curl >/dev/null 2>&1; then
  if curl -fsS --max-time 3 "$HEALTH_URL" >/dev/null; then
    echo "    健康检查通过：$HEALTH_URL"
  else
    echo "    健康检查未通过：$HEALTH_URL（如端口不同，可用 HAVEN_HEALTH_URL 覆盖）" >&2
  fi
fi
