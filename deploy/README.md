# deploy — Haven 部署脚本

> 本目录回答：Haven 如何构建、如何执行 migration、如何以 systemd 常驻运行。
> 依据 `docs/architecture.md` 5.6、第七节、第八节；部署形态（端口、HTTPS、备份）仍待定。

不使用 Docker / K8s：后端二进制、前端静态文件、本机 PostgreSQL 直接跑在宿主机上。

## 目录内容

| 文件 | 作用 |
|---|---|
| `build.sh` | 构建后端二进制 + 前端 dist，产物集中到 `deploy/out/`（已 gitignore） |
| `reload.sh` | 本地构建 → 安装到 `/opt/haven` → 重启服务（可选 `--migrate` / `--with-frontend`） |
| `migrate.sh` | 执行 / 回滚 migration，带版本表，后端启动时不自动跑 |
| `haven.service` | systemd unit，`ExecStart=/opt/haven/bin/haven` |
| `haven.env.example` | 环境变量模板，安装到 `/etc/haven/haven.env` |

## 前置

- Go ≥ 1.22（`go.mod` 要求 1.27.3，`GOTOOLCHAIN=auto` 会自动拉工具链）
- pnpm + Node ≥ 20（只构建后端时可跳过）
- PostgreSQL ≥ 15，已建库与角色，并具备 `CREATE EXTENSION pg_trgm` 权限

建角色与库（一次性，用超级用户）：

```bash
sudo -u postgres psql <<'SQL'
CREATE ROLE haven LOGIN PASSWORD '...';
CREATE DATABASE haven_dev OWNER haven;
SQL
```

`pg_trgm` 是 PostgreSQL 13+ 的 trusted 扩展，库 owner 执行 migration 时即可自动创建。

## 一、构建

```bash
deploy/build.sh                  # 后端 + 前端
deploy/build.sh --backend-only   # 前端还在改，只出后端
```

产物：

```
deploy/out/
├── bin/haven
├── frontend/dist/
├── migrations/
└── migrate.sh
```

## 二、执行 migration

后端启动不会自动建表，必须显式执行（`docs/architecture.md` 5.6）。

```bash
export HAVEN_DB_DSN='postgres://haven:...@127.0.0.1:5432/haven_dev?sslmode=disable'

deploy/migrate.sh status    # 看哪些已应用
deploy/migrate.sh up        # 按文件名顺序执行未应用的 *.up.sql
deploy/migrate.sh down 1    # 回滚最近 1 个版本
```

- 每个文件在单个事务内执行（`psql -1`），失败整体回滚并留下 `dirty` 标记；
- `dirty` 为真时脚本拒绝继续，需人工核对后清理 `schema_migrations` 里那一行；
- 版本表 `schema_migrations(version, dirty)` 与 golang-migrate 同构，将来换 CLI 可无缝衔接；
- 已手工建过表、但没有版本记录的库，脚本会自动基线到 `0001`，不会重复建表。

服务器上只需 `migrations/` 与 `migrate.sh` 两个产物：

```bash
HAVEN_DB_DSN='...' HAVEN_MIGRATIONS_DIR=/opt/haven/migrations /opt/haven/migrate.sh up
```

## 三、安装与启动

```bash
# 1) 建运行账号（或改用已有账号，见 unit 顶部注释）
sudo useradd --system --home /opt/haven --shell /usr/sbin/nologin haven

# 2) 放产物
sudo install -d -o haven -g haven /opt/haven
sudo cp -a deploy/out/. /opt/haven/

# 3) 配置
sudo install -d -m 0750 /etc/haven
sudo install -m 0600 deploy/haven.env.example /etc/haven/haven.env
sudoedit /etc/haven/haven.env     # 至少改 HAVEN_DB_DSN / COOKIE_DOMAIN / GOGS_BASE_URL

# 4) 建唯一账号（不暴露注册接口）
sudo -u haven env HAVEN_DB_DSN='...' HAVEN_INIT_PASSWORD='至少12位' \
  /opt/haven/bin/haven-init-user -username kairo

# 5) unit
sudo install -m 0644 deploy/haven.service /etc/systemd/system/haven.service
sudo systemctl daemon-reload
sudo systemctl enable --now haven
systemctl status haven
journalctl -u haven -f
```

> `haven-init-user` 由 `build.sh` 一并构建到 `deploy/out/bin/`，服务器上可直接执行。

## 四、升级

```bash
git pull                      # dev 分支
deploy/build.sh
sudo cp -a deploy/out/. /opt/haven/
export HAVEN_DB_DSN='...' HAVEN_MIGRATIONS_DIR=/opt/haven/migrations
/opt/haven/migrate.sh up
sudo systemctl restart haven
```

## 五、验证

```bash
curl -s http://127.0.0.1:8080/api/public/notes     # 期望 {"items":[],"total":0}
curl -sI http://127.0.0.1:8080/ | head -1          # 期望 200，返回 index.html
curl -s http://127.0.0.1:8080/api/not-exist        # 期望 JSON 404，不是 HTML
```

## 六、双域名（公开域 + 私有域）

同一份二进制 + 同一份 dist 同时服务两个域名，后端**不按 Host 分支**，分工由两处配置决定：

| 配置 | 在哪配 | 作用 |
|---|---|---|
| `HAVEN_COOKIE_DOMAIN` | `/etc/haven/haven.env`（运行时） | cookie 的 `Domain`，填**私有域**精确主机名；公开域因此收不到任何 cookie |
| `VITE_PRIVATE_HOST` | 构建时环境变量（**编译进 JS**） | 前端据此判断当前 host 是私有域还是公开域；不匹配的一律按公开域渲染 |

```bash
# 构建时必须带上私有域，否则线上所有域名都会被前端当成公开域
VITE_PRIVATE_HOST=note.vorin.icu ./deploy/build.sh

# 运行配置
HAVEN_COOKIE_DOMAIN=note.vorin.icu
HAVEN_COOKIE_SECURE=true          # 上 HTTPS 后必须为 true
```

要点：

- `VITE_PRIVATE_HOST` 只认**一个**主机名，必须与 `HAVEN_COOKIE_DOMAIN` 完全一致（不带端口、不带协议）；
- 不要填 `.vorin.icu` 这类父域，否则公开域也会收到 cookie，破坏「公开域无凭证」的设计（`docs/frontend/frontend.md` 第二节）；
- 私有域用 IP 或另一个别名访问时 cookie 不生效，表现为登录成功但仍是匿名；
- 反向代理必须原样透传 `Host`，不要重写路径，两个域名的 `server` 块都 `proxy_pass` 到同一个 `127.0.0.1:8080`。

## 七、尚未定案（`docs/architecture.md` 第八节）


以下属于文档待定项，脚本里刻意没有写死，等人类补文档后再落：

- 正式端口分配（Haven 后端 / Gogs HTTP / Gogs SSH）；
- 反向代理与 HTTPS（在不在同机 nginx / caddy）；
- `pg_dump` 备份定时任务。

当前 unit 只监听 `127.0.0.1:8080`，对外访问需要自行加反代或改 `HAVEN_LISTEN_ADDR`。
