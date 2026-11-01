# api — 五期统计接口

> 本文件回答：首页所需的统计数据怎么取、返回什么结构（v1–v4 未覆盖的部分）。
> 依赖：`../v1/api.md`、`../v2/api.md`

覆盖规则见 `../README.md` 第二节。通用约定（错误响应、鉴权标注）沿用 `v1/api.md` 第一章。

## 一、GET `/api/stats`

**鉴权**：登录（`read` Token 亦可）

**说明**：一次返回首页需要的全部统计数据。走 SQL 聚合，不让前端拉全量笔记自行计算。

**查询参数**：无。

**响应** `200`：

```json
{
  "totals": {
    "notes": 128,
    "words": 42310,
    "public_notes": 12
  },
  "week": {
    "created": 5,
    "updated": 9
  },
  "heatmap": [
    { "date": "2026-05-01", "count": 2 },
    { "date": "2026-05-02", "count": 0 }
  ],
  "recent": [
    {
      "id": "uuid",
      "title": "某篇笔记",
      "updated_at": "2026-11-01T09:12:00Z",
      "visibility": "private"
    }
  ]
}
```

### 1.1 各字段口径

| 字段 | 含义 | SQL 口径 |
|---|---|---|
| `totals.notes` | 笔记总数 | `count(*)` where `deleted_at IS NULL` |
| `totals.words` | 总字数（按字符计） | `sum(length(content))` 同上 |
| `totals.public_notes` | 公开笔记数 | 追加 `visibility = 'public' AND published_at IS NOT NULL` |
| `week.created` | 本周新建 | `created_at` 在最近 7 天内 |
| `week.updated` | 本周编辑过 | `updated_at` 在最近 7 天内 |
| `heatmap` | 近三个月每天的编辑次数 | 按 `updated_at::date` 分组，**补零**到完整日期序列 |
| `recent` | 最近编辑的 5 篇 | 按 `updated_at DESC`，只返回摘要字段 |

**通用规则**：

- **只统计当前用户**：全部查询带 `user_id = $1`；
- **排除回收站**：全部查询带 `deleted_at IS NULL`；
- **字数按字符**：`length(content)` 是 PostgreSQL 的字符数（不是字节），中文按 1 个计；
- **不含标题**：`totals.words` 只算正文，标题不计入。

### 1.2 热力图

- **范围**：从「三个月前的今天」到「今天」，共 91 天（`stats.HeatmapDays`）；
- **补零**：没有编辑的日期也返回 `count: 0`，前端无需自己补；
- **范围是代码常量**：早期数据稀疏，半年的格子图大部分是空的，因此先取 91 天；改范围只改常量；
- **按天聚合**：`updated_at` 按服务器时区转换成日期；
- **统计的是「编辑过」**：一天内编辑同一篇多次只算 1 次（`count(distinct id)` 按天分组）。

### 1.3 最近编辑

- 固定返回 **5 条**，不支持分页参数；
- 字段只含摘要（`id` / `title` / `updated_at` / `visibility`），不含正文。

## 二、不做的事

- 不做按标签 / 文件夹的统计；
- 不做写作目标与完成度；
- 不做历史趋势对比（同比、环比）；
- 不做导出的统计报表。
