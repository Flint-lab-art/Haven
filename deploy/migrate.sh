#!/usr/bin/env bash
# Haven 数据库 migration 执行脚本。
#
# 依据 docs/architecture.md 5.6：migration 由部署脚本执行，
# 后端启动时不自动跑（避免并发启动冲突与误执行）。
#
# 用法：
#   deploy/migrate.sh status     查看每个 migration 是否已应用
#   deploy/migrate.sh up         按文件名顺序应用所有未执行的 *.up.sql
#   deploy/migrate.sh down [N]   回滚最近 N 个版本（默认 1）
#   deploy/migrate.sh version    打印当前版本号
#
# 配置（环境变量，与后端配置来源一致）：
#   HAVEN_DB_DSN          必填，PostgreSQL 连接串
#   HAVEN_MIGRATIONS_DIR  可选，migration 目录，默认 <repo>/backend/migrations
#
# 版本表：schema_migrations(version bigint, dirty boolean)。
# 与 golang-migrate 同名字段，将来换成 golang-migrate CLI 可直接衔接。
#
# 每个 migration 文件在单个事务内执行（psql -1），失败即整体回滚并保留
# dirty 标记；dirty 为真时脚本拒绝继续，需人工确认后清理。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "${HAVEN_DB_DSN:-}" ]; then
  echo "缺少 HAVEN_DB_DSN（PostgreSQL 连接串）" >&2
  exit 1
fi

DSN="$HAVEN_DB_DSN"
MIG_DIR="${HAVEN_MIGRATIONS_DIR:-$REPO_ROOT/backend/migrations}"

if [ ! -d "$MIG_DIR" ]; then
  echo "migration 目录不存在: $MIG_DIR" >&2
  exit 1
fi

q()   { psql "$DSN" -v ON_ERROR_STOP=1 -q -t -A -c "$1"; }
run() { psql "$DSN" -v ON_ERROR_STOP=1 -q -1 -f "$1"; }

# 建立版本表（与 golang-migrate 兼容）
q "CREATE TABLE IF NOT EXISTS schema_migrations (
     version bigint  NOT NULL PRIMARY KEY,
     dirty   boolean NOT NULL DEFAULT false
   );" >/dev/null

# 已有 schema 但没有版本记录（例如手工执行过 0001）：基线到 0001，不重复建表
if [ "$(q "SELECT count(*) FROM schema_migrations;")" = "0" ] \
   && [ "$(q "SELECT to_regclass('public.users') IS NOT NULL;")" = "t" ]; then
  q "INSERT INTO schema_migrations (version, dirty) VALUES (1, false);" >/dev/null
  echo "检测到已有 schema 但无版本记录，已基线到 0001（不重复执行）" >&2
fi

current_version() {
  local v
  v="$(q "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;")"
  printf '%s' "${v:-0}"
}

is_dirty() {
  [ "$(q "SELECT dirty FROM schema_migrations ORDER BY version DESC LIMIT 1;")" = "t" ]
}

mark_dirty() { q "DELETE FROM schema_migrations;
                  INSERT INTO schema_migrations (version, dirty) VALUES ($1, true);" >/dev/null; }
mark_clean() { q "DELETE FROM schema_migrations;
                  INSERT INTO schema_migrations (version, dirty) VALUES ($1, false);" >/dev/null; }

# 升序的 up 文件列表
mapfile -t UP_FILES < <(find "$MIG_DIR" -maxdepth 1 -name '[0-9]*_*.up.sql' -printf '%f\n' | sort)
if [ "${#UP_FILES[@]}" -eq 0 ]; then
  echo "在 $MIG_DIR 下没有找到 migration 文件" >&2
  exit 1
fi

version_of() { printf '%s' "$((10#${1%%_*}))"; }

down_file_for() {
  local v="$1" f
  for f in "$MIG_DIR"/*.down.sql; do
    [ -e "$f" ] || continue
    if [ "$(version_of "$(basename "$f")")" = "$v" ]; then
      printf '%s' "$f"
      return 0
    fi
  done
  return 1
}

previous_version() {
  local cur="$1" v prev=0
  for f in "${UP_FILES[@]}"; do
    v="$(version_of "$f")"
    if [ "$v" -lt "$cur" ] && [ "$v" -gt "$prev" ]; then prev="$v"; fi
  done
  printf '%s' "$prev"
}

cmd="${1:-status}"

case "$cmd" in
  version)
    current_version; echo
    ;;

  status)
    cur="$(current_version)"
    echo "migration 目录: $MIG_DIR"
    echo "当前版本:      $cur"
    is_dirty && echo "状态:          DIRTY（上次执行失败，需人工处理）"
    echo
    for f in "${UP_FILES[@]}"; do
      v="$(version_of "$f")"
      if [ "$v" -le "$cur" ]; then
        printf '  [x] %s\n' "$f"
      else
        printf '  [ ] %s\n' "$f"
      fi
    done
    ;;

  up)
    if is_dirty; then
      echo "schema_migrations 处于 dirty 状态，拒绝继续。请人工核对后用 SQL 清理该行。" >&2
      exit 1
    fi
    cur="$(current_version)"
    applied=0
    for f in "${UP_FILES[@]}"; do
      v="$(version_of "$f")"
      [ "$v" -le "$cur" ] && continue
      echo "==> 应用 $f"
      mark_dirty "$v"
      if ! run "$MIG_DIR/$f"; then
        echo "执行失败，schema_migrations 已标记 dirty（version=$v）。" >&2
        exit 1
      fi
      mark_clean "$v"
      applied=$((applied + 1))
    done
    if [ "$applied" -eq 0 ]; then
      echo "已是最新版本（$cur），无需执行"
    else
      echo "完成，当前版本: $(current_version)"
    fi
    ;;

  down)
    steps="${2:-1}"
    if is_dirty; then
      echo "schema_migrations 处于 dirty 状态，拒绝继续。请人工核对后用 SQL 清理该行。" >&2
      exit 1
    fi
    for ((i = 0; i < steps; i++)); do
      cur="$(current_version)"
      if [ "$cur" -eq 0 ]; then
        echo "没有可回滚的版本"
        break
      fi
      if ! f="$(down_file_for "$cur")"; then
        echo "找不到版本 $cur 对应的 *.down.sql" >&2
        exit 1
      fi
      echo "==> 回滚 $cur（$(basename "$f")）"
      mark_dirty "$cur"
      if ! run "$f"; then
        echo "回滚失败，schema_migrations 已标记 dirty（version=$cur）。" >&2
        exit 1
      fi
      prev="$(previous_version "$cur")"
      if [ "$prev" -eq 0 ]; then
        q "DELETE FROM schema_migrations;" >/dev/null
        echo "已回滚到空库"
      else
        mark_clean "$prev"
        echo "已回滚到版本 $prev"
      fi
    done
    ;;

  -h|--help|help)
    sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    ;;

  *)
    echo "未知子命令: $cmd（可用: status / up / down / version）" >&2
    exit 2
    ;;
esac
