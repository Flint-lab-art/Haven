# 数据模型

数据库：PostgreSQL，迁移由 Flyway 管理（`backend/src/main/resources/db/migration/`）。

## 1. 迁移清单

| 版本 | 文件 | 内容 |
| --- | --- | --- |
| V1 | `init.sql` | 建表：users、sa_token、pending_totp、tokens、audit_events、folders、notes、tags、note_tags、note_versions、issues、issue_status_events、portfolio_items、portfolio_repos |
| V2 | `trusted_devices.sql` | 授信设备表 |
| V3 | `del_issues_parentId.sql` | 删除 issues.parent_id |
| V4 | `add_ledger_tables.sql` | 记账三表 |
| V5 | `ledger_default_aliases.sql` | 支出默认别名（仅开发账号 `kairo`） |
| V6 | `ledger_income_categories.sql` | 收入分类加入白名单 |
| V7 | `folders_parent_on_delete_set_null.sql` | 文件夹父引用改为 `ON DELETE SET NULL` |
| V8 | `note_versions_merge_window.sql` | 版本表加 `updated_at` / `window_started_at` |
| V9 | `portfolio_items_is_public.sql` | 作品集加 `is_public`（默认 false） |
| V10 | `ledger_repayment_category.sql` | 支出新增「还款」分类 + 默认别名 |

### 迁移规则

- **已执行的迁移永不修改**，修正一律新增版本。
- 迁移必须能在**空库**上从头跑通（测试每次都在临时 schema 里完整执行一遍）。
- 只用 Flyway 管理事务，脚本里不要写 `BEGIN/COMMIT`。
- 命名：`V<n>__<snake_case_description>.sql`（V3 的 `del_issues_parentId` 是历史遗留，不追改）。

## 2. 核心表

### users

```sql
id            uuid primary key
username      text not null
password_hash text not null          -- BCrypt cost=12
totp_secret   text                   -- Base32；启用后才有值
totp_enabled  boolean not null default false
created_at / updated_at timestamptz

create unique index idx_users_username_lower on users (lower(username));
```

用户名唯一性用 **小写索引**，因此 `Kairo` 与 `kairo` 是同一个账号。

### notes

```sql
id            uuid primary key
user_id       uuid not null references users on delete cascade
folder_id     uuid          -- 指向 folders
title         text not null
content       text
visibility    text not null            -- 'private' | 'public'
published_at  timestamptz              -- 发布后才有值
search_text   text                     -- 去标签后的正文，供 GIN 索引
sort_order    int
deleted_at    timestamptz              -- 软删除
created_at / updated_at
```

索引：

```sql
create index idx_notes_search_trgm on notes using gin (search_text gin_trgm_ops);
create index idx_notes_title_trgm  on notes using gin (title gin_trgm_ops);
create index idx_notes_updated_at  on notes (user_id, updated_at desc);
```

### note_versions

```sql
id                uuid primary key
note_id           uuid not null references notes on delete cascade
user_id           uuid not null references users on delete cascade
title / content / folder_id / tag_ids uuid[]
created_at        timestamptz not null   -- 不可变
updated_at        timestamptz            -- 窗口内合并时更新
window_started_at timestamptz            -- 合并窗口的固定锚点
```

### folders

```sql
id         uuid primary key
user_id    uuid not null references users on delete cascade
parent_id  uuid references folders (id) on delete set null
name       text not null
is_inbox   boolean not null default false
sort_order int
```

**`parent_id` 必须是 `ON DELETE SET NULL`，不能是 `CASCADE`**：曾经的 CASCADE 会在跨用户引用时
把别人的子树一起删掉。同用户子树的级联删除由 `FoldersServiceImpl.cascadeDelete` 按 `user_id` 显式处理。

### ledger_entries

```sql
id           uuid primary key
user_id      uuid not null
type         varchar(16) not null check (type in ('expense','income'))
amount_cents bigint not null check (amount_cents > 0)
category     varchar(32) not null check (category in (...))
note         text
occurred_at  timestamptz not null
batch_id     varchar(64) not null
created_at   timestamptz not null
```

### portfolio_items

```sql
id / user_id / title / description / content / sort_order / created_at
is_public boolean not null default false   -- V9 新增，匿名接口只返回 true
```

**默认 `false`**：公开作品集页需要作者主动勾选才展示。

### audit_events

```sql
id, actor_user_id, actor_username, event_type, target_type, target_id,
metadata jsonb, ip, user_agent, created_at
```

`event_type` / `target_type` 都有 CHECK 约束，取值见 `audit/AuditEventType` 与 `AuditTargetType`。

## 3. 金额

### 存整数分，不存小数

```sql
amount_cents bigint not null check (amount_cents > 0)
```

理由：

| 方案 | 问题 |
| --- | --- |
| `float8` / `double` | 二进制表示小数有误差，累计后账对不上 |
| `numeric(12,2)` | 精确但运算慢；本项目只需加减与分组求和 |
| **`bigint` 分** | 精确、快、无歧义（Stripe / 支付宝 / 微信支付都用这个） |

`bigint` 上限约 922 万亿分，个人记账绰绰有余；`int4` 只有约 2147 万分（21 万元），不能用。

### 转换必须严格

```java
// LedgerTextParser.toCents
value.movePointRight(2).setScale(0, RoundingMode.UNNECESSARY).longValueExact()
```

- `UNNECESSARY`：出现第三位小数直接抛异常，不静默截断
- `longValueExact`：溢出抛异常，不回绕

### 约束有测试守着

`LedgerConstraintTest` 断言了：

- `0` / 负数被拒绝
- `1` 分是最小合法值
- 1 亿分（100 万元）写入后原值读回
- 列类型是 `bigint`（防止有人改成浮点）
- 分类白名单与 `LedgerCategories.ALL` 一致

### 当前不做的

| 项 | 原因 |
| --- | --- |
| `currency` 字段 | 单用户单币种，加了就是永远等于 `'CNY'` 的死字段 |
| `numeric` 视图 | 没有 BI / 报表消费方，加了没人用 |
| 允许 `amount_cents = 0` | 个人记账里 0 元不是一笔支出，`> 0` 恰好挡住脏数据 |

## 4. 时间

- 所有时间用 `timestamptz`（带时区），不用 `timestamp`。
- 业务代码一律 `OffsetDateTime.now(clock)`，禁止直接 `now()`。
- 业务时区由 `haven.time-zone` 决定，默认取 JVM 时区。

### 为什么版本表要 `window_started_at`

编辑笔记时，5 分钟内的多次保存合并成一个版本。最初的实现用 `created_at` 判断窗口，
但合并时又把 `created_at` 刷新成当前时间——**窗口永远滑动**，只要持续编辑，历史版本就永不归档。

现在：

- `created_at` 创建后不可变
- `window_started_at` 是窗口起点，合并时不动
- `updated_at` 记录最近一次合并写入

## 5. 软删除

`notes` 用 `deleted_at` 软删除：

- 列表默认过滤 `deleted_at is null`
- 回收站查询 `is not null`
- 永久删除（purge）才真正 `delete`

其他表（ledger、issues、portfolio）是硬删除。

## 6. 外键与级联

| 表 | 外键 | 级联 |
| --- | --- | --- |
| `notes.user_id` | → users | cascade |
| `folders.user_id` | → users | cascade |
| `folders.parent_id` | → folders | **set null** |
| `notes.folder_id` | → folders | （无外键，删除时手动迁移到回收站） |
| `note_versions.note_id` | → notes | cascade |
| `audit_events.actor_user_id` | → users | set null（保留审计） |
| `ledger_*` | 无外键 | 见下方已知问题 |

### 已知问题

`ledger_batches` / `ledger_entries` / `ledger_aliases` 的 `user_id` **没有外键**，
删除用户后会留下孤儿数据。修法：新增迁移补 `references users(id) on delete cascade`（先清理孤儿行）。

## 7. 索引策略

| 场景 | 索引 |
| --- | --- |
| 按用户列列表 | `(user_id, updated_at desc)` 等复合索引，避免回表 |
| 模糊搜索 | `pg_trgm` GIN 索引（`search_text`、`title`、`tags.name`） |
| 部分索引 | 公开笔记 `(user_id, published_at desc) where visibility='public'` |
| 幂等键 | `ledger_batches` 主键 `(user_id, batch_id)` |

> `ledger_entries` 的 `(user_id, batch_id)` 是**普通索引**不是唯一索引。
> 批次级幂等靠 `ledger_batches` 主键保证，条目表本身不阻止同批次重复，
> 因为写入前已经用 `insertIfAbsent` 挡住了重放。

## 8. 数据库扩展

`V1` 里 `create extension if not exists pg_trgm`，需要数据库账号有建扩展权限（托管 PG 常限制）。

测试环境处理方式见 [testing.md](testing.md#pg_trgm-的坑)：
扩展装在 `public`，临时 schema 的 `search_path` 必须包含 `public`。
