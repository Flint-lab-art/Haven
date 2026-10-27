# TODO

> 执行清单，不是事实来源。所有实现细节以 `docs/` 为准；本文件与 `docs/` 冲突时以 `docs/` 为准。
> `docs/` 只读，需求变更请先改文档，再勾选这里的条目。

当前阶段：**第 0 章（脚手架清理）已完成**，下一步进入第 1 章（配置与数据库基座）。

图例：`[ ]` 未做 · `[x]` 已完成 · `[~]` 部分完成

---

## 0. 清理脚手架（最先做，避免旧写法被模仿）

- [x] `backend/cmd/haven/main.go` 重写为读环境变量的入口（见 `architecture.md` 第四节、5.2/5.3）：删除硬编码 `:8080`，改用 `HAVEN_LISTEN_ADDR`，接 `log/slog`
- [x] 删除 `frontend/src/components/HelloWorld.vue` 与模板样式（`style.css` 里的 demo 变量、`src/assets/{vue.svg,vite.svg,hero.png}`）
- [x] 删除 `frontend/README.md`（Vite 模板说明）与 `frontend/public/icons.svg` 等模板残留，保留 `favicon.svg` 或替换
- [x] `frontend/index.html`：`lang="zh-CN"`，标题改为 Haven
- [x] 接入 `vue-router`（History 模式）与 `pinia` 到 `main.ts`
- [x] 根目录 `.gitignore`（当前只有子目录里的，`backend/.gitignore` 里 `/backend/...` 这类路径是按仓库根写的，实际匹配不到）

- [x] 根目录 `AGENTS.md`：写文档驱动规则、Git 规范、TODO 边界、技术栈锁定（已含“AI 只读不写 docs”“禁止自动提交”“按 TODO 顺序执行”三条）
- [x] 根目录 `opencode.json`：`instructions` 只加载 `docs/conventions.md` 和 `docs/overview.md`，其余文档按需手动喂，不全量加载

## 1. 配置与数据库基座

- [ ] `internal/config`：读取并校验全部 `HAVEN_*` 变量，缺必填项拒绝启动；常量（cookie 名、有效期、bcrypt cost）写死不走配置
- [ ] `internal/db`：`database/sql` + `pgx` 连接池，启动时 ping
- [ ] `migrations/0001_init.up.sql` / `.down.sql`：按 `data-model.md` 依赖顺序建表（`users` → `sessions`/`pending_logins`/`trusted_devices`/`tokens`/`audit_events` → `notes`/`tags`/`portfolio_items` → `note_tags`/`portfolio_repos`），含全部索引与 CHECK
- [ ] migration 要求 `CREATE EXTENSION IF NOT EXISTS pg_trgm;`；确认 `gen_random_uuid()` 可用
- [ ] 初始化脚本：创建唯一用户（bcrypt cost 12）——**不暴露注册接口**
- [ ] 后端启动**不**跑 migration（由脚本执行）；在 `deploy/` 或文档待定处补执行方式

## 2. 鉴权核心（`internal/auth`，按 `auth.md`）

- [ ] 凭证生成与哈希工具：32 字节随机 + base64url，落库只存 SHA-256
- [ ] 身份识别（auth.md 6.1）：`Authorization: Bearer` 优先于 cookie；`sessions` / `tokens` 两张表；`pending_logins` 不参与
- [ ] 授权中间件（auth.md 6.2–6.4）：`anonymous_ok` / `login_required` / `write` / `totp_verified` 四档，并把可见性条件注入 context
- [ ] cookie 下发：`haven_session` / `haven_trusted_device`，`HttpOnly`、`SameSite=Lax`、`Domain=HAVEN_COOKIE_DOMAIN`、`Secure` 跟随 `HAVEN_COOKIE_SECURE`
- [ ] 登录两步：账密 → （未启用 TOTP / 授信设备有效则直接建会话）→ 否则 `pending_logins` + `temp_token`（5 分钟）
- [ ] 每次请求更新 `sessions.last_used_at`，不延长 `expires_at`
- [ ] TOTP：setup 不落库、verify 通过才落库并置 `totp_enabled`；disable 同时删除该用户全部授信设备
- [ ] 改密码：同事务内删全部 `sessions` + `trusted_devices`，**不删** `tokens`，当前会话也失效
- [ ] bcrypt cost 12；密码 ≥12 位且不能与旧密码相同

## 3. 审计（`internal/audit`，按 `audit.md`）

- [ ] `audit_events` 写入器：只追加；`actor_user_id` 可为 NULL，`actor_username` 存快照
- [ ] 实现第十三类事件（login_success/login_failure/logout/totp_bound/totp_disabled/password_changed/session_revoked/trusted_device_added|revoked/token_created|revoked/note_published|unpublished）
- [ ] 写入时机：业务成功后、响应前；**失败只打错误日志，不影响业务结果**
- [ ] 笔记 CRUD 不写审计；不记录笔记内容、密码、Token 明文、TOTP secret

## 4. 领域接口（按 `api.md` 逐条实现）

- [ ] `/api/me`（11.1）：匿名/会话/Token 三种响应
- [ ] 认证 `/api/auth`（二）：login、login/totp、logout、totp/setup|verify|disable、password
- [ ] 会话 `/api/sessions`（三）：列表带 `is_current`；禁止撤销当前会话（422）；Token 访问 403
- [ ] 授信设备 `/api/trusted-devices`（四）：**只读 + 删除，不提供 POST**
- [ ] Token `/api/tokens`（五）：创建仅返回一次明文；撤销写 `revoked_at` 不删记录；需 TOTP
- [ ] 笔记私有 `/api/notes`（六）：列表 `updated_at DESC` + `content_preview`（rune 截 200 + `…`）；创建不收 `visibility`；`tag_ids` 全量替换
- [ ] publish / unpublish：`published_at` 首次写入、撤回保留；重复操作 409
- [ ] 笔记公开 `/api/public/notes`（七）：`published_at DESC`，不可见统一 404
- [ ] 标签 `/api/tags`（八）：`lower(name)` 唯一 → 409；无重命名接口；级联删除关联
- [ ] 搜索（九）：`/api/search` 笔记查 `notes.search_text ILIKE '%q%'`、标签查 `tags.name ILIKE '%q%'`，返回 `{notes, tags}` 两块；`/api/public/search` 只查公开笔记的 `search_text`，不返回标签列表
- [ ] 作品集 `/api/public/portfolio` + `/api/portfolio/*`（十）：`url` 由后端拼接（Gogs 用 `HAVEN_GOGS_BASE_URL`，GitHub 固定）；主链接唯一
- [ ] `internal/httpx`：统一错误响应（`error`/`message`/可选 `fields`）+ 统一分页（`limit` 默认 20 上限 100）
- [ ] 响应字段全 `snake_case`；列表空值返回 `{"items": [], "total": 0}`
- [ ] 跨用户访问一律 404；read Token 写操作 403；凭证类操作对任何 Token 一律 403

## 5. 静态托管

- [ ] `r.Static` 托管 `/assets`（长缓存），`NoRoute` 兜底 `index.html`；`HAVEN_FRONTEND_DIR`
- [ ] 确认 `/api/*` 不被 SPA 兜底吞掉

## 6. 前端（按 `frontend.md`）

- [ ] `src/api/` 按领域拆文件（auth/notes/tags/search/portfolio/sessions/devices/tokens/me）+ 统一 `ApiError`；路径写相对 `/api/...`
- [ ] `auth` store：启动调 `GET /api/me`；401 统一清空并跳 `/login`；403 只提示不跳转
- [ ] 按 `window.location.hostname` 选择公开域/私有域路由表（同一份构建）
- [ ] router guard：除 `/login` 外全部需登录，支持 `?redirect=`
- [ ] 公开域页面：`/`、`/notes/:id`、`/search?q=`、`/portfolio`；**无登录入口、无后台链接**
- [ ] 私有域页面：`/login`（含 TOTP 第二步，`temp_token` 只存内存）、`/`、`/notes/:id`、`/notes/new`、`/search`、`/tags`、`/portfolio`、`/settings`、`/settings/security`、`/settings/sessions`、`/settings/devices`、`/settings/tokens`
- [ ] `/settings/tokens` 遇 403 时引导去 `/settings/security` 完成 TOTP，不登出
- [ ] 公共组件：`NoteCard`、`TagBadge`、`SearchBar`、`LoginForm`、`TotpForm`、`SettingsNav`
- [ ] 中文界面；不做深色模式切换、不做 PWA、不做多语言
- [ ] 本地开发代理 `/api` 到后端（`vite.config.ts` 目前没有 server proxy）

## 7. 验证与部署

- [ ] `go vet ./...`、`go test ./...` 全绿；至少覆盖：可见性矩阵、Token scope、跨用户 404、publish 幂等性
- [ ] `pnpm build`（含 `vue-tsc -b`）通过
- [ ] 手工冒烟：匿名 → 公开列表/详情/搜索/作品集；登录 → TOTP → 笔记 CRUD → publish → 退出
- [ ] `deploy/`（README 与 `conventions.md` 提到但尚不存在）：构建脚本 + systemd unit + migration 执行
- [ ] 部署形态待定项（`architecture.md` 第八节）：端口、HTTPS/反代、`pg_dump` 备份定时任务
- [ ] 更新根 `README.md` 的「快速开始」占位

## 8. 明确不做（防止误开工）

- ✗ TUI / Neovim 插件（第二版）
- ✗ LLM 实现与 SDK 依赖（`internal/llm` 只保留接口）
- ✗ Docker / K8s、ORM / sqlc、SSR、多用户注册、审计查询界面
