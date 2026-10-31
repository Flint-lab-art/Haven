# README — Haven 文档索引

> 本文件回答：Haven 的文档分几期、各期文档放在哪、各期之间是什么关系、生成代码时该读哪些文件。
> 依赖：无

本目录是 Haven 的**文档来源**，按期（版本）分文件夹：

```
docs/
├── README.md      # 本文件：索引 + 覆盖规则（唯一出处）
├── v1/            # 第一期文档（已冻结，与一期代码一一对应）
├── v2/            # 第二期文档（回收站、历史版本）
└── v3/            # 第三期文档（公开站改版）
```

## 一、分期原则

- **v1 是已完成并已落地的版本。**
- **v2 已落地**：回收站与历史版本。
- **v3 已落地**：公开站改版、作品详情、标签页。
- **v4 是第四期**：图片改为上传到磁盘，正文只存 URL。
- **后一版不修改前一版。** 各期文档永久保留，作为该期实现时的依据。
- 各期内部目录结构与 v1 **完全镜像**：文件名相同意味着「对应同一个问题的该期版本」。

## 二、覆盖规则（本节是唯一出处）

后一版是前一版的**增量覆盖层**，按以下顺序理解：

1. **逐节覆盖，粒度是「节」不是「文件」。** 新版本某文件里出现的某一节，替换旧版本同名文件里的同名节；没出现的节，旧版本原样有效。
2. **文件级等同「全部替换」。** 若整节替换，必须在该节开头写明「本节整节替换 vX 同名节，以本文件为准」。
3. **没提的一律沿用。** 包括：路由、字段、错误码、禁令、常量、目录结构。
4. **新增优先。** 同一问题在多个版本都写到时，版本号最大的优先，且该文件必须说明「这与哪一版哪一节不同」。
5. **禁令同样适用覆盖规则，但必须显式解除。** `v1/conventions.md` 第四节的禁令默认继续有效；要做什么而 v1 明文禁止的，必须在对应版本的 `conventions.md` 里登记「解除哪条、理由、日期」。
6. **冲突处理**：出现无法用上面规则判定的矛盾时，不要自行取舍，停下来问人类。

**当前有效文档 = v1 + v2 + v3 叠加**（按上表顺序覆盖）。

## 三、旧版本已过期的表述怎么处理

旧版本里「本期不做、以后再做」的表述，若后续版本实现，**不改旧文档**，而是在新版本的 `changes.md` 登记「哪个文件、哪一节、被什么替代」。

## 四、生成代码时读哪些文件

当前是 v3 阶段，上下文是**v1 全文 + v2 全文 + v3 全文**：

- **后端**：`v1/` 根下项目级文件 + `v1/backend/` + `v1/api.md`，叠加 `v2/api.md`、`v2/conventions.md`、`v2/backend/`；
- **前端**：`v1/` 根下项目级文件 + `v1/frontend/` + `v1/api.md`，叠加 `v2/api.md`、`v2/conventions.md`、`v2/frontend/`，再叠加 `v3/conventions.md`、`v3/frontend/`，再叠加 `v4/api.md`、`v4/conventions.md`、`v4/frontend/`；
- **优先级**：以第二节的覆盖规则为准。

各期代码**都在同一个 `backend/`、`frontend/` 仓库里增量演进**，不新建并列目录。

## 五、各期文件清单

### v2（已落地）

| 文件 | 对应的 v1 文件 | 改动概述 |
|---|---|---|
| `v2/changes.md` | —（新增） | v1 → v2 的逐条变更清单 |
| `v2/conventions.md` | `v1/conventions.md` | 二期约定补充 + 禁令变更 |
| `v2/api.md` | `v1/api.md` | 回收站 4 个接口、历史版本 3 个接口、`DELETE /api/notes/:id` 语义变更 |
| `v2/backend/data-model.md` | `v1/backend/data-model.md` | `notes.deleted_at`、`note_versions` 表、migration 规划 |
| `v2/backend/test-plan.md` | —（新增） | 测试补齐的范围与完成标准 |
| `v2/frontend/frontend.md` | `v1/frontend/frontend.md` | `/trash` 页面、侧边栏入口、删除文案、历史版本浮层 |

### v3（进行中）

| 文件 | 对应的 v1 文件 | 改动概述 |
|---|---|---|
| `v3/changes.md` | —（新增） | v1/v2 → v3 的逐条变更清单，v3 的入口 |
| `v3/conventions.md` | `v1/conventions.md` | 三期约定：公开域排版不再完全受 `ui-design.md` 约束 |
| `v3/api.md` | `v1/api.md` | `portfolio_items.content`、公开作品详情接口 |
| `v3/backend/data-model.md` | `v1/backend/data-model.md` | `portfolio_items.content` 列与 `0008` migration |
| `v3/frontend/frontend.md` | `v1/frontend/frontend.md` | 公开域首页改版、新增 `/notes` 与作品详情页、作品集网格与视觉规格 |

**v3 以公开域前端为主**；作品详情需要介绍正文，因此新增了 `portfolio_items.content` 字段与一个公开详情接口。

### v4（进行中）

| 文件 | 对应的 v1 文件 | 改动概述 |
|---|---|---|
| `v4/changes.md` | —（新增） | 四期范围与逐条变更清单，v4 的入口 |
| `v4/conventions.md` | `v1/conventions.md` | 图片存磁盘的约定与部署约束（systemd 写权限） |
| `v4/api.md` | `v1/api.md` | `HAVEN_UPLOAD_DIR`、`/uploads/*` 静态托管、`POST /api/uploads` |
| `v4/backend/data-model.md` | `v1/backend/data-model.md` | `folders.icon` 可存图片路径；本期无 migration |
| `v4/frontend/frontend.md` | `v1/frontend/frontend.md` | 编辑器插图上传播、文件夹图标上传与展示 |

## 六、v1 目录导航

### 项目级（前后端共享）

| 文件 | 回答的问题 |
|---|---|
| `v1/overview.md` | Haven 是什么、面向什么场景、由哪几部分组成、主页承担什么职责 |
| `v1/architecture.md` | 技术架构、目录结构、配置项清单、部署形态 |
| `v1/conventions.md` | 文档归属规则、文档与代码的主从关系、**硬性禁令清单** |
| `v1/api.md` | HTTP 接口契约 |

### 后端

| 文件 | 回答的问题 |
|---|---|
| `v1/backend/data-model.md` | 全部表结构（唯一出处） |
| `v1/backend/auth.md` | 鉴权与权限模型、权限矩阵 |
| `v1/backend/audit.md` | 审计事件清单与写入时机 |
| `v1/backend/search.md` | 搜索的匹配规则、索引与已知限制 |
| `v1/backend/llm-extension.md` | LLM 抽象层接口定义与未来落点 |

### 前端

| 文件 | 回答的问题 |
|---|---|
| `v1/frontend/frontend.md` | 公开域/私有域路由、登录流程、全局状态、API 客户端约定 |
| `v1/frontend/ui-design.md` | 布局、色彩排版、组件规范、树状目录交互 |
| `v1/frontend/clients.md` | TUI 与 Neovim 插件的边界（一期只占位） |

## 七、维护规则

- 本目录的修改只由人类完成，AI 只读。
- 新增文档前，先在第五节登记一行，再创建文件；每个文件开头保留固定两行（`本文件回答` / `依赖`）。
- 文档归属按 `v1/conventions.md` 第一节判断（约束后端 → `backend/`，约束前端 → `frontend/`，共享 → 根）。
