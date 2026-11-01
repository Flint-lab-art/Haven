# api — 六期搜索参数

> 本文件回答：命令面板所需的标题搜索怎么调（v1–v5 未覆盖的部分）。
> 依赖：`../v1/api.md`、`../v5/api.md`

覆盖规则见 `../README.md` 第二节。通用约定沿用 `v1/api.md` 第一章。

## 一、GET `/api/search` 新增 `type` 参数

**本节扩展 v1 `api.md` 10.1，其余字段与响应结构不变。**

**查询参数**（新增项）：

| 参数 | 取值 | 默认 | 说明 |
|---|---|---|---|
| `type` | `title` / `title_content` | `title_content` | 匹配范围 |

**各取值的行为**：

| `type` | 匹配条件 | 用途 |
|---|---|---|
| `title_content`（默认） | `search_text ILIKE '%q%'`（标题 + 正文的生成列） | 搜索页，行为与 v1 一致 |
| `title` | `title ILIKE '%q%'` | 命令面板，只找标题 |

**规则**：

- **不传 `type` 等同于 `title_content`**，搜索页不受影响；
- 非法 `type` 返回 `422 validation_failed`，`fields.type` 说明原因；
- **不提供 `content` 单值**：没有「只搜正文」的场景，且 `content` 无索引会全表扫描；
- `q` 仍然必填、仍然转义 `%` `_` `\`（`search.escapeLike`）；
- 标签搜索**不受 `type` 影响**：无论哪种 `type`，标签一律按 `name ILIKE` 匹配。

**响应**：不变，仍是 `{notes: {items, total}, tags: {items, total}}`。

**备注**：命令面板只用 `notes` 部分，忽略 `tags`。

## 二、索引要求

`type=title` 依赖 `notes.title` 上的 trigram 索引，见 `backend/data-model.md` 第一节。没有索引时该分支会全表扫描。

## 三、不做的事

- 不做 `type=content`；
- 不做按文件夹 / 标签 / 时间的组合筛选；
- 不做搜索结果排序权重（仍按 `updated_at DESC`）。
