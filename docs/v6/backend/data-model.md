# data-model — 六期 schema 变更

> 本文件回答：六期对索引做了哪些改动（v1–v5 未覆盖的部分）。
> 依赖：`../../v1/backend/data-model.md`、`../v2/backend/data-model.md`

覆盖规则见 `../../README.md` 第二节。

## 一、notes 表新增索引

**不新增列、不新增表。** 只加一个索引，支撑 `type=title` 的搜索：

```sql
-- 标题的 trigram 索引：命令面板按标题搜时避免全表扫描
CREATE INDEX idx_notes_title_trgm ON notes USING gin (title gin_trgm_ops);
```

**规则**：

1. **只索引标题**：`search_text` 已有的 trigram 索引覆盖「标题 + 正文」，这个索引专门服务「只搜标题」；
2. **索引很小**：只覆盖 `title` 列，通常远小于 `search_text` 的索引；
3. **与 `idx_notes_search_trgm` 并存**：两者服务不同查询，不互相替代。

## 二、migration 规划

| 文件 | 内容 |
|---|---|
| `0010_notes_title_trgm` | `notes.title` 的 GIN trigram 索引 |

- 依赖 `pg_trgm` 扩展，`0001_init` 已创建；
- 必须提供 `down`，只删本期新增的索引；
- **执行 migration 的角色必须是表属主**（同 `v2/backend/data-model.md` 第三节）。
