# changes — 第三期变更清单

> 本文件回答：v1/v2 的哪些文件/节在第三期被改动或作废、由 v3 的哪个文件哪一节接管。
> 依赖：`../README.md`（覆盖规则）

本文件是 v3 的**入口**。规则见 `../README.md` 第二节：

> v3 中出现的节覆盖 v1、v2 同名节；未被 v3 提及的内容继续有效。

## 一、三期范围

**主题：公开站首页改版。**

目的：公开域当前以「公开笔记列表」为主体，作品集是二级页面。三期把作品集提到首页主位，让首页更像对外展示的个人主页，而不是一个笔记索引。

| 项 | 内容 |
|---|---|
| 首页结构 | 品牌标语 → 作品集（双列卡片）→ 近期笔记 |
| 视觉风格 | 放宽 v1 `ui-design.md` 的排版约束，按对外展示重新设计 |
| 内容宽度 | 由 800px 放宽到 960px |
| 新增页面 | `/notes`：全部公开笔记列表 |
| 移除 | 首页的搜索框 |
| 作品详情 | 新增公开详情页 `/portfolio/:id`，作品可写 Markdown 介绍正文 |
| 后端 | 新增 `portfolio_items.content` 字段与 `GET /api/public/portfolio/:id` |

**范围调整说明**：三期最初规划「不改后端」。实现作品详情时发现作品集只有 `title` + `description`，没有任何可展示的介绍正文，公开页点开作品只有几个链接。因此本期增加 `portfolio_items.content` 字段与一个公开详情接口。这是对原计划的扩展，已登记在下方清单第 7–10 条。

不纳入三期：RSS、分页器、按标签浏览、上一篇/下一篇、LLM、TUI 与 Neovim。

## 二、登记格式

| # | 文件 / 节 | 变更类型 | 变更说明 | v3 落点 |
|---|---|---|---|---|

- **变更类型**：`扩展`（原内容仍成立）/ `替换`（原结论被改掉）/ `作废`（整节不再适用）/ `解除禁令` / `新增`（原版本无对应节）。
- **v3 落点**：接管该节的 `文件#节`；无替代内容填 `—`。

## 三、清单

| # | 文件 / 节 | 变更类型 | 变更说明 | v3 落点 |
|---|---|---|---|---|
| 1 | `v1/frontend/frontend.md` 第三节「公开域路由」 | 替换 | `/` 从「公开笔记列表 + 搜索入口」改为「品牌标语 + 作品集 + 近期笔记」；新增 `/notes` 页 | `v3/frontend/frontend.md` 第一节 |
| 2 | `v1/frontend/frontend.md` 第三节「公开域路由」规则 | 扩展 | 公开域仍无登录入口与写操作入口；搜索框不再出现在首页，`/search` 路由保留 | `v3/frontend/frontend.md` 第一节 |
| 3 | `v1/frontend/ui-design.md` 第十节「公开域笔记列表排版规范」 | 替换 | 笔记行沿用「日期 → 标题 → 摘要」，但间距与字号按新版规格调整 | `v3/frontend/frontend.md` 第四节 |
| 4 | `v1/frontend/ui-design.md` 第二节「整体布局」 | 扩展 | 公开域内容宽度由 800px 放宽到 960px，私有域三栏布局不变 | `v3/frontend/frontend.md` 第二节 |
| 5 | `v1/frontend/ui-design.md`（无对应节） | 新增 | 公开域新增作品集卡片网格、区块标题与「全部」链接的视觉规格 | `v3/frontend/frontend.md` 第三、五节 |
| 6 | `v1/conventions.md` 第四节「前端」条 | 扩展 | 公开域的排版可脱离 `ui-design.md`，但仍受「不做 SSR / 不做 SEO 优化」约束 | `v3/conventions.md` 第二节 |
| 7 | `v1/backend/data-model.md` 第十三节「portfolio_items」 | 扩展 | 新增 `content` 列（作品介绍正文，Markdown） | `v3/backend/data-model.md` 第一节 |
| 8 | `v1/api.md` 第十一节「作品集」 | 扩展 | `POST` / `PATCH` 接受 `content`；公开列表不返回正文 | `v3/api.md` 第一节 |
| 9 | `v1/api.md`（无对应章节） | 新增 | 私有作品详情 `GET /api/portfolio/:id`（列表不含正文） | `v3/api.md` 1.2 |
| 9.1 | `v1/api.md`（无对应章节） | 新增 | 公开作品详情 `GET /api/public/portfolio/:id` | `v3/api.md` 2.2 |
| 10 | `v1/backend/data-model.md` 的 migration 顺序 | 扩展 | 追加 `0008_portfolio_content` | `v3/backend/data-model.md` 第二节 |
| 11 | `v1/frontend/frontend.md` 第四节「私有域路由」的 `/tags` | **替换** | 标签页改为只读的卡片网格，去掉新建与删除操作 | `v3/frontend/frontend.md` 第十节 |

## 四、旧版本表述的时效说明

- v1 `frontend.md` 第三节把公开域 `/` 定义为「公开笔记列表（首页）」，三期起首页不再是纯列表，该行由 `v3/frontend/frontend.md` 第一节接管。
- v1 `ui-design.md` 第十节的公开笔记排版规范仍然有效，但具体间距与字号以 v3 为准。
- 三期**不解除** v1 第四节任何禁令。
