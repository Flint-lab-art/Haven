#!/usr/bin/env bash
# Haven 一键部署脚本（前后端一起）。
#
# 用法（不要用 sudo 运行，脚本内部会按需提权）：
#   deploy/deploy.sh                    构建 + 安装 + migration + 重启
#   deploy/deploy.sh --reset            先清空旧部署（保留数据库与 /etc/haven 配置）
#   deploy/deploy.sh --reset-db         删除并重建数据库（会自动先备份），再重新部署
#   deploy/deploy.sh --reset --reset-db --caddy --backup-db
#                                       完全重装：清空文件 + 重建数据库 + 切换 Caddy
#   deploy/deploy.sh --backup-db        部署前用 pg_dump 备份数据库
#   deploy/deploy.sh --skip-migrate     跳过 migration
#   deploy/deploy.sh --yes              跳过 --reset-db 的交互确认（自动化用）
#
# 可覆盖的环境变量：
#   VITE_PRIVATE_HOST     构建时私有域，默认读 /etc/haven/haven.env 的 HAVEN_COOKIE_DOMAIN
#   HAVEN_SERVICE         systemd 服务名，默认 haven
#   HAVEN_INSTALL_ROOT    安装目录，默认 /opt/haven
#   HAVEN_RUN_USER        运行账号，默认 haven
#   HAVEN_ENV_FILE        环境变量文件，默认 /etc/haven/haven.env
#   HAVEN_CADDYFILE       Caddy 配置，默认 /etc/caddy/Caddyfile
#   HAVEN_CADDY_SERVICE   Caddy 服务名，默认 caddy
#   HAVEN_DB_NAME         --reset-db 的目标库名，默认从 HAVEN_DB_DSN 解析
#   HAVEN_DB_OWNER        目标库 owner，默认 haven
#
# 清空范围：
#   --reset     只删除安装目录、停止 Haven 服务；不动数据库与 env。
#   --reset-db  删除并重建数据库（数据全部丢失，默认先 pg_dump 备份），
#               之后重新执行 migration 并用 HAVEN_INIT_PASSWORD / 交互输入
#               重建唯一账号；TOTP、会话、Token 全部重置。
#   Caddy 切换是单独的 --caddy 开关。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE="${HAVEN_SERVICE:-haven}"
INSTALL_ROOT="${HAVEN_INSTALL_ROOT:-/opt/haven}"
RUN_USER="${HAVEN_RUN_USER:-haven}"
RUN_GROUP="${HAVEN_RUN_GROUP:-$RUN_USER}"
ENV_FILE="${HAVEN_ENV_FILE:-/etc/haven/haven.env}"
CADDYFILE="${HAVEN_CADDYFILE:-/etc/caddy/Caddyfile}"
CADDY_SERVICE="${HAVEN_CADDY_SERVICE:-caddy}"

do_reset=0
do_reset_db=0
do_caddy=0
do_backup=0
do_migrate=1
assume_yes=0
timestamp="$(date +%Y%m%d-%H%M%S)"

for arg in "$@"; do
  case "$arg" in
    --reset)        do_reset=1 ;;
    --reset-db)     do_reset_db=1; do_backup=1 ;;
    --caddy)        do_caddy=1 ;;
    --backup-db)    do_backup=1 ;;
    --skip-migrate) do_migrate=0 ;;
    --yes)          assume_yes=1 ;;
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

if [ "$(id -u)" -eq 0 ]; then
  echo "不要用 sudo/root 直接运行；脚本会在需要时自己调用 sudo。" >&2
  exit 1
fi

case "$INSTALL_ROOT" in
  ""|"/"|*..*) echo "HAVEN_INSTALL_ROOT 不安全: $INSTALL_ROOT" >&2; exit 1 ;;
esac
[[ "$INSTALL_ROOT" = /* ]] || {
  echo "HAVEN_INSTALL_ROOT 必须是绝对路径: $INSTALL_ROOT" >&2
  exit 1
}

for bin in go pnpm; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "缺少命令: $bin" >&2
    exit 1
  }
done
if [ "$do_migrate" -eq 1 ] || [ "$do_reset_db" -eq 1 ]; then
  command -v psql >/dev/null 2>&1 || {
    echo "缺少命令: psql（migration / --reset-db 需要）" >&2
    exit 1
  }
fi

if [ "$do_reset_db" -eq 1 ] && [ "$do_migrate" -eq 0 ]; then
  echo "--reset-db 需要重新执行 migration，不能和 --skip-migrate 一起用" >&2
  exit 1
fi

sudo -v

env_value() {
  local key="$1" raw
  raw="$(sudo sed -n "s/^[[:space:]]*\(export[[:space:]]\{1,\}\)\?${key}=//p" "$ENV_FILE" | head -n1)" || true
  raw="${raw%\"}"; raw="${raw#\"}"
  raw="${raw%\'}"; raw="${raw#\'}"
  printf '%s' "$raw"
}

# 首次部署：只安装模板，让用户填 DSN 后再重跑；不动旧部署
# 注意：/etc/haven 可能只有 root 能进入，必须用 sudo 判断文件是否存在，
# 否则会把已存在的生产配置误判为不存在并用模板覆盖。
if ! sudo test -f "$ENV_FILE"; then
  if sudo test -e "$ENV_FILE"; then
    echo "$ENV_FILE 存在但不是普通文件，已中止" >&2
    exit 1
  fi
  echo "==> 创建 $ENV_FILE"
  sudo install -d -m 0750 "$(dirname "$ENV_FILE")"
  sudo install -m 0600 "$REPO_ROOT/deploy/haven.env.example" "$ENV_FILE"
  echo "已生成环境变量模板，请先编辑 $ENV_FILE（至少填 HAVEN_DB_DSN 与 HAVEN_COOKIE_DOMAIN），然后重跑。" >&2
  exit 1
fi

FRONTEND_DIR="$(env_value HAVEN_FRONTEND_DIR)"
# 上传目录：图片存这里，数据库只存路径（docs/v4/conventions.md 第三节）
UPLOAD_DIR="$(env_value HAVEN_UPLOAD_DIR)"
LISTEN_ADDR="$(env_value HAVEN_LISTEN_ADDR)"
COOKIE_DOMAIN="$(env_value HAVEN_COOKIE_DOMAIN)"
DB_DSN="${HAVEN_DB_DSN:-$(env_value HAVEN_DB_DSN)}"

[ -n "$FRONTEND_DIR" ] || FRONTEND_DIR="$INSTALL_ROOT/frontend/dist"
[ -n "$UPLOAD_DIR" ] || UPLOAD_DIR="$INSTALL_ROOT/uploads"
[ -n "$LISTEN_ADDR" ] || LISTEN_ADDR="127.0.0.1:8080"
[ -n "$COOKIE_DOMAIN" ] || COOKIE_DOMAIN=""

PORT="${LISTEN_ADDR##*:}"
[[ "$PORT" =~ ^[0-9]+$ ]] || {
  echo "HAVEN_LISTEN_ADDR 端口非法: $LISTEN_ADDR" >&2
  exit 1
}
HEALTH_URL="http://127.0.0.1:${PORT}/api/health"

DB_NAME="${HAVEN_DB_NAME:-}"
DB_OWNER="${HAVEN_DB_OWNER:-haven}"
DB_EXISTS=0
INIT_USER="${HAVEN_INIT_USERNAME:-kairo}"
INIT_PASSWORD="${HAVEN_INIT_PASSWORD:-}"

if [ "$do_reset_db" -eq 1 ]; then
  [ -n "$DB_DSN" ] || {
    echo "--reset-db 需要 HAVEN_DB_DSN" >&2
    exit 1
  }
  # 不连接目标库（它可能还不存在），直接从 DSN 解析库名
  if [ -z "$DB_NAME" ]; then
    if [[ "$DB_DSN" == postgres://* || "$DB_DSN" == postgresql://* ]]; then
      _path="${DB_DSN%%\?*}"
      DB_NAME="${_path##*/}"
    else
      DB_NAME="$(printf '%s' "$DB_DSN" | sed -n 's/.*dbname=\([^ ]*\).*/\1/p')"
    fi
  fi
  if [[ ! "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || [[ ! "$DB_OWNER" =~ ^[A-Za-z0-9_]+$ ]]; then
    echo "数据库名 / owner 非法（可用 HAVEN_DB_NAME / HAVEN_DB_OWNER 指定）: name=$DB_NAME owner=$DB_OWNER" >&2
    exit 1
  fi

  DB_EXISTS="$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | tr -d '[:space:]')"
  [ "$DB_EXISTS" = "1" ] || DB_EXISTS=0

  if [ -z "$INIT_PASSWORD" ]; then
    if [ -t 0 ]; then
      read -rsp "设置 $INIT_USER 的登录密码（至少 12 位，输入不回显）: " INIT_PASSWORD
      echo
    else
      echo "非交互运行请设置 HAVEN_INIT_PASSWORD（至少 12 位）" >&2
      exit 1
    fi
  fi
  if [ "${#INIT_PASSWORD}" -lt 12 ]; then
    echo "初始密码至少 12 位" >&2
    exit 1
  fi

  if [ "$assume_yes" -ne 1 ]; then
    echo "警告：即将永久删除数据库 $DB_NAME 的全部数据（会先备份）。" >&2
    printf '请输入数据库名 %s 确认: ' "$DB_NAME" >&2
    read -r confirm
    [ "$confirm" = "$DB_NAME" ] || {
      echo "确认失败，已取消" >&2
      exit 1
    }
  fi
fi

# 前后端必须使用同一个 dist 目录，否则后端会继续托管旧目录
if [ "$FRONTEND_DIR" != "$INSTALL_ROOT/frontend/dist" ]; then
  echo "==> 修正 HAVEN_FRONTEND_DIR -> $INSTALL_ROOT/frontend/dist"
  sudo cp -a "$ENV_FILE" "$ENV_FILE.bak.$timestamp"
  if sudo grep -q '^HAVEN_FRONTEND_DIR=' "$ENV_FILE"; then
    sudo sed -i "s#^HAVEN_FRONTEND_DIR=.*#HAVEN_FRONTEND_DIR=$INSTALL_ROOT/frontend/dist#" "$ENV_FILE"
  else
    printf '\nHAVEN_FRONTEND_DIR=%s\n' "$INSTALL_ROOT/frontend/dist" | sudo tee -a "$ENV_FILE" >/dev/null
  fi
  FRONTEND_DIR="$INSTALL_ROOT/frontend/dist"
fi

# 前端构建需要知道哪个 host 是私有域
if [ -z "${VITE_PRIVATE_HOST:-}" ]; then
  VITE_PRIVATE_HOST="$COOKIE_DOMAIN"
fi
if [ -z "$VITE_PRIVATE_HOST" ] || [ "$VITE_PRIVATE_HOST" = "localhost" ]; then
  echo "无法确定私有域：请在 $ENV_FILE 设置 HAVEN_COOKIE_DOMAIN，或显式传 VITE_PRIVATE_HOST=你的私有域名" >&2
  exit 1
fi

dump_database() {
  [ -n "$DB_DSN" ] || {
    echo "备份数据库需要 HAVEN_DB_DSN" >&2
    exit 1
  }
  command -v pg_dump >/dev/null 2>&1 || {
    echo "缺少命令: pg_dump" >&2
    exit 1
  }

  local backup_dir="/var/backups/haven"
  local tmp="/tmp/haven-db-$timestamp.sql.gz"
  echo "==> 备份数据库到 $backup_dir"
  sudo install -d -m 0700 "$backup_dir"
  ( umask 077; pg_dump "$DB_DSN" | gzip > "$tmp" )
  sudo install -m 0600 "$tmp" "$backup_dir/haven-$timestamp.sql.gz"
  rm -f "$tmp"
  echo "    $backup_dir/haven-$timestamp.sql.gz"
}

switch_caddy() {
  command -v caddy >/dev/null 2>&1 || {
    echo "未找到 caddy，跳过 Caddy 切换" >&2
    return 0
  }
  [ -f "$CADDYFILE" ] || {
    echo "未找到 $CADDYFILE，跳过 Caddy 切换" >&2
    return 0
  }

  sudo cp -a "$CADDYFILE" "$CADDYFILE.bak.$timestamp"
  if ! sudo grep -qE '(127\.0\.0\.1|localhost):5173' "$CADDYFILE"; then
    echo "Caddyfile 中没有发现 5173 的 Vite 反代，跳过（已备份）" >&2
    return 0
  fi

  echo "==> 把 Caddy 的 Vite 5173 反代切到后端 $PORT"
  sudo sed -i -E "s#(127\.0\.0\.1|localhost):5173#127.0.0.1:${PORT}#g" "$CADDYFILE"

  if ! sudo caddy validate --config "$CADDYFILE" >/dev/null; then
    echo "Caddy 配置校验失败，已恢复备份" >&2
    sudo cp -a "$CADDYFILE.bak.$timestamp" "$CADDYFILE"
    exit 1
  fi
  sudo systemctl reload "$CADDY_SERVICE"
}

# ---------------------------------------------------------------------------
# 1. 构建（先构建，构建失败不会动旧部署）
# ---------------------------------------------------------------------------
echo "==> 构建前端与后端（VITE_PRIVATE_HOST=$VITE_PRIVATE_HOST）"
VITE_PRIVATE_HOST="$VITE_PRIVATE_HOST" "$REPO_ROOT/deploy/build.sh"

# ---------------------------------------------------------------------------
# 2. 可选：备份数据库，然后清空旧部署
# ---------------------------------------------------------------------------
if [ "$do_backup" -eq 1 ]; then
  if [ "$do_reset_db" -eq 1 ] && [ "$DB_EXISTS" -ne 1 ]; then
    echo "目标数据库 $DB_NAME 尚不存在，跳过备份"
  else
    dump_database
  fi
fi

if [ "$do_reset" -eq 1 ] || [ "$do_reset_db" -eq 1 ]; then
  echo "==> 停止 $SERVICE"
  sudo systemctl stop "$SERVICE" 2>/dev/null || true
fi

if [ "$do_reset_db" -eq 1 ]; then
  echo "==> 删除并重建数据库 $DB_NAME（owner: $DB_OWNER）"
  sudo -u postgres psql -v ON_ERROR_STOP=1 -d postgres <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS "$DB_NAME";
CREATE DATABASE "$DB_NAME" OWNER "$DB_OWNER";
SQL
fi

if [ "$do_reset" -eq 1 ]; then
  echo "==> 清空旧部署目录 $INSTALL_ROOT（数据库与 $ENV_FILE 保留）"
  # 上传目录若在安装目录内（默认 /opt/haven/uploads），清空时跳过它：
  # 用户上传的图片不属于部署产物，--reset 只是重装程序，不该删数据。
  if [[ "$UPLOAD_DIR" == "$INSTALL_ROOT"/* ]]; then
    echo "==> 保留上传目录 $UPLOAD_DIR"
    sudo find "$INSTALL_ROOT" -mindepth 1 -maxdepth 1 \
      ! -path "$UPLOAD_DIR" -exec rm -rf {} +
  else
    sudo rm -rf "$INSTALL_ROOT"
  fi
fi

# ---------------------------------------------------------------------------
# 3. 安装产物
# ---------------------------------------------------------------------------
echo "==> 安装到 $INSTALL_ROOT"
sudo install -d -o "$RUN_USER" -g "$RUN_GROUP" "$INSTALL_ROOT/bin"
sudo install -d -o "$RUN_USER" -g "$RUN_GROUP" "$INSTALL_ROOT/frontend"
sudo install -d -o "$RUN_USER" -g "$RUN_GROUP" "$INSTALL_ROOT/migrations"

# 上传目录单独创建：--reset 会删掉整个安装目录，但用户上传的图片必须保留，
# 所以这里每次部署都确保它存在并属于运行账号（docs/v4/conventions.md 第三节）。
echo "==> 上传目录 $UPLOAD_DIR"
sudo install -d -o "$RUN_USER" -g "$RUN_GROUP" -m 0755 "$UPLOAD_DIR"

sudo install -m 0755 "$REPO_ROOT/deploy/out/bin/haven" "$INSTALL_ROOT/bin/haven"
sudo install -m 0755 "$REPO_ROOT/deploy/out/bin/haven-init-user" "$INSTALL_ROOT/bin/haven-init-user"
sudo cp -a "$REPO_ROOT/deploy/out/migrations/." "$INSTALL_ROOT/migrations/"
sudo install -m 0755 "$REPO_ROOT/deploy/out/migrate.sh" "$INSTALL_ROOT/migrate.sh"

sudo rm -rf "$INSTALL_ROOT/frontend/dist"
sudo cp -a "$REPO_ROOT/deploy/out/frontend/dist" "$INSTALL_ROOT/frontend/dist"
sudo chown -R "$RUN_USER:$RUN_GROUP" "$INSTALL_ROOT/frontend" "$INSTALL_ROOT/migrations"

sudo install -m 0644 "$REPO_ROOT/deploy/haven.service" "/etc/systemd/system/${SERVICE}.service"

# ---------------------------------------------------------------------------
# 4. migration
# ---------------------------------------------------------------------------
if [ "$do_migrate" -eq 1 ]; then
  [ -n "$DB_DSN" ] || {
    echo "HAVEN_DB_DSN 为空，无法执行 migration（可加 --skip-migrate）" >&2
    exit 1
  }
  echo "==> 执行 migration"
  HAVEN_DB_DSN="$DB_DSN" HAVEN_MIGRATIONS_DIR="$INSTALL_ROOT/migrations" \
    "$INSTALL_ROOT/migrate.sh" up
fi

if [ "$do_reset_db" -eq 1 ]; then
  echo "==> 重建唯一账号 $INIT_USER"
  HAVEN_DB_DSN="$DB_DSN" HAVEN_INIT_PASSWORD="$INIT_PASSWORD" \
    "$INSTALL_ROOT/bin/haven-init-user" -username "$INIT_USER"
fi

# ---------------------------------------------------------------------------
# 5. 启动
# ---------------------------------------------------------------------------
echo "==> 启动 $SERVICE"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE" >/dev/null
sudo systemctl restart "$SERVICE"
sleep 1

if ! sudo systemctl is-active --quiet "$SERVICE"; then
  echo "$SERVICE 启动失败，最近日志：" >&2
  sudo journalctl -u "$SERVICE" -n 40 --no-pager >&2 || true
  exit 1
fi

# ---------------------------------------------------------------------------
# 6. 可选：Caddy 从 Vite 切到后端
# ---------------------------------------------------------------------------
if [ "$do_caddy" -eq 1 ]; then
  switch_caddy
fi

# ---------------------------------------------------------------------------
# 7. 健康检查
# ---------------------------------------------------------------------------
if command -v curl >/dev/null 2>&1; then
  if curl -fsS --max-time 5 "$HEALTH_URL" >/dev/null; then
    echo "==> 健康检查通过：$HEALTH_URL"
  else
    echo "健康检查未通过：$HEALTH_URL" >&2
    exit 1
  fi
fi

echo
echo "部署完成"
echo "  后端:   $INSTALL_ROOT/bin/haven"
echo "  前端:   $INSTALL_ROOT/frontend/dist"
echo "  私有域: $VITE_PRIVATE_HOST"
if [ "$do_reset_db" -eq 1 ]; then
  echo "  数据库: 已重建（账号: $INIT_USER）"
else
  echo "  数据库: 未清空"
fi
[ "$do_backup" -eq 1 ] && echo "  备份:   /var/backups/haven/haven-$timestamp.sql.gz"
echo
echo "如果浏览器仍看到旧页面，请检查 Caddy 是否指向 127.0.0.1:$PORT（或用 --caddy 自动切换）。"
