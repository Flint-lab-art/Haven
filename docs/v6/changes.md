# changes — 第六期变更清单

> 本文件回答：v1–v5 的哪些文件/节在第六期被改动或作废、由 v6 的哪个文件哪一节接管。
> 依赖：`../README.md`（覆盖规则）

本文件是 v6 的**入口**。规则见 `../README.md` 第二节：

> v6 中出现的节覆盖早期版本同名节；未被 v6 提及的内容继续有效。

## 一、六期范围

**主题：命令面板与快捷键。**

工作台的操作入口分散在侧边栏、列表栏与编辑区工具栏，找一篇笔记或执行一个动作都要用鼠标。本期加入 `Cmd+K` 命令面板与常用快捷键。

| 序 | 功能 | 说明 |
|---|---|---|
| **C1** | 命令面板 | `Cmd/Ctrl+K` 打开，搜笔记标题、执行常用命令 |
| **C5** | 文件夹选择器 | 命令面板 `n 标题` 回车后弹出，用 `j/k` 选保存位置 |
| **C2** | 快捷键 | `Cmd/Ctrl+S` 保存、`Cmd/Ctrl+N` 新建 |
| **C3** | 搜索 `type` 参数 | `GET /api/search?type=title\|title_content` |
| **C4** | 标题索引 | `notes.title` 的 trigram 索引，支撑 `type=title` |
| **C6** | 任务列表复选框 | 编辑器里点方块直接勾选 / 取消（GitHub / Notion 式） |
| **C7** | 代码块复制 | 代码块右上角复制按钮，编辑态与阅读态都有 |

开发顺序：**C3 → C4 → C1 → C5 → C2**。命令面板依赖标题搜索，先做后端。

C6 与命令面板互不依赖，随时可做。C7 的复制按钮属于编辑器内控件，受 `v6/conventions.md` 第一节第 7 条约束（该条已同步放行）。

不纳入六期：Vim 模式、编辑器内快捷键、可配置键位。

## 二、登记格式

| # | 文件 / 节 | 变更类型 | 变更说明 | v6 落点 |
|---|---|---|---|---|

- **变更类型**：`扩展`（原内容仍成立）/ `替换`（原结论被改掉）/ `作废`（整节不再适用）/ `解除禁令` / `新增`（原版本无对应节）。
- **v6 落点**：接管该节的 `文件#节`；无替代内容填 `—`。

## 三、清单

| # | 文件 / 节 | 变更类型 | 变更说明 | v6 落点 |
|---|---|---|---|---|
| 1 | `v1/api.md` 10.1「GET `/api/search`」 | 扩展 | 新增 `type` 参数：`title` / `title_content`（默认） | `v6/api.md` 第一节 |
| 2 | `v1/backend/data-model.md` 第十节「notes」索引 | 扩展 | 新增 `idx_notes_title_trgm` | `v6/backend/data-model.md` 第一节 |
| 3 | `v1/frontend/frontend.md`（无对应节） | 新增 | 命令面板的触发、内容与交互 | `v6/frontend/frontend.md` 第一节 |
| 4 | `v1/frontend/frontend.md`（无对应节） | 新增 | 全局快捷键清单与冲突处理 | `v6/frontend/frontend.md` 第二节 |
| 5 | `v1/conventions.md` 第四节「前端」条 | 扩展 | 允许命令面板劫持浏览器默认快捷键 | `v6/conventions.md` 第二节 |
| 6 | `v1/frontend/ui-design.md`（无对应节） | 新增 | 文件夹选择器：平铺路径、j/k 移动 | `v6/frontend/frontend.md` 第三节 |
| 7 | `v1/frontend/ui-design.md` 7.1「Milkdown 编辑器专属配置（必须遵守）」 | 扩展 | 列表项改由组件渲染；任务列表的方块可点，点击写回 `- [ ]` / `- [x]` | `v6/frontend/frontend.md` 第五节 |
| 8 | `v1/conventions.md` 第六节「已知不做」中「引入第三方 UI 组件库须经维护者同意」 | 扩展 | 维护者已同意引入 `@milkdown/components` 的列表项组件，用于任务列表复选框 | `v6/conventions.md` 第一节第 6 条 |
| 9 | `v1/frontend/ui-design.md` 7.1「Milkdown 编辑器专属配置（必须遵守）」 | 扩展 | 代码块右上角新增复制按钮（编辑态与阅读态都有） | `v6/frontend/frontend.md` 第六节 |
| 10 | `v1/frontend/ui-design.md`（无对应节） | 新增 | 中文输入法全角符号导致 Markdown 语法不生效的已知陷阱 | `v6/frontend/frontend.md` 第七节 |
| 11 | `v1/frontend/ui-design.md` 7.1「Milkdown 编辑器专属配置（必须遵守）」 | 扩展 | 代码块语言支持范围、别名归一、不支持时按纯文本（不自动猜测） | `v6/frontend/frontend.md` 第八节 |

## 四、旧版本表述的时效说明

- v1 `api.md` 10.1 只描述了 `search_text` 的匹配，本期起可只搜标题，该节由 `v6/api.md` 第一节接管扩展部分。
- v1 `ui-design.md` 7.1 第 2 条要求「只保留纯净的输入区」，本期任务列表的方块是编辑器内的唯一可点控件，不构成工具栏，该条继续有效；7.1 对列表排版的约束由 `v6/frontend/frontend.md` 第五节补充。
- 本期**不解除** `v1/conventions.md` 第四节任何禁令。第六节「引入第三方组件库须经维护者同意」不是禁令，本期按流程取得同意后登记，见 `v6/conventions.md` 第一节第 6 条。
