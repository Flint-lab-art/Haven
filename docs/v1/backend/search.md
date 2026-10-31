# search — 搜索设计

> 本文件回答：搜索怎么实现、匹配什么范围、用什么索引、有哪些已知限制。
> 依赖：data-model.md

接口形态（路径、参数、响应结构）见 `api.md` 第十章；表结构与 `search_text` 生成列见 `data-model.md` 第十节。

## 一、范围

笔记标题、笔记正文、标签名，三处都支持模糊包含查询。

- 笔记标题 + 正文：通过 `notes.search_text` 生成列合并后匹配；
- 标签名：直接匹配 `tags.name`。

## 二、技术方案

`search_text` 是 `title || ' ' || content` 的 STORED 生成列，由数据库自动维护，应用层只读不写。

```sql
-- notes.search_text 的 trigram 索引
CREATE INDEX idx_notes_search_trgm ON notes USING gin (search_text gin_trgm_ops);
```

查询：

```sql
-- 笔记：当前用户范围内匹配
WHERE user_id = $1 AND search_text ILIKE '%关键词%'

-- 标签：当前用户范围内匹配
WHERE user_id = $1 AND name ILIKE '%关键词%'
```

`tags.name` 的 trigram 索引 `idx_tags_name_trgm` 定义在 `data-model.md` 第十一节。

**不安装中文分词扩展**（`zhparser` / `pg_jieba` / `pg_bigm` 等）。1–2 个字的查询会退化为全表扫描，接受这一代价（数据量小，且实际使用中很少只搜一两个字）。

## 三、可见性

搜索同样受授权中间件的可见性过滤约束（见 `auth.md` 6.3）：

- 私有搜索只返回当前用户的笔记与标签；
- 公开搜索只返回 `visibility = 'public' AND published_at IS NOT NULL` 的笔记。

搜索实现不得自行拼 visibility 条件。

## 四、已知限制

本期搜索为子串匹配，只处理“包含”语义：

- 不处理同义词（如“知识中台”搜不到“知识管理平台”）；
- 不处理繁体与简体互通；
- 不纠正错别字。

这是刻意的取舍：自用场景、数据量小，子串匹配足够日常检索；语义检索与分词留到第二版评估（LLM 侧的落点见 `llm-extension.md`）。

## 五、返回

- 笔记搜索结果返回笔记列表，同时返回每篇笔记的标签（联查 `note_tags` + `tags`）；
- 标签搜索结果返回标签列表，点进去看该标签下的笔记；
- 搜索结果不返回正文，只返回标题、`content_preview` 与元信息。

具体结构见 `api.md` 第十章的 10.1 与 10.2。
