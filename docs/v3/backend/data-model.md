# data-model — 三期 schema 变更

> 本文件回答：三期对数据库表结构做了哪些改动（v1/v2 未覆盖的部分）。
> 依赖：`../../v1/backend/data-model.md`、`../v2/backend/data-model.md`

覆盖规则见 `../../README.md` 第二节。本文件中出现的节替换旧版本同名节；未出现的内容继续有效。

## 一、portfolio_items 表变更

在现有表基础上**只新增一列**，其余字段、约束、索引不变。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `content` | text | NOT NULL | `''` | 作品介绍正文（Markdown 源文本），公开详情页渲染用 |

**规则**：

1. **正文由使用者手动填写**，不自动抓取仓库 README。
2. **列表接口不返回正文**：`GET /api/public/portfolio` 只查 `id, title, description, sort_order`；正文只在详情接口 `GET /api/public/portfolio/:id` 返回。
3. **空串即「没有写介绍」**：前端据此显示占位提示，不视为错误。
4. **不做版本历史**：作品正文不进入 `note_versions`，版本功能只服务笔记。

## 二、portfolio_repos 表变更

**相关链接改为直接存完整 URL，不再按 platform 拼接。** 同时删除 `platform`，新增 `title`。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `url` | text | NOT NULL | `''` | 完整地址（http/https） |
| `title` | text | NOT NULL | `''` | 非仓库链接在公开页展示的文字；仓库链接留空 |

**删除的字段**：`platform`（gogs / github）、`repo_path`（相对路径）。

**规则**：

1. **URL 直接保存**，不再由 `HAVEN_GOGS_BASE_URL` 拼接；换域名不需要迁移数据。
2. **链接类型由域名推断**（不落库）：`github.com` → github；配置的 Gogs 域名 → gogs；其他 → link。
3. **标题抓取**：新增非仓库链接且 `title` 为空时，后端请求页面解析 `<title>`；超时 5 秒、响应上限 256 KiB、标题截断到 120 字符。抓取失败不影响添加，标题留空。
4. **唯一性**：同一作品下 `url` 唯一。
5. `is_primary` 只对仓库链接有意义，非仓库链接一律 false。

## 三、migration 规划

| 文件 | 内容 |
|---|---|
| `0008_portfolio_content` | `portfolio_items` 加 `content` 列（默认空串） |
| `0009_portfolio_repos_url` | `portfolio_repos` 加 `url`、`title`，删 `platform`、`repo_path` |

- 命名与前几期一致（`000N_描述.up.sql` / `.down.sql`），放 `backend/migrations/`；
- 必须提供 `down`，只回滚本期新增的列；
- **执行 migration 的数据库角色必须是表属主**（同 `v2/backend/data-model.md` 第三节的说明）。
