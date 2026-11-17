#!/usr/bin/env bash
#
# 版本号同步工具。
#
# 唯一来源：仓库根目录的 VERSION 文件。
# 这个脚本把 VERSION 同步到两处必须在构建时硬编码版本的地方：
#   - backend/pom.xml        的 <properties><revision>
#   - frontend/package.json  的 "version"
#
# 为什么还需要这一步：
#   Maven 的 ${revision} 必须在 pom 里有默认值（不能像 npm 那样读外部文件），
#   npm 也不支持从文件读取 version。
#   所以两处仍有字面量，但唯一写入入口是这里，不再手工改。
#
# 用法：
#   ./scripts/version.sh              # 显示当前版本与各处状态
#   ./scripts/version.sh sync         # 把 VERSION 同步到 pom.xml 与 package.json
#   ./scripts/version.sh check        # 只校验，不一致则非 0 退出（CI / test.sh 用）
#   ./scripts/version.sh set 2.2.0    # 改 VERSION 并同步到各处

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
POM="$ROOT_DIR/backend/pom.xml"
PKG="$ROOT_DIR/frontend/package.json"

if [ -t 1 ]; then
  info() { printf '\033[36m[version]\033[0m %s\n' "$*"; }
  ok()   { printf '\033[32m[version]\033[0m %s\n' "$*"; }
  err()  { printf '\033[31m[version]\033[0m %s\n' "$*" >&2; }
else
  info() { printf '[version] %s\n' "$*"; }
  ok()   { printf '[version] %s\n' "$*"; }
  err()  { printf '[version] %s\n' "$*" >&2; }
fi

usage() {
  awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"
}

require_files() {
  for f in "$VERSION_FILE" "$POM" "$PKG"; do
    [ -f "$f" ] || { err "缺少文件：$f"; exit 1; }
  done
}

validate_format() {
  local v="$1"
  if ! printf '%s' "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$'; then
    err "版本号格式不合法：$v（应为 MAJOR.MINOR.PATCH）"
    exit 1
  fi
}

read_version()   { tr -d ' \t\r\n' < "$VERSION_FILE"; }
# 用 perl 提取，避免 sed 在路径含 / 时要换分隔符的麻烦
read_pom_version() { perl -ne 'print "$1\n" if /<revision>([^<]*)<\/revision>/' "$POM" | head -n 1; }
read_pkg_version() { perl -ne 'print "$1\n" if /"version":\s*"([^"]*)"/' "$PKG" | head -n 1; }

show_status() {
  require_files
  local file_v pom_v pkg_v
  file_v="$(read_version)"
  pom_v="$(read_pom_version)"
  pkg_v="$(read_pkg_version)"

  printf '%-30s %s\n' "VERSION（唯一来源）" "$file_v"
  if [ "$pom_v" = "$file_v" ]; then
    printf '%-30s %s  ✓\n' "backend/pom.xml <revision>" "$pom_v"
  else
    printf '%-30s %s  ✗ 需同步\n' "backend/pom.xml <revision>" "$pom_v"
  fi
  if [ "$pkg_v" = "$file_v" ]; then
    printf '%-30s %s  ✓\n' "frontend/package.json" "$pkg_v"
  else
    printf '%-30s %s  ✗ 需同步\n' "frontend/package.json" "$pkg_v"
  fi

  [ "$pom_v" = "$file_v" ] && [ "$pkg_v" = "$file_v" ]
}

sync_version() {
  local v="$1"
  validate_format "$v"
  command -v perl >/dev/null 2>&1 || { err "同步需要 perl"; exit 1; }

  printf '%s\n' "$v" > "$VERSION_FILE"

  # 只改 <revision>，不动依赖版本号
  V="$v" perl -0pi -e 's:<revision>[^<]*</revision>:<revision>$ENV{V}</revision>:' "$POM"
  # 只改顶层 "version"，package.json 里没有其它 version 字段
  # 用 {} 做分隔符，避免 " 与 : 在替换串里被 perl 当成语法
  V="$v" perl -0pi -e 's{"version":\s*"[^"]*"}{"version": "$ENV{V}"}' "$PKG"

  ok "已同步到 $v"
  show_status >/dev/null || true
}

cmd="${1:-status}"
case "$cmd" in
  status) show_status ;;
  sync)   sync_version "$(read_version)" ;;
  check)
    if show_status; then
      ok "版本号一致"
    else
      err "版本号不一致：执行 ./scripts/version.sh sync 修复"
      exit 1
    fi
    ;;
  set)
    [ $# -ge 2 ] || { err "用法：./scripts/version.sh set <version>"; exit 1; }
    sync_version "$2"
    ;;
  -h|--help) usage ;;
  *) err "未知参数：$cmd"; usage; exit 1 ;;
esac
