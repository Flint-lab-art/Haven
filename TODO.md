# TODO

> 执行清单，不是事实来源。所有实现细节以 `docs/` 为准；本文件与 `docs/` 冲突时以 `docs/` 为准。
> `docs/` 只读，需求变更请先改文档，再勾选这里的条目。

当前阶段：**二期（v2）开发中**。一期（第 0–7 章）已全部完成并归档在本文下半部分。

图例：`[ ]` 未做 · `[x]` 已完成 · `[~]` 部分完成

---

# 二期（v2）

文档：`docs/v2/`，入口为 `docs/v2/changes.md`。范围与顺序：**F3 → F1 → F2**。

## 二期.0 开工前置

- [x] 按 `docs/v2/backend/test-plan.md` 第二节确认基线：`go build ./...`、`go vet ./...`、`go test ./...`（**必须设置 `HAVEN_TEST_DB_DSN`，skip 不算通过**）、`pnpm test`、`pnpm build` 全绿（2026-10-31 实测：四项全通过）
- [x] 确认本地库已执行到 `0005_inbox_folder`，且 `schema_migrations` 无 `dirty`（实测 `version=5, dirty=f`）

## 二期.F3 测试补齐（最先做，见 `docs/v2/backend/test-plan.md`）

> 调整说明：F3.2 与 F3.3 的用例断言的是 F1 / F2 才引入的行为，先写只会是红的。
> 已按 `docs/v2/backend/test-plan.md` 的意图拆开：**现有代码的测试在 F3.1 完成**，
> **F1 / F2 的测试分别挂在 F1.4、F2.4**，与功能同一条提交完成。

### F3.1 纯函数单测（已完成）

- [x] `internal/search`：`escapeLike` 单测（`%`、`_`、`\` 转义；空串；中文多字节）——`internal/search/search_test.go`，12 个用例
- [x] `internal/notes`：`Preview` 单测（空串 / 恰好 200 rune / 201 rune / 多字节不按字节截断）——`internal/notes/preview_test.go`
- [x] `internal/notes`：`sameFolder` 单测（nil 与 nil / nil 与值 / 相同 / 不同）——`internal/notes/folder_test.go`
- [x] `internal/folders`：`isSelfOrDescendant` 单测（自身 / 直接子级 / 隔代 / 兄弟 / 无关节点，能识别成环）——依赖 `*sql.Tx` 无法纯函数单测，改为 `cmd/haven/folders_cycle_test.go` 通过 PATCH 防环验证（自身 / 直接子级 / 隔代 / 兄弟合法 / 先移动再成环）
- [x] `internal/folders`：`normalizeIcon` 单测（空 / 单 Emoji / 16 rune 边界 / 17 rune / 含换行）——`internal/folders/icon_test.go`；顺带确认纯空白与纯换行均按「未设置」处理
- [x] `internal/tags`：标签名长度单测（63 / 64 / 65 rune；trim 后为空；多字节按 rune 计数）——校验内联在 `Create` 且依赖数据库，改为 `cmd/haven/tags_length_test.go` 通过 API 验证边界

## 二期.F1 回收站（见 `docs/v2/api.md` 第二、四节，`docs/v2/backend/data-model.md` 第一、三节）

### F1.1 数据层

- [x] `migrations/0006_notes_recycle_bin.up.sql` / `.down.sql`：`notes.deleted_at` + `idx_notes_deleted` 部分索引（已应用，`up`/`down` 均验证通过）
- [x] `auth.VisibilityPublic` / `auth.VisibilityOwnedOrPublic` 追加 `deleted_at IS NULL`（**唯一一处**，不在 handler 另拼）——注意「自己的」分支也必须排除已删行，否则登录用户仍能看到自己删掉的笔记；同时补齐 `notes.Get`、`tags.NotesByTag`、`tags.List` 与 `search.Private` 的标签计数
- [x] `folders.Delete` 迁移笔记时加 `AND deleted_at IS NULL`，不搬动回收站中的笔记——`cmd/haven/folders_trash_test.go` 覆盖两条路径

### F1.2 接口层

- [x] `notes.Delete` 改为 `UPDATE notes SET deleted_at = now()`；已删除再删返回 404—`TestDeleteMovesToTrash`
- [x] `notes.Update` / `Publish` / `Unpublish` 对已删除笔记返回 404
- [x] `GET /api/notes/trash`：`deleted_at DESC`，返回 `content_preview`、`folder_path`、`deleted_at`，访问时顺带惰性清理
- [x] `POST /api/notes/:id/restore`：清 `deleted_at`；原文件夹不存在时归入收件箱
- [x] `DELETE /api/notes/:id/purge`：仅对回收站中的笔记有效
- [x] `DELETE /api/notes/trash`：清空回收站
- [x] 惰性清理：保留 30 天（代码常量，不走环境变量）——`TrashRetention`，`cmd/haven/trash_api_test.go` 覆盖

### F1.3 前端

- [x] `src/api/notes.ts` 增加回收站四个调用
- [x] 新增 `/trash` 路由（`meta.section: 'trash'`），未登录跳 `/login`——`src/__tests__/trash-route.test.ts`
- [x] 侧边栏：在 `sidebar__spacer` 与用户区之间新增「回收站」入口，Mini 模式显示 tooltip
- [x] 回收站页面：列表（标题 / 原路径 / 删除时间）+ 只读预览 + 还原 / 永久删除 / 清空
- [x] 删除确认文案改为「可在回收站中还原」（仅笔记，文件夹不变）

### F1.4 测试（与原 F3.2 / F3.3 对应，跟功能一起完成）

- [x] 软删除后 `GET /api/public/notes` 与 `/api/public/notes/:id` 不可见 —— `cmd/haven/trash_visibility_test.go`
- [x] 软删除后 `GET /api/public/search` 不返回
- [x] 软删除后 `GET /api/search` 不返回
- [x] 软删除后 `GET /api/tags/:id/notes` 不返回，且 `note_count` 不计已删
- [x] 软删除后 `GET /api/notes` 不返回
- [x] 还原后上述接口重新可见
- [x] 原文件夹已删除时还原，笔记落到收件箱
- [x] 超过 30 天的回收站记录在访问回收站时被清理
- [x] 跨用户无法查看他人的回收站
- [x] `/trash` 路由需要登录，未登录跳 `/login`——`src/__tests__/trash-route.test.ts`
- [x] 在 `/trash` 时侧边栏对应项高亮、其他项不高亮（校验 section 归属互不重叠）
- [x] 笔记删除确认框提示「可在回收站中还原」；文件夹删除仍为「不可恢复」

## 二期.F2 历史版本（见 `docs/v2/api.md` 第三、四节，`docs/v2/backend/data-model.md` 第二、三节）

### F2.1 数据层

- [x] `migrations/0007_note_versions.up.sql` / `.down.sql`：`note_versions` 表（`tag_ids uuid[]`）+ `idx_note_versions_note`（已应用）
- [x] `notes.Update` 事务内、更新前写快照；仅当标题 / 正文 / 文件夹 / 标签真的变化
- [x] 同一笔记 5 分钟内合并为一条（代码常量 `VersionMergeWindow`，不走环境变量）

### F2.2 接口层

- [x] `GET /api/notes/:id/versions`：`created_at DESC`，返回标题、时间、`content_size`，不返回正文
- [x] `GET /api/notes/:id/versions/:versionId`：返回完整快照含 `tag_ids`
- [x] `POST /api/notes/:id/versions/:versionId/restore`：覆盖标题 / 正文 / 文件夹 / 标签，还原本身也产生一条快照
- [x] 已删除笔记的版本接口一律 404；跨用户 404

### F2.3 前端

- [ ] 编辑页 `editor-actions` 内、字数之后新增「历史版本」按钮；`/notes/new` 未创建时不显示
- [ ] 浮层：左栏版本时间线，右栏为该版本与**当前编辑器内容**的 DIFF（基准 A）
- [ ] 只对正文做 DIFF；标题变化在顶部单独提示
- [ ] 还原前二次确认；还原时先 `sync()` 再覆盖，避免与自动保存竞争
- [ ] 点击外部或 `Esc` 关闭浮层（`pointerdown` 判断，不用 `focusout`）

### F2.4 测试（与原 F3.2 / F3.3 对应，跟功能一起完成）

- [x] 标题 / 正文 / 文件夹 / 标签变化时产生版本快照；只改 `sort_order` 不产生——`cmd/haven/versions_test.go`
- [x] 5 分钟内的多次修改合并为一条快照
- [x] 版本还原后标题、正文、文件夹、标签与快照一致
- [x] 跨用户无法查看他人的版本
- [ ] DIFF 行分类（新增 / 删除 / 未变）纯函数单测

---

# 一期（v1，已归档）

> 以下条目为已完成存档，**不再修改**，仅作历史参考。详细说明见 `docs/v1/`。

当前状态（归档时）：前后端功能均已完成（第 0–6 章），`deploy/` 已落地。

## 0. 清理脚手架

- [x] `backend/cmd/haven/main.go` 重写为读环境变量的入口（见 `architecture.md` 第四节、5.2/5.3）：删除硬编码 `:8080`，改用 `HAVEN_LISTEN_ADDR`，接 `log/slog`
- [x] 删除 `frontend/src/components/HelloWorld.vue` 与模板样式（`style.css` 里的 demo 变量、`src/assets/{vue.svg,vite.svg,hero.png}`）
- [x] 删除 `frontend/README.md`（Vite 模板说明）与 `frontend/public/icons.svg` 等模板残留，保留 `favicon.svg` 或替换
- [x] `frontend/index.html`：`lang="zh-CN"`，标题改为 Haven
- [x] 接入 `vue-router`（History 模式）与 `pinia` 到 `main.ts`
- [x] 根目录 `.gitignore`
- [x] 根目录 `AGENTS.md`：写文档驱动规则、Git 规范、TODO 边界、技术栈锁定
- [x] 根目录 `opencode.json`：`instructions` 加载常驻文档（二期已扩为 `docs/README.md`、`docs/v1/conventions.md`、`docs/v1/overview.md`、`docs/v2/changes.md`）

## 1. 配置与数据库基座

- [x] `internal/config`：读取并校验全部 `HAVEN_*` 变量，缺必填项拒绝启动；常量（cookie 名、有效期、bcrypt cost）写死不走配置
- [x] `internal/db`：`database/sql` + `pgx` 连接池，启动时 ping
- [x] `migrations/0001_init.up.sql` / `.down.sql`：按 `data-model.md` 依赖顺序建表，含全部索引与 CHECK
- [x] migration 要求 `CREATE EXTENSION IF NOT EXISTS pg_trgm;`；确认 `gen_random_uuid()` 可用
- [x] 初始化脚本：创建唯一用户（bcrypt cost 12）——**不暴露注册接口**（`backend/cmd/haven-init-user`）
- [x] 后端启动**不**跑 migration（由脚本执行）；执行方式见 `deploy/migrate.sh`

## 2. 鉴权核心（`internal/auth`，按 `auth.md`）

- [x] 凭证生成与哈希工具：32 字节随机 + base64url，落库只存 SHA-256
- [x] 身份识别（auth.md 6.1）：`Authorization: Bearer` 优先于 cookie；`sessions` / `tokens` 两张表；`pending_logins` 不参与
- [x] 授权中间件（auth.md 6.2–6.4）：`anonymous_ok` / `login_required` / `write` / `totp_verified` 四档，并把可见性条件注入 context
- [x] cookie 下发：`haven_session` / `haven_trusted_device`，`HttpOnly`、`SameSite=Lax`、`Domain=HAVEN_COOKIE_DOMAIN`、`Secure` 跟随 `HAVEN_COOKIE_SECURE`
- [x] 登录两步：账密 → （未启用 TOTP / 授信设备有效则直接建会话）→ 否则 `pending_logins` + `temp_token`（5 分钟）
- [x] 每次请求更新 `sessions.last_used_at`，不延长 `expires_at`
- [x] TOTP：setup 不落库、verify 通过才落库并置 `totp_enabled`；disable 同时删除该用户全部授信设备
- [x] 改密码：同事务内删全部 `sessions` + `trusted_devices`，**不删** `tokens`，当前会话也失效
- [x] bcrypt cost 12；密码 ≥12 位且不能与旧密码相同

> 补充实现：会话/授信设备/Token 的 `internal/auth` 业务与 handler、`internal/httpx` 统一错误响应、`cmd/haven` 路由装配。
> 会话「是否通过过 TOTP」用 token 后缀 `:totp` 承载，与 `pending_logins` 的 `trust_device` 后缀手法一致。

## 3. 审计（`internal/audit`，按 `audit.md`）

- [x] `audit_events` 写入器：只追加；`actor_user_id` 可为 NULL，`actor_username` 存快照
- [x] 实现第十三类事件（login_success/login_failure/logout/totp_bound/totp_disabled/password_changed/session_revoked/trusted_device_added|revoked/token_created|revoked/note_published|unpublished）
- [x] 写入时机：业务成功后、响应前；**失败只打错误日志，不影响业务结果**
- [x] 笔记 CRUD 不写审计；不记录笔记内容、密码、Token 明文、TOTP secret

> `note_published` / `note_unpublished` 已在第 4 章接入 `notes.Handler` 的钩子（`audit.UseNoteHooks`）。

### 6.1 追加：Markdown 编辑（用户后续要求，2026-10-28）

- [x] 正文以 Markdown 原文存储（`notes.content` 不变，后端零改动）
- [x] 阅读态渲染：`marked` + `DOMPurify`（`utils/markdown.ts`），过滤脚本与内联事件
- [x] 所见即所得编辑器：Milkdown 7.23（MIT），`components/MarkdownEditor.vue`，路由懒加载
- [x] 新建笔记改为直接进空白编辑页（无弹窗），首次保存才创建
- [x] 保存前 `sync()` 编辑器内容，避免异步回写导致的空正文
- [x] 离开页面有未保存改动时确认

> 注意：`docs/v1/` 里 `content` 字段仍写作「正文 text」，未声明 Markdown。

## 4. 领域接口（按 `api.md` 逐条实现）

- [x] `/api/me`（11.1）：匿名/会话/Token 三种响应
- [x] 认证 `/api/auth`（二）：login、login/totp、logout、totp/setup|verify|disable、password
- [x] 会话 `/api/sessions`（三）：列表带 `is_current`；禁止撤销当前会话（422）；Token 访问 403
- [x] 授信设备 `/api/trusted-devices`（四）：**只读 + 删除，不提供 POST**
- [x] Token `/api/tokens`（五）：创建仅返回一次明文；撤销写 `revoked_at` 不删记录；需 TOTP
- [x] 笔记私有 `/api/notes`（六）：列表 `updated_at DESC` + `content_preview`（rune 截 200 + `…`）；创建不收 `visibility`；`tag_ids` 全量替换
- [x] publish / unpublish：`published_at` 首次写入、撤回保留；重复操作 409
- [x] 笔记公开 `/api/public/notes`（七）：`published_at DESC`，不可见统一 404
- [x] 标签 `/api/tags`（八）：`lower(name)` 唯一 → 409；无重命名接口；级联删除关联
- [x] 搜索（九）：`/api/search` 笔记查 `notes.search_text ILIKE '%q%'`、标签查 `tags.name ILIKE '%q%'`，返回 `{notes, tags}` 两块；`/api/public/search` 只查公开笔记的 `search_text`，不返回标签列表
- [x] 作品集 `/api/public/portfolio` + `/api/portfolio/*`（十）：`url` 由后端拼接（Gogs 用 `HAVEN_GOGS_BASE_URL`，GitHub 固定）；主链接唯一
- [x] `internal/httpx`：统一错误响应（`error`/`message`/可选 `fields`）+ 统一分页（`limit` 默认 20 上限 100）
- [x] 响应字段全 `snake_case`；列表空值返回 `{"items": [], "total": 0}`
- [x] 跨用户访问一律 404；read Token 写操作 403；凭证类操作对任何 Token 一律 403
- [x] 文件夹 `/api/folders`：树状目录、收件箱、图标、拖拽排序

## 5. 静态托管

- [x] `r.Static` 托管 `/assets`（长缓存），`NoRoute` 兜底 `index.html`；`HAVEN_FRONTEND_DIR`
- [x] 确认 `/api/*` 不被 SPA 兜底吞掉

## 6. 前端（按 `frontend.md`）

- [x] `src/api/` 按领域拆文件（auth/notes/tags/search/portfolio/sessions/devices/tokens/me/folders）+ 统一 `ApiError`；路径写相对 `/api/...`
- [x] `auth` store：启动调 `GET /api/me`；401 统一清空并跳 `/login`；403 只提示不跳转
- [x] 按 `window.location.hostname` 选择公开域/私有域路由表（同一份构建）
- [x] router guard：除 `/login` 外全部需登录，支持 `?redirect=`
- [x] 公开域页面：`/`、`/notes/:id`、`/search?q=`、`/portfolio`；**无登录入口、无后台链接**
- [x] 私有域页面：`/login`（含 TOTP 第二步，`temp_token` 只存内存）、`/`、`/notes/:id`、`/notes/new`、`/search`、`/tags`、`/portfolio`、`/settings/*`
- [x] `/settings/tokens` 遇 403 时引导去 `/settings/security` 完成 TOTP，不登出
- [x] 公共组件：`NoteListItem`、`TagBadge`、`TagDropdown`、`SearchBar`、`LoginForm`、`TotpForm`、`MarkdownEditor` 等
- [x] 中文界面；不做深色模式切换、不做 PWA、不做多语言
- [x] 本地开发代理 `/api` 到后端（`vite.config.ts`）

## 7. 验证与部署

- [ ] `go vet ./...`、`go test ./...` 全绿；至少覆盖：可见性矩阵、Token scope、跨用户 404、publish 幂等性
- [x] 全量路由鉴权不变量测试（2026-10-30）：`cmd/haven/route_auth_test.go` 遍历全部 `/api` 路由，白名单外匿名一律要求 401，非 GET 私有路由对 read Token 一律要求 403
- [ ] `pnpm build`（含 `vue-tsc -b`）通过
- [ ] 手工冒烟：匿名 → 公开列表/详情/搜索/作品集；登录 → TOTP → 笔记 CRUD → publish → 退出
- [x] `deploy/`：构建脚本 + systemd unit + migration 执行
- [ ] 部署形态待定项（`architecture.md` 第八节）：端口、HTTPS/反代、`pg_dump` 备份定时任务
- [ ] 更新根 `README.md` 的「快速开始」占位

## 8. 明确不做（防止误开工）

- ✗ TUI / Neovim 插件（二期确认二至三期都不做）
- ✗ LLM 实现与 SDK 依赖（`internal/llm` 只保留接口，二期不做，留待三期后再议）
- ✗ Docker / K8s、ORM / sqlc、SSR、多用户注册、审计查询界面

---

## 待确认：一期遗留的三条状态

以下三条一期条目**实测已满足**，但尚未勾选，需要人类确认后再改：

| 行 | 条目 | 实测情况 |
|---|---|---|
| 7 章 | `go vet ./...`、`go test ./...` 全绿 | 2026-10-31 实测：`go build`、`go vet` 通过；设置 `HAVEN_TEST_DB_DSN` 后 `go test ./...` 全绿（约 140s） |
| 7 章 | `pnpm build`（含 `vue-tsc -b`）通过 | 2026-10-31 实测通过 |
| 7 章 | 更新根 `README.md` 的「快速开始」占位 | 2026-10-31 已改（含「当前版本」节与路径修正） |

另：7 章「手工冒烟」属于人工验证，无法由 AI 判定。
