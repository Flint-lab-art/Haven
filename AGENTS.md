# AGENTS.md

## 最重要的三条

1. **`docs/` 是唯一事实来源。** 所有代码按 `docs/` 生成，不做反向推导。
2. **代码与文档冲突时，以文档为准。** 冲突的判定是"代码错了"，修代码或重新生成；不得改文档去迁就代码。
3. **`docs/` 下任何文件只读。** 不得创建、修改、删除、格式化 `docs/`；需求变更由人类先改文档。见 `docs/conventions.md` 第二、五节。

遇到题面没覆盖的行为：不自己发明，写进回复里让人类决定补文档还是补禁令。

## 严格按 `TODO.md` 执行

- 根目录 `TODO.md` 是唯一的任务清单。**按章节顺序（0 → 8）从上往下做**，不要跳章节挑"有意思的"先做。
- **一次只做一个条目**：改完、验证通过、把该条勾成 `[x]`（部分完成用 `[~]` 并在后面注明缺什么），再开始下一条。不要把多个章节的改动混在一次提交里。
- 不擅自扩充范围：TODO 没列的功能不做；确实需要的先提出来让人类加条目。
- 第 8 章「明确不做」永远不勾选，也不实现。
- `TODO.md` 可以用 `[x]`/`[~]` 反映进度，但**不得删除条目或改动其含义**——需求变更走文档流程，由人类改。

## 开工前按任务读文档

- 永远：`docs/overview.md`、`docs/architecture.md`、`docs/conventions.md`（第四节是硬性禁令清单）
- 后端：再加 `docs/api.md`、`docs/backend/{data-model,auth,audit}.md`
- 前端：再加 `docs/api.md`、`docs/frontend/frontend.md`
- `README.md` 只是索引，具体规则以它指向的文档为准；README 里写的 `deploy/` 目录当前不存在。

## 硬性禁令（全部来自 `docs/conventions.md` 第四节，只摘最容易违反的）

- 不用 Docker / K8s；不引入 PG 之外的存储作为真值源。
- 不做 SSR / 预渲染；不做多用户（`user_id` 字段是预留，不实现注册）。
- 后端只用 Gin；不用 ORM / sqlc，手写 SQL（`database/sql` + `pgx`）。
- `*gin.Context` 只出现在 handler 层，业务函数只收 `context.Context`。
- 创建笔记不接受 `visibility`；公开只走 publish。
- 本期**不写**任何 TUI / Neovim 代码，也不写 LLM 实现（`internal/llm` 只有接口，不加 SDK 依赖）。
- 读接口的 visibility 收敛统一由授权中间件注入，不在各 handler 里自己拼。

## 当前代码状态（先看这里再动手，别假设已实现）

仓库处于脚手架阶段：

- `backend/cmd/haven/main.go` 只有 `GET /api/health` 和硬编码 `r.Run(":8080")`，与文档要求的 `HAVEN_LISTEN_ADDR` 等环境变量配置不符——按 `docs/architecture.md` 第四节重写，不要参考现有写法。
- `backend/internal/*` 全是空目录；`backend/migrations/` 为空。
- `frontend/` 是 Vite `create-vue` 模板（`HelloWorld.vue`、`src/views|router|stores|api` 空目录）；缺 `vue-router`、`pinia` 的实际接线。
- `frontend/dist/` 是上次构建产物，被 gitignore，不要手改、不要提交。

## 常用命令

后端（在 `backend/` 下执行）：

```bash
go build ./...                  # 编译
go vet ./...
go test ./...                   # 单包：go test ./internal/auth/...
go test ./internal/auth -run TestLoginTotp -v
```

前端（在 `frontend/` 下执行）：包管理器是 **pnpm**（有 `pnpm-lock.yaml`，不要用 npm/yarn 生成新 lockfile）。

```bash
pnpm install
pnpm dev                        # Vite dev server，需自行代理 /api 到后端
pnpm build                      # = vue-tsc -b && vite build → frontend/dist/
```

没有 lint / format / CI 配置，不要自造工具链。

认证相关的本地运行需要 PostgreSQL 并 `CREATE EXTENSION IF NOT EXISTS pg_trgm;`；其它 `HAVEN_*` 环境变量见 `docs/architecture.md` 第四节（缺必填项应拒绝启动）。

## 容易踩的约定

- **module 路径**是 `github.com/kairo/haven`；`go.mod` 用 `go 1.27.3`，`pgx` 是 v5。
- **migration** 用 `golang-migrate` 命名 `0001_init.up.sql` / `.down.sql`，放 `backend/migrations/`；顺序为 `users` → `sessions`/`pending_logins`/`trusted_devices`/`tokens`/`audit_events` → `notes`/`tags`/`portfolio_items` → `note_tags`/`portfolio_repos`。**后端启动时不跑 migration**。
- **后端分包按领域**（`notes`、`tags`、`search`、`portfolio`、`audit`），禁止建 `handlers/`、`services/`、`repositories/`；跨领域公共代码只放 `httpx` / `auth` / `config`。
- **搜索**只查生成列 `notes.search_text`，应用层不写该字段；`ILIKE '%q%'`，无中文分词。
- **公开可见条件唯一**：`visibility = 'public' AND published_at IS NOT NULL`；撤回 public→private 时保留 `published_at`。
- **跨用户访问返回 404 而非 403**；403 只留给"已登录但权限不足"（如 read Token 做写操作）。
- **JSON 一律 `snake_case`**，不转 camelCase；列表响应固定 `{items, total}`（空列表不能是 null）；笔记列表 item 必须带后端截断好的 `content_preview`（按 rune 截 200）。
- **凭证类操作**（Token / 授信设备 / 会话 / TOTP / 密码）Token 一律 403，只允许 Web 会话；其中 TOTP 关闭、改密码、增删改查 Token 需要会话已通过 TOTP。
- cookie 名、有效期、bcrypt cost 等是代码常量，**不从环境变量读取**（清单在 `docs/architecture.md` 第四节）。
- 审计只在业务成功后写、失败只打日志不影响响应；笔记 CRUD 不写审计，只有 publish/unpublish 写。

## Git 规范

- 提交信息沿用现有风格：`feat(backend): ...` / `fix(frontend): ...` / `doc(docs): ...`，**中文描述**，不加 AI 署名或 `Co-Authored-By`。
- 只提交自己本次改动的文件；不要 `git add -A` / `git commit -a`，以免带上别人未完成的改动。
- **未经用户明确要求，不要 commit / amend / push / rebase / reset**；不要改写已有提交历史。
- `docs/` 只读，因此任何 AI 发起的提交都不应包含 `docs/` 变更；若 `git status` 里 `docs/` 有改动，视为人类未提交的编辑，必须原样保留。
- 提交前先跑与改动范围对应的验证（`go build ./...` + `go test ./...`，或 `pnpm build`）；`node_modules/`、`frontend/dist/` 已在 `.gitignore` 中，不要强制添加。
- 不创建 PR、不推送到 `main`、不擅自切换或创建分支，除非用户要求。
