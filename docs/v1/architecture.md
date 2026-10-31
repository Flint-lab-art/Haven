# architecture — 技术架构与目录结构

> 本文件回答：技术栈、目录结构、组件关系、配置项清单、部署形态。
> 依赖：overview.md

## 一、技术栈（锁定）

| 层 | 选型 | 说明 |
|---|---|---|
| 后端语言 | Go | 版本 ≥ 1.22 |
| 后端 HTTP 框架 | **Gin** | 版本 ≥ 1.10，统一使用，不混用 chi / Echo |
| 数据库 | PostgreSQL | ≥ 15，启用 `pg_trgm` 扩展 |
| 数据库访问 | `database/sql` + `pgx` 驱动，手写 SQL | 不引入 ORM / sqlc |
| 前端框架 | Vue 3 + TypeScript | Composition API |
| 前端构建 | Vite | 不使用 Webpack / Nuxt |
| 前端路由 | Vue Router | History 模式 |
| 前端状态 | Pinia（仅需时用） | 简单状态优先用 composable |
| 前端 UI | 手写 CSS | 不引入 UI 组件库，样式规范见 `frontend/ui-design.md` |
| Markdown 渲染 | `marked` + `DOMPurify` | 阅读态；HTML 必须过 DOMPurify |
| Markdown 编辑 | Milkdown 7 | 编辑态，路由懒加载 |
| 代码高亮 | `highlight.js`（common 语言集） | 阅读态与编辑态共用 |
| 包管理器 | pnpm | 前端锁定 `pnpm-lock.yaml` |

**锁定含义**：opencode 生成代码时不得替换上述选型，需要新增依赖时先改本节。

**框架选择理由**：本项目代码由 opencode + DeepSeek 生成，Gin 的训练语料丰富、写法惯例统一，生成质量比 chi 更稳定。代价是 Gin 自带 `*gin.Context`，需要通过约束把它限制在 handler 层。

## 二、目录结构

```
Haven/
├── docs/                    # 唯一事实来源（文档）
├── backend/                 # Go 后端
│   ├── cmd/
│   │   ├── haven/
│   │   │   ├── main.go      # 入口
│   │   │   └── router.go    # 路由装配 + 静态托管
│   │   └── haven-init-user/ # 创建唯一账号的初始化脚本
│   ├── internal/
│   │   ├── config/          # 配置加载
│   │   ├── db/              # 数据库连接
│   │   ├── auth/            # 鉴权中间件、会话、Token、TOTP
│   │   ├── notes/           # 笔记领域
│   │   ├── folders/         # 文件夹目录树
│   │   ├── tags/            # 标签领域
│   │   ├── search/          # 搜索
│   │   ├── portfolio/       # 作品集
│   │   ├── audit/           # 审计
│   │   ├── llm/             # LLM 抽象层（本期只有接口）
│   │   └── httpx/           # 通用 HTTP 辅助（错误响应、分页）
│   ├── migrations/          # SQL migration 文件
│   ├── go.mod
│   └── go.sum
├── frontend/                # Vue 前端
│   ├── src/
│   │   ├── api/             # API 客户端封装
│   │   ├── views/           # 页面（public/ 与 private/ 两个子目录）
│   │   ├── components/      # 组件
│   │   ├── router/          # 路由（domain.ts 做域判定）
│   │   ├── stores/          # Pinia（auth store）
│   │   ├── utils/           # markdown 渲染、主题、格式化
│   │   ├── __tests__/       # vitest 纯逻辑单测
│   │   └── main.ts
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.json
│   └── vite.config.ts
├── deploy/                  # 部署脚本（systemd unit、构建、migration）
└── README.md
```

**约定**：

- 后端按**领域**分包（`notes`、`folders`、`tags`…），不按技术层分包（不建 `handlers/`、`services/`、`repositories/` 这种横切目录）。
- 每个领域包内部自包含：handler、业务逻辑、SQL 查询都在该包内，并各自提供 `RegisterRoutes`。
- 跨领域的通用代码放 `internal/httpx`、`internal/auth`、`internal/config`。
- 前端按**页面**组织 `views`（`public/` 公开域、`private/` 私有域），公共组件放 `components`，API 调用统一封装在 `api/` 下。
- `frontend/dist/` 是构建产物，不提交。

## 三、组件关系与数据流

```
浏览器 (Vue SPA)
    │  HTTPS / HTTP
    ▼
Go 后端 (Gin)
    │
    ├── 鉴权中间件 ──→ sessions / pending_logins / tokens / trusted_devices
    │
    ├── 领域 handler ──→ notes / tags / search / portfolio / audit
    │
    └── database/sql ──→ PostgreSQL（唯一真值源）

TUI / Neovim ──→ Go 后端（Authorization: Bearer <token>）
```

**关键点**：

- 后端是**唯一 API 出口**，所有客户端（Web / TUI / Neovim）都走同一套接口。
- 前端是纯静态 SPA，构建产物由后端托管（见第七节）。
- 没有任何组件直连 PostgreSQL，除了后端本身。

## 四、配置项清单

所有**后端运行时**配置通过环境变量提供（自用场景，不引入配置文件）。后端启动时读取并校验，缺失必填项则拒绝启动。

| 变量名 | 必填 | 说明 | 示例 |
|---|---|---|---|
| `HAVEN_LISTEN_ADDR` | 是 | 后端监听地址 | `127.0.0.1:8080` |
| `HAVEN_DB_DSN` | 是 | PostgreSQL 连接串 | `postgres://haven:xxx@127.0.0.1:5432/haven?sslmode=disable` |
| `HAVEN_FRONTEND_DIR` | 是 | 前端静态文件目录 | `/opt/haven/frontend/dist` |
| `HAVEN_COOKIE_SECURE` | 否 | 会话 cookie 是否加 `Secure` 属性，默认 `true`；HTTP 部署时设 `false` | `true` |
| `HAVEN_GOGS_BASE_URL` | 是 | Gogs 站点 base URL，用于拼作品集跳转链接 | `https://gogs.example.com` |
| `HAVEN_TOTP_ISSUER` | 否 | TOTP 验证器里显示的发行者名，默认 `Haven` | `Haven` |
| `HAVEN_LOG_LEVEL` | 否 | 日志级别，默认 `info` | `info` / `debug` |
| `HAVEN_COOKIE_DOMAIN` | 是 | 会话与授信设备 cookie 的 Domain | `app.example.com` |

**前端构建期变量**（编译进 JS，不是运行时配置）：

| 变量名 | 必填 | 说明 | 示例 |
|---|---|---|---|
| `VITE_PRIVATE_HOST` | 生产必填 | 私有域的精确主机名，前端据此判定当前域；不匹配的一律按公开域渲染 | `app.example.com` |

- 必须与 `HAVEN_COOKIE_DOMAIN` **完全一致**（不带协议、不带端口）；
- 不得填父域（如 `.example.com`），否则公开域也会收到 cookie；
- 本地开发时 `localhost` / IP 一律视为私有域，不需要设置。

**常量（不进配置）**：

以下值在 `auth.md` 中已定，直接写在代码里，不通过环境变量暴露，避免误配。

| 常量 | 值 | 来源 |
|---|---|---|
| 会话 cookie 名 | `haven_session` | auth.md 第三节 |
| 授信设备 cookie 名 | `haven_trusted_device` | auth.md 第四节 |
| 会话有效期 | 7 天 | auth.md 第三节 |
| 授信设备有效期 | 30 天 | auth.md 第四节 |
| `pending_logins` 有效期 | 5 分钟 | auth.md 3.1 |
| bcrypt cost | 12 | auth.md 8.1 |

**未来可能新增**（本期不实现）：

- `LLM_PROVIDER`：provider 名（如 `openai` / `deepseek` / `local`）
- `LLM_API_KEY`：API 密钥（如适用）
- `LLM_BASE_URL`：API 地址（如适用）
- `LLM_MODEL`：模型名
- `TOTP_SECRET_ENCRYPTION_KEY` — 见 `auth.md` 8.2 后期升级路径

LLM 配置项的启用时机与触发方式见 `backend/llm-extension.md`。

## 五、后端项目结构约定

### 5.1 数据库访问方式

采用 **`database/sql` + `pgx` 驱动**，手写 SQL。理由：

- 自用项目，查询数量有限，手写 SQL 最直观；
- 避免 ORM 的隐式行为（懒加载、N+1、意外的级联），SQL 写出来是什么就是什么；
- `pgx` 提供 PostgreSQL 完整支持（`jsonb`、`uuid`、`timestamptz`）。

**不引入**：GORM、Ent、sqlc、sqlboiler。

### 5.2 Gin 的使用边界

**`*gin.Context` 只允许出现在 handler 层**，不得传入业务逻辑层或数据访问层。

- handler 函数签名：`func(c *gin.Context)`；
- handler 内部解析请求、调用业务函数、写响应；
- 业务函数签名只接受标准 `context.Context` 和领域参数，不接受 `*gin.Context`；
- 需要标准 context 时用 `c.Request.Context()`。

**原因**：把 Gin 限制在 HTTP 层，业务层不感知框架，将来如需换框架只改 handler。

### 5.3 中间件

- 鉴权中间件在 `internal/auth` 下实现，返回 `gin.HandlerFunc`；
- 中间件通过 `c.Set("user", ...)` 注入身份，handler 用 `c.MustGet("user")` 取出；
- 中间件顺序：日志 → 鉴权 → 领域 handler。具体注册在 `internal/httpx` 或 `main.go`。

### 5.4 错误处理

- 领域层返回 `error`，handler 层统一映射为 `api.md` 1.4 定义的错误响应；
- 不暴露内部错误细节给客户端（`500` 只返回 `internal_error`，细节进日志）；
- 统一的错误响应构造函数放在 `internal/httpx`，所有 handler 调用同一套。

### 5.5 请求校验

- 用 Gin 的 `ShouldBindJSON` 绑定请求体；
- 校验规则用 struct tag（`binding:"required"`）做基础校验，复杂校验在业务层；
- 校验失败统一返回 `422 validation_failed`，`fields` 从绑定错误中提取。

### 5.6 migration

- migration 文件放在 `backend/migrations/`；
- 文件名格式：`0001_init.up.sql` / `0001_init.down.sql`，按顺序编号；
- 首个 migration 按 `data-model.md` 第一节的依赖顺序建表；后续结构变更各自新增一个编号（如 `0002_folders.up.sql`），**不回头改已执行的 migration**；
- migration 由 `deploy/migrate.sh` 执行（见第八节），**后端启动时不自动跑**（避免并发启动冲突，也避免误执行）。

### 5.7 日志

- 结构化日志，标准库 `log/slog`；
- 不记录请求体、不记录笔记内容、不记录密码或 Token；
- 审计事件走 `audit_events` 表，不走日志。

## 六、前端项目结构约定

### 6.1 API 客户端

`frontend/src/api/` 下按后端领域分文件（`auth.ts`、`notes.ts`、`tags.ts`…），每个文件导出函数，函数内部处理：

- 请求路径拼接（前缀 `/api`）；
- 错误响应转异常（统一 `ApiError` 类型，含 `error` / `message` / `fields`）；
- 不在此层做状态管理。

### 6.2 认证状态

- 前端启动时调 `GET /api/me` 判断登录态；
- 登录态存 Pinia store；
- 未登录访问受保护路由时，router guard 重定向到登录页。

### 6.3 构建产物

- `pnpm build`（= `vue-tsc -b && vite build`）输出到 `frontend/dist/`；
- 该目录即 `HAVEN_FRONTEND_DIR` 指向的位置（部署时由 `deploy/` 脚本拷贝）；
- 构建时需带 `VITE_PRIVATE_HOST`（见第四节），否则生产环境整站按公开域渲染、看不到后台。

### 6.4 域判定

- `src/router/domain.ts` 按 `window.location.hostname` 选择公开域 / 私有域路由表，同一份构建服务两个域名；
- `hostname` 等于 `VITE_PRIVATE_HOST` 时为私有域；`localhost` 与 IP 一律视为私有域（便于本地开发）；其余一律公开域。

## 七、静态文件托管与路由

**后端同时托管前端静态文件**，不单独部署 nginx。

- `GET /api/*` 走 API handler；
- 其余路径（`/`、`/notes/xxx` 等）一律返回 `index.html`，由 Vue Router 接管；
- 静态资源（`/assets/*.js`、`*.css`）由后端直接返回文件，带长缓存头（文件名含 hash）。

**实现方式**：Gin 的 `r.NoRoute(...)` 兜底到 `index.html`，`r.Static("/assets", ...)` 托管静态资源。

**理由**：自用项目、单机部署，多一个 nginx 就多一个组件要运维。Go 的静态文件服务足够。

## 八、部署形态

**当前形态：宿主机直接运行**，不用容器。

- Go 二进制 + 前端静态文件 + 本机 PostgreSQL，三者跑在同一台宿主机；
- 后端由 **systemd** 常驻（unit 名 `haven`，`ExecStart=/opt/haven/bin/haven`）；
- 后端默认只监听 `127.0.0.1:8080`，对外由反向代理（Caddy）终止 TLS；
- 同一份二进制与同一份 `dist` 同时服务公开域与私有域，后端**不按 Host 分支**，分工由 `HAVEN_COOKIE_DOMAIN`（运行时）与 `VITE_PRIVATE_HOST`（构建期）共同决定；
- Gogs 同机部署，使用 Gogs 内置 SSH server，与宿主机 sshd 端口不冲突；
- Haven 本身不提供 SSH 服务。

**生产目录布局**：

| 路径 | 内容 |
|---|---|
| `/opt/haven/bin/haven` | 后端二进制 |
| `/opt/haven/bin/haven-init-user` | 唯一账号初始化脚本 |
| `/opt/haven/frontend/dist/` | 前端构建产物（`HAVEN_FRONTEND_DIR`） |
| `/opt/haven/migrations/` + `/opt/haven/migrate.sh` | migration 与执行脚本 |
| `/etc/haven/haven.env` | 环境变量（权限 `0600`） |
| `/var/backups/haven/` | `pg_dump` 备份输出 |

**构建与部署流程**：

1. `deploy/build.sh` 构建后端二进制与前端 `dist`，产物集中到 `deploy/out/`（已 gitignore）；
2. `deploy/migrate.sh up` 显式执行 migration（后端启动不自动跑）；
3. `deploy/deploy.sh` 一键完成构建、安装、migration、重启，可选 `--backup-db` / `--reset` / `--reset-db` / `--caddy`。

**migration 执行方式**：`deploy/migrate.sh` 自带版本表 `schema_migrations(version, dirty)`，与 golang-migrate 同构；每个文件在单事务内执行，失败整体回滚并置 `dirty`，`dirty` 为真时拒绝继续。支持 `status` / `up` / `down N` 三个子命令。

**备份策略**：`pg_dump` 输出到 `/var/backups/haven/`，由 `deploy/deploy.sh --backup-db` 触发；定时任务的时间点与保留份数由运维另行配置，不在本仓库脚本内写死。

**端口分配**：Haven 后端 `127.0.0.1:8080`；Gogs 的 HTTP / SSH 端口归 Gogs 部署，Haven 不依赖其具体取值（作品集只存 base URL）。对外 HTTPS 由反向代理承担，反向代理必须原样透传 `Host`，两个域名的 `server` 块都指向同一个 `127.0.0.1:8080`。

**`www` 重定向**：`www.example.com` → `example.com` 的 301 由反向代理（Caddy）配置，Haven 后端不处理，也不按 Host 分支。理由：后端只服务公开域与私有域两个精确主机名，`www` 属于部署侧的规范跳转，放在这里会多一层与 TLS 证书绑定的逻辑。Caddyfile 不在本仓库内（`deploy/deploy.sh --caddy` 只修改宿主机上已有的 `/etc/caddy/Caddyfile`），该跳转需在部署时手工加一条 `www` 的 site 块，指向与 `example.com` 相同的 `127.0.0.1:8080`。

**健康检查**：`GET /api/health` 返回 `{"status":"ok"}`，可匿名访问，部署脚本据此判定启动成功。

## 九、不做的事

完整禁令清单见 `conventions.md` 第四节，本文件不重复列举。
