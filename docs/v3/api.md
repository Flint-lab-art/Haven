# api — 三期接口变更

> 本文件回答：三期新增与变更的接口契约（v1/v2 未覆盖的部分）。
> 依赖：`../v1/api.md`、`../v2/api.md`、`backend/data-model.md`

覆盖规则见 `../README.md` 第二节。通用约定（分页、错误响应、鉴权标注含义、`PATCH` 语义）沿用 `v1/api.md` 第一章，本文件不重复。

> 注：三期最初规划「不改后端」。实现作品详情时发现作品集只有 `title` + `description`，没有可展示的介绍正文，因此本期增加 `content` 字段与一个公开详情接口。这是对原计划的扩展，已登记在 `changes.md`。

## 一、portfolio_items 新增字段

`portfolio_items` 增加 `content`（Markdown 源文本，默认空串），表结构见 `backend/data-model.md` 第一节。

### 1.1 涉及接口

| 接口 | 变更 |
|---|---|
| `POST /api/portfolio` | 请求可带 `content`（可选，默认空串） |
| `PATCH /api/portfolio/:id` | 请求可带 `content`（部分更新，不传则不变） |
| `GET /api/public/portfolio` | **不返回** `content`，避免列表带上大段正文 |
| `GET /api/portfolio/:id` | **新增**，私有域作品详情，返回含 `content` 的完整作品 |
| `GET /api/public/portfolio/:id` | **新增**，公开作品详情，返回含 `content` 的完整作品 |

已有的私有域 CRUD 响应（创建 / 更新）会在 `content` 非空时带回该字段。

### 1.2 GET `/api/portfolio/:id`

**鉴权**：登录（read Token 亦可）

**说明**：私有域作品详情。私有域列表用的是公开列表接口（不含正文），编辑器打开作品时必须单独调本接口取正文，否则保存会把正文覆盖成空串。

**响应** `200`：结构同下方 2.2。

**错误**：

- `404 not_found` — 作品不存在或不属于当前用户。

## 二、公开作品详情

### 2.1 GET `/api/public/portfolio`

**鉴权**：匿名

响应结构不变（`{items, total}`）。列表项**不含** `content`；正文只在详情接口返回。

### 2.2 GET `/api/public/portfolio/:id`

**鉴权**：匿名

**响应** `200`：

```json
{
  "id": "uuid",
  "title": "官网检索器",
  "description": "官网收录检索工具",
  "content": "# 官网检索器\n\n用 Playwright 做官网收录检索。",
  "sort_order": 0,
  "repos": [
    {
      "id": "uuid",
      "platform": "gogs",
      "repo_path": "kairo/site-search",
      "url": "https://gogs.example.com/kairo/site-search",
      "is_primary": true
    }
  ]
}
```

**错误**：

- `404 not_found` — 作品不存在。

**备注**：

- `content` 为空串时响应体省略该字段（`omitempty`），前端按「没有写介绍」处理；
- 该接口只读，不接受任何写操作；
- 与私有域的 `GET /api/portfolio/:id` 区别：公开版不带 `user_id` 过滤，任何已存在的作品都可访问。

## 三、相关链接（替换 v1 第十一节的作品仓库部分）

**本节替换 v1 `api.md` 11.5 / 11.6 中关于 `platform` 与 `repo_path` 的约定。**

### 3.1 POST `/api/portfolio/:id/repos`

**鉴权**：登录 + write

**请求**：

```json
{ "url": "https://github.com/kairo/haven", "title": "", "is_primary": true }
```

- `url`：必填，必须是 `http://` 或 `https://` 开头的完整地址；否则 `422 validation_failed`，`fields.url` 给出原因；
- `title`：可选。**非仓库链接留空时，后端会尝试抓取页面标题**并按需截断到 120 字符；抓取失败则留空；
- `is_primary`：可选，默认 false。

**响应** `201`：

```json
{
  "id": "uuid",
  "url": "https://github.com/kairo/haven",
  "title": "",
  "kind": "github",
  "is_primary": true
}
```

`kind` 是按 URL 域名推断的只读字段：`github` / `gogs` / `link`。

**错误**：

- `409 conflict` — 同一作品下已存在相同 `url`，或已有主链接；
- `422 validation_failed` — `url` 不是合法的完整地址。

### 3.2 PATCH `/api/portfolio/:id/repos/:repoId`

**请求**（部分更新）：

```json
{ "url": "https://example.com/new", "title": "新标题", "is_primary": false }
```

- `url` 如出现，同样要做完整地址校验；
- `title` 如出现，允许留空（公开页会退回显示 URL）。

**响应** `200`：同 3.1。

### 3.3 展示规则（前端契约）

| `kind` | 公开页展示 |
|---|---|
| `github` | GitHub 图标 |
| `gogs` | Gogs 图标 |
| `link` | `title`（为空时退回 `url`），**不展示 URL** |

## 四、标签列表顺带清理空标签

**`GET /api/tags` 在执行查询前，会先删除当前用户下没有任何有效引用的标签。**

- **有效引用**指 `deleted_at IS NULL` 的笔记：回收站里的笔记不算引用，与列表里 `note_count` 的口径一致；
- 这样接口永远不会返回 `note_count = 0` 的标签；
- 属于「读接口带写副作用」的取舍：项目单用户、数据量小，这样做最简单，也不需要引入定时任务。

## 五、不做的事

- 不提供公开的作品列表筛选、搜索；
- 不提供作品正文的版本历史（版本历史只服务笔记，见 v2）；
- 不自动抓取仓库 README：正文由使用者在私有域手动填写；
- 不缓存或定时刷新链接标题：只在新增时抓取一次，之后由使用者手动修改。
