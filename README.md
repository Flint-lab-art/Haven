# Haven

自托管的个人综合知识中台。PostgreSQL 为唯一真值源，Go + Gin 后端，Vue 3 前端，公开域与私有域分离部署。Web 浏览器为一等主入口。

## 当前版本

**二期（v2）开发中。**

- **已落地**：一期（v1），文档见 `docs/v1/`，与当前 `backend/`、`frontend/` 代码一一对应；
- **进行中**：二期（v2），文档见 `docs/v2/`，v1 → v2 的差异登记在 `docs/v2/changes.md`；
- **二期范围与顺序**：F3 测试补齐 → F1 回收站 → F2 历史版本；
- **二期明确不做**：LLM（翻译 / 润色 / 对话）、公开站增强、TUI 与 Neovim。

v1 与 v2 的关系、覆盖规则、生成代码时该读哪些文件，见 `docs/README.md`。

## 文档即事实来源

本项目所有代码由 opencode + DeepSeek 依据 `docs/` 生成，**文档是唯一事实来源**：

- 代码与文档冲突时，以文档为准；
- 改需求先改文档，再重新生成代码；
- `docs/` 只能由人类修改，AI 只读不写。

完整规则见 `docs/v1/conventions.md`，二期补充见 `docs/v2/conventions.md`。

## 文档索引

文档按版本分目录（`docs/v1/`、`docs/v2/` …），完整导航表见 **`docs/README.md`**，本文件不重复维护。

- **一期（已落地）**：`docs/v1/` — 项目级 4 篇、后端 5 篇、前端 3 篇；
- **二期（进行中）**：`docs/v2/` — 只写新增与变更，含 `changes.md`（变更清单）、`api.md`、`backend/`、`frontend/`。

## 仓库结构

```
Haven/
├── docs/           # 唯一事实来源（v1/、v2/ 分版本）
├── backend/        # Go 后端（Gin + database/sql + pgx）
├── frontend/       # Vue 3 + Vite 前端
├── deploy/         # 部署脚本与 systemd unit
├── AGENTS.md       # 给 AI 的工作约定
└── README.md
```

后端代码只写 `backend/`，前端代码只写 `frontend/`，不得交叉。

## 工作流

生成代码时，按任务类型喂上下文，**始终是「当前版本全文 + 之前各版本」叠加**：

- **生成后端代码**：`docs/` 根下项目级文件 + `docs/v1/backend/` + `docs/v1/api.md`，叠加 `docs/v2/api.md`、`docs/v2/conventions.md`、`docs/v2/backend/`；
- **生成前端代码**：`docs/` 根下项目级文件 + `docs/v1/frontend/` + `docs/v1/api.md`，叠加 `docs/v2/api.md`、`docs/v2/conventions.md`、`docs/v2/frontend/`。

覆盖规则：v2 中出现的节替换 v1 同名节；v2 未提及的内容按 v1 执行。详见 `docs/README.md` 第二节。

生成结果与文档不符时，是代码错，修代码或重新生成，不改文档去迁就代码。

## 快速开始（本地开发）

前置：PostgreSQL ≥ 15（需 `pg_trgm` 扩展）、Go ≥ 1.22、Node ≥ 20 + pnpm。

```bash
# 1. 建库并建表（migration 不会随服务启动自动执行）
createdb haven_dev
psql "postgres://haven:haven_dev_pw@127.0.0.1:5432/haven_dev?sslmode=disable" \
  -f backend/migrations/0001_init.up.sql

# 2. 创建唯一账号（密码至少 12 位）
cd backend
HAVEN_DB_DSN="postgres://haven:haven_dev_pw@127.0.0.1:5432/haven_dev?sslmode=disable" \
  HAVEN_INIT_PASSWORD='至少12位的密码' go run ./cmd/haven-init-user -username kairo
cd ..

# 3. 构建前端并启动
cd frontend && pnpm install && pnpm build && cd ..
./run-dev.sh
```

打开 <http://localhost:8080/>。本地开发时 `localhost` 按私有域渲染（见 `frontend/src/router/domain.ts`）。

生产部署（systemd、反向代理、备份）见 `docs/v1/architecture.md` 第八节与 `deploy/` 目录。

## 技术栈

Go ≥ 1.22 / Gin / PostgreSQL ≥ 15（`pg_trgm`）/ Vue 3 / Vite / TypeScript。详见 `docs/v1/architecture.md`。
