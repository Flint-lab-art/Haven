# conventions — 编码约定与硬性约束

> 本文件回答：文档与代码的组织规则、文档与代码的主从关系、以及本项目的硬性禁令清单。
> 依赖：无

本文件是给 opencode + DeepSeek 生成代码时的护栏。每次生成跑偏，就把对应的禁令追加到本文件，不另起新文件。

## 一、文档归属规则

文档按“约束谁”划分目录，不按“代码在哪”划分：

- `docs/backend/`：只约束后端的文档
- `docs/frontend/`：只约束前端的文档（含 TUI / Neovim 客户端）
- `docs/` 根：前后端共享的契约，或项目级文档

当前文件归属：

- `docs/overview.md` — 项目定位、场景、非目标（项目级）
- `docs/architecture.md` — 整体架构、目录结构、部署形态（项目级）
- `docs/conventions.md` — 本文件（项目级）
- `docs/api.md` — HTTP 接口契约，前后端共享，固定放根目录
- `docs/backend/data-model.md` — 数据库 schema（全部表结构的唯一出处，其他文档只引用不重复）
- `docs/backend/auth.md` — 鉴权与权限模型
- `docs/backend/audit.md` — 审计日志
- `docs/backend/search.md` — 搜索设计与匹配规则
- `docs/backend/llm-extension.md` — LLM 抽象层预留
- `docs/frontend/frontend.md` — Web 前端页面与交互
- `docs/frontend/clients.md` — TUI 与 Neovim 插件
- `docs/frontend/ui-design.md` — UI 与交互设计规范

新增文档时，先判断它约束谁，再决定放哪个目录。

## 二、文档与代码的主从关系

1. `docs/` 是唯一事实来源。所有代码由 opencode + DeepSeek 依据文档生成，不以代码反推文档。
2. 代码与文档冲突时，以文档为准。生成结果不符合文档，是代码错，重新生成或修正代码，不修改文档去迁就代码。
3. 改需求先改文档。任何功能变更、接口变更、数据模型变更，先落文档，再重新生成相关代码。
4. 文档回答的问题必须唯一。同一个问题只在一个文件里回答；如果发现两处都在回答同一问题，合并到一处，另一处改为引用。数据库表结构统一由 `data-model.md` 回答，`auth.md` / `audit.md` / `search.md` 只写规则与索引用法，不重复字段表。
5. 文档只能由人类修改。opencode / AI 只读取 `docs/` 生成代码，不得写入或修改 `docs/` 下任何文件。文档的增删改一律由项目维护者手动完成。

每个文档文件开头固定两行：

> 本文件回答：<一句话，这个问题只有本文件回答>
> 依赖：<前置文件，没有就写“无”>

## 三、目录边界

Haven/
├── docs/           # 唯一事实来源
├── backend/        # Go 后端，代码只写在这里
├── frontend/       # Vue 前端，代码只写在这里
├── deploy/         # 部署脚本（systemd unit、构建脚本等），如需要
└── README.md

- 后端代码只写在 `backend/` 下，前端代码只写在 `frontend/` 下，不得交叉。
- 生成后端代码时，上下文为 `docs/` 根下项目级文件 + `docs/backend/` + `docs/api.md`。
- 生成前端代码时，上下文为 `docs/` 根下项目级文件 + `docs/frontend/` + `docs/api.md`。

## 四、硬性禁令清单

本清单只锁“不做什么”，不锁“具体怎么做”。具体实现方式以 `architecture.md` 为准。

以下事项本项目明确不做。opencode 生成代码时不得自行添加，发现即视为生成错误。

### 架构与部署

- 不使用 Docker / Docker Compose 部署本项目。
- 不使用 Kubernetes。
- 原因备注：同机 Gogs 若跑在容器中会导致 SSH 失败；为避免同类问题，Haven 不使用容器。
- 不引入 PostgreSQL 之外的存储作为真值源；Redis / 对象存储等如后续需要，只作为辅助，不存真值。
- 不做多租户、不做多用户协作，本项目是单人自用。数据模型保留 `user_id` 归属字段，是为将来可能的第二个账号预留技术位；**不代表本期要实现注册、邀请、账号管理等多人功能**。所有接口仍按“当前登录用户”过滤，不提供账号创建入口。


### 前端

- 不做 SSR / Nuxt / 预渲染，纯 Vue 3 + Vite SPA。
- 不为 SEO 做任何专门优化。

### 后端 / 接口

- 创建笔记接口不接受 `visibility` 参数，新建笔记一律为 private；公开走独立的 publish 动作。
- `visibility` 的默认值在数据库层固化（DEFAULT 'private' + NOT NULL），不依赖应用层传值。
- API Token 只做 `read` / `read_write` 两档 scope，不做细粒度权限。
- 所有读接口统一走授权中间件做 visibility 收敛，不在各 handler 里各自判断。
- 后端 HTTP 层统一用 Gin，不引入 chi / Echo 等其他 Web 框架；`*gin.Context` 只允许出现在 handler 层，不得传入业务层与数据访问层。

### 客户端

- TUI 与 Neovim 插件只覆盖“读写笔记 + 检索”主路径，不做功能对等，其余交给 Web。
- 次级客户端以服务端为准，不做离线编辑与冲突合并（如后续要做，先改本文档再实现）。
- 本期（第一版）不实现 TUI 和 Neovim 插件，不创建任何相关代码。第二版再动工，设计另写。

### LLM

- 本期只定义 `LLMProvider` 接口，不实现任何 LLM 调用。
- 抽象层不泄漏具体模型 SDK 到业务层。

### 审计

- 前期只记录安全与状态事件（登录成功/失败、TOTP 验证、Token 创建/撤销、授信设备添加/撤销、笔记 publish）。
- 笔记 CRUD 等高频业务事件前期不记录。

## 五、追加规则

- 每次 opencode 生成结果出现“文档没写、但代码自作主张”的行为，由项目维护者（人类）判断是否合理：
  - 合理：补进对应文档，作为正式需求；
  - 不合理：追加到本文件第四节禁令清单。
- 本文件第四节只增不删；确需解除禁令时，写明原因和日期。
- AI / opencode 不得自行修改 `docs/` 下任何文件，也不得自行向禁令清单追加条目。
