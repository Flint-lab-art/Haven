下面是 `README.md` 初稿。根目录文件，定位是**索引 + 工作流入口**，不重复任何文档的内容。

---

# Haven

自托管的个人综合知识中台。PostgreSQL 为唯一真值源，Go + Gin 后端，Vue 3 前端，公开域与私有域分离部署。本期只做 Web 端，TUI 与 Neovim 插件在第二版。

## 文档即事实来源

本项目所有代码由 opencode + DeepSeek 依据 `docs/` 生成，**文档是唯一事实来源**：

- 代码与文档冲突时，以文档为准；
- 改需求先改文档，再重新生成代码；
- `docs/` 只能由人类修改，AI 只读不写。

完整规则见 `docs/conventions.md`。

## 文档索引

### 项目级（`docs/`）

| 文件 | 回答什么问题 |
|---|---|
| `overview.md` | Haven 是什么、面向什么场景、由哪几部分组成 |
| `architecture.md` | 技术栈、目录结构、组件关系、配置项、部署形态 |
| `conventions.md` | 文档与代码的组织规则、主从关系、硬性禁令清单 |
| `api.md` | 每个 HTTP 接口的路径、请求、响应、鉴权、错误码 |

### 后端（`docs/backend/`）

| 文件 | 回答什么问题 |
|---|---|
| `data-model.md` | 数据库有哪些表、字段、约束、索引、业务规则 |
| `auth.md` | 鉴权分层、会话、授信设备、API Token、授权中间件 |
| `audit.md` | 审计记录哪些事件、表结构、写入时机 |
| `llm-extension.md` | LLM 抽象层接口定义（本期只定义不实现） |

### 前端（`docs/frontend/`）

| 文件 | 回答什么问题 |
|---|---|
| `ui-design.md` | 界面布局、色彩排版与组件规范 |
| `frontend.md` | 公开域与私有域的页面清单、路由、登录流程 |
| `clients.md` | TUI 与 Neovim 插件（第二版，本期占位） |

## 仓库结构

```
Haven/
├── docs/           # 唯一事实来源
├── backend/        # Go 后端（Gin + database/sql + pgx）
├── frontend/       # Vue 3 + Vite 前端
├── deploy/         # 部署脚本（如需要）
└── README.md
```

后端代码只写 `backend/`，前端代码只写 `frontend/`，不得交叉。

## 工作流

生成代码时，按任务类型喂上下文：

- **生成后端代码**：`docs/` 根下项目级文件 + `docs/backend/` + `docs/api.md`；
- **生成前端代码**：`docs/` 根下项目级文件 + `docs/frontend/` + `docs/api.md`。

生成结果与文档不符时，是代码错，修代码或重新生成，不改文档去迁就代码。

## 快速开始（本地开发）

前置：PostgreSQL ≥ 15、Go ≥ 1.22、Node ≥ 20 + pnpm。

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

生产部署（systemd、反向代理、备份）待定，见 `docs/architecture.md` 第八节。

## 技术栈

Go ≥ 1.22 / Gin / PostgreSQL ≥ 15（`pg_trgm`）/ Vue 3 / Vite / TypeScript。详见 `docs/architecture.md`。
