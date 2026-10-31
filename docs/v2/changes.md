# changes — 第二期变更清单

> 本文件回答：v1 的哪些文件/节在第二期被改动或作废、由 v2 的哪个文件哪一节接管。
> 依赖：`../README.md`（覆盖规则）

本文件是 v2 的**入口**。规则见 `../README.md` 第二节：

> v2 中出现的节覆盖 v1 同名节；v1 中未被 v2 提及的内容继续有效。

## 一、二期范围

| 序 | 功能 | 文档 | 说明 |
|---|---|---|---|
| **F3** | 测试补齐 | `backend/test-plan.md` | **最先做**，保证 v1 现有测试全绿后再动功能 |
| **F1** | 回收站 | `api.md` 第二、四节；`backend/data-model.md` 第一、三节；`frontend/frontend.md` 第一至四节 | 软删除 + 还原 + 永久删除 + 30 天惰性清理 |
| **F2** | 历史版本 | `api.md` 第三、四节；`backend/data-model.md` 第二、三节；`frontend/frontend.md` 第五节 | 编辑页内浮层、DIFF 基准为「版本 ↔ 当前内容」 |

开发顺序：**F3 → F1 → F2**。F1 的可见性改动影响 F2 的全部查询，必须先落地。

不纳入二期：LLM（翻译/润色/对话）、公开站增强、TUI 与 Neovim。

## 二、登记格式

| # | v1 文件 / 节 | 变更类型 | 变更说明 | v2 落点 |
|---|---|---|---|---|

- **变更类型**：`扩展`（v1 内容仍成立）/ `替换`（v1 结论被改掉）/ `作废`（整节不再适用）/ `解除禁令` / `新增`（v1 无对应节）。
- **v2 落点**：接管该节的 `文件#节`；无替代内容填 `—`。

## 三、清单

| # | v1 文件 / 节 | 变更类型 | 变更说明 | v2 落点 |
|---|---|---|---|---|
| 1 | `v1/conventions.md` 第五节「追加规则」 | 扩展 | 二期新增约定（只加列、可见性唯一、常量清单），未解除任何 v1 禁令 | `v2/conventions.md` 第一节 |
| 2 | `v1/conventions.md` 第四节「硬性禁令清单」 | 扩展 | 新增二期禁令（不做回收站看版本、不做定时清理、不引 DIFF 库等） | `v2/conventions.md` 第二节 |
| 3 | `v1/backend/data-model.md` 第十节「notes」 | 扩展 | 新增 `deleted_at` 列与回收站索引；明确可见性需排除已删行 | `v2/backend/data-model.md` 第一节 |
| 4 | `v1/backend/data-model.md`（无对应表） | 新增 | 新增 `note_versions` 表 | `v2/backend/data-model.md` 第二节 |
| 5 | `v1/backend/data-model.md` 的 migration 顺序 | 扩展 | 追加 `0006`、`0007` | `v2/backend/data-model.md` 第三节 |
| 6 | `v1/api.md` 6.5「DELETE `/api/notes/:id`」 | **替换** | 从永久删除改为移入回收站 | `v2/api.md` 1.1 |
| 7 | `v1/api.md`（无对应章节） | 新增 | 回收站四个接口 | `v2/api.md` 第二节 |
| 8 | `v1/api.md`（无对应章节） | 新增 | 历史版本三个接口 | `v2/api.md` 第三节 |
| 9 | `v1/backend/auth.md` 6.3「可见性过滤条件」 | 扩展 | 两个可见性常量追加 `deleted_at IS NULL` | `v2/backend/data-model.md` 第一节规则 3（实现落点见 `v2/conventions.md` 第一节第 4 条） |
| 10 | `v1/frontend/frontend.md` 第四节「私有域路由」 | 扩展 | 新增 `/trash` 路由 | `v2/frontend/frontend.md` 第一节 |
| 11 | `v1/frontend/ui-design.md` 第八节「侧边栏结构」 | 扩展 | 在 `sidebar__spacer` 与用户区之间新增「回收站」入口 | `v2/frontend/frontend.md` 第二节 |
| 12 | `v1/frontend/frontend.md`（无对应页面） | 新增 | 回收站页面与交互 | `v2/frontend/frontend.md` 第三节 |
| 13 | `v1/frontend/frontend.md` 第四节「删除笔记」文案 | 替换 | 确认框从「无法恢复」改为「可在回收站中还原」 | `v2/frontend/frontend.md` 第四节 |
| 14 | `v1/frontend/ui-design.md` 第七节「编辑器与阅读态规范」 | 扩展 | 编辑页工具栏新增历史版本按钮与浮层、DIFF 规则 | `v2/frontend/frontend.md` 第五节 |
| 15 | `v1/conventions.md` 第三节「目录边界」中的测试约定 | 新增 | 二期测试补齐的目标、范围与完成标准 | `v2/backend/test-plan.md` |

## 四、v1 表述的时效说明

本期**不解除** `v1/conventions.md` 第四节任何禁令，因此不涉及「v1 禁令作废」。

`v1` 中「第二版再做」的相关表述（TUI / Neovim、LLM、语义检索）**在二期仍未实现**，继续保持有效，不作登记。
