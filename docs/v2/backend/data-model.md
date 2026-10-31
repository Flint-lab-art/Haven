# data-model — 二期 schema 变更

> 本文件回答：二期对数据库表结构做了哪些改动（v1 未覆盖的部分）。
> 依赖：`../../v1/backend/data-model.md`

覆盖规则见 `../../README.md` 第二节：本文件中出现的节替换 v1 同名节；v1 中未出现的表结构继续有效。

## 一、notes 表变更

在 v1 `notes` 表基础上**只新增一列**，其余字段、约束、索引不变。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `deleted_at` | timestamptz | NULL | NULL | 非 NULL 表示已移入回收站；值为删除时间 |

**新增索引**：

```sql
-- 回收站列表：按删除时间倒序
CREATE INDEX idx_notes_deleted ON notes (user_id, deleted_at DESC)
    WHERE deleted_at IS NOT NULL;
```

**规则**：

1. **软删除**：删除笔记只写 `deleted_at`，不删行，也不清空 `folder_id`——`folder_id` 就是“原位置”。
2. **原位置失效**：`notes.folder_id` 外键为 `ON DELETE SET NULL`，原文件夹被删除后该列自动置空，还原时归入收件箱。
3. **可见性**：所有读路径都必须排除 `deleted_at IS NOT NULL` 的行。这一条件统一写进 `auth.VisibilityPublic` 与 `auth.VisibilityOwnedOrPublic` 常量，不在各 handler 里自行拼接。
4. **永久删除**：`purge` 才真正 `DELETE`，此时 `note_versions` 由外键级联清理。

## 二、note_versions — 历史版本

**用途**：保存笔记在每次实质性编辑之前的内容快照，用于在编辑页回看与还原。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `note_id` | uuid | NOT NULL, FK → notes(id) ON DELETE CASCADE | — | 所属笔记 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户，用于权限过滤与索引 |
| `title` | text | NOT NULL | — | 快照时的标题 |
| `content` | text | NOT NULL | `''` | 快照时的正文（Markdown 源文本） |
| `folder_id` | uuid | NULL | NULL | 快照时的文件夹；NULL 表示当时无归属 |
| `tag_ids` | uuid[] | NOT NULL | `'{}'` | 快照时的标签 id 数组 |
| `created_at` | timestamptz | NOT NULL | `now()` | 快照时间 |

**索引**：

```sql
CREATE INDEX idx_note_versions_note ON note_versions (note_id, created_at DESC);
```

**规则**：

1. **写入时机**：在 `notes.Update` 事务内、执行更新**之前**，把当前值写入快照。只更新 `sort_order` 时不写。
2. **写入条件**：只有 `title` / `content` / `folder_id` / `tag_ids` 中至少一项真的变化时才写。编辑器自动保存会频繁调用 `PATCH`，内容没变时不产生快照。
3. **合并**：同一笔记 5 分钟内只保留一条——若该笔记最新一条快照的 `created_at` 在 5 分钟以内，则**不新增**，直接沿用最早的那条快照。
4. **`tag_ids` 用数组**：不另建关联表。标签被物理删除后，快照数组里可能残留已不存在的 id，还原时跳过不存在的 id（不报错）。
5. **不感知回收站**：笔记进入回收站后不再产生快照；历史版本接口对被删除的笔记返回 404。
6. **归属校验**：查询与还原都必须带 `note_id = ? AND user_id = ?`，跨用户访问返回 404。

## 三、migration 规划

| 文件 | 内容 |
|---|---|
| `0006_notes_recycle_bin` | `notes` 加 `deleted_at` + `idx_notes_deleted` |
| `0007_note_versions` | 新建 `note_versions` 表 + 索引 |

- 命名与 v1 一致（`000N_描述.up.sql` / `.down.sql`），放 `backend/migrations/`；
- 后端启动不跑 migration，仍需显式执行；
- 两个 migration 都必须提供 `down`，且 `down` 只回滚自己新增的东西。
