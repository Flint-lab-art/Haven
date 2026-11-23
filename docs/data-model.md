# 数据模型

数据库：PostgreSQL，迁移由 Flyway 管理（`backend/src/main/resources/db/migration/`）。

## 1. 迁移清单

| 版本 | 文件 | 内容 |
| --- | --- | --- |
| V1 | `init.sql` | 建表：users、sa_token、pending_totp、tokens、audit_events、folders、notes、tags、note_tags、note_versions、issues、issue_status_events、portfolio_items、portfolio_repos（作品集两表已在 V14 删除） |
| V2 | `trusted_devices.sql` | 授信设备表 |
| V3 | `del_issues_parentId.sql` | 删除 issues.parent_id |
| V4 | `add_ledger_tables.sql` | 记账三表 |
| V5 | `ledger_default_aliases.sql` | 支出默认别名（仅开发账号 `kairo`） |
| V6 | `ledger_income_categories.sql` | 收入分类加入白名单 |
| V7 | `folders_parent_on_delete_set_null.sql` | 文件夹父引用改为 `ON DELETE SET NULL` |
| V8 | `note_versions_merge_window.sql` | 版本表加 `updated_at` / `window_started_at` |
| V9 | `portfolio_items_is_public.sql` | （历史）作品集加 `is_public`；表已在 V14 删除 |
| V10 | `ledger_repayment_category.sql` | 支出新增「还款」分类 + 默认别名 |
| V11 | `ledger_user_foreign_keys.sql` | 记账三表补 `user_id` 外键 |
| V12 | `ledger_token_category.sql` | 支出新增「Token」分类 |
| V13 | `ledger_subscription_category.sql` | 支出新增「订阅」分类 |
| V14 | `remove_public_notes_and_portfolio.sql` | 删作品集两表、`idx_notes_public`、`notes.visibility` / `published_at` |
| V15 | `login_logs.sql` | 登录日志表（独立于 `audit_events`） |
| V16 | `split_module_schemas.sql` | 按模块拆分 schema：`note` / `issue` / `ledger`，`public` 只留公共表 |
| V17 | `ledger_accounts_categories_budget.sql` | 记账重构：账户、两级分类、预算；重建流水表；删批次 / 别名表 |
| V18 | `ledger_category_seed.sql` | 分类种子：7 支出 + 1 收入一级，44 条二级 |

### 迁移规则

- **已执行的迁移永不修改**，修正一律新增版本。
- 迁移必须能在**空库**上从头跑通（测试每次都在临时 schema 里完整执行一遍）。
- 改表所属 schema 用 `ALTER TABLE ... SET SCHEMA`，不要 `DROP` + `CREATE`，否则丢数据。
- 只用 Flyway 管理事务，脚本里不要写 `BEGIN/COMMIT`。
- 命名：`V<n>__<snake_case_description>.sql`（V3 的 `del_issues_parentId` 是历史遗留，不追改）。

## 2. schema 分层

V16 之前所有表都平铺在 `public`，表一多就难以分辨归属。V16 起按模块拆分：

| schema | 表 | 说明 |
| --- | --- | --- |
| `public` | `users`、`tokens`、`sa_token`、`pending_totp`、`trusted_devices`、`audit_events`、`login_logs` | 用户与认证，跨模块共用 |
| `note` | `notes`、`folders`、`tags`、`note_tags`、`note_versions` | 笔记模块独占 |
| `issue` | `issues`、`issue_status_events` | Issue 模块独占 |
| `ledger` | `ledger_entries`、`ledger_accounts`、`ledger_categories`、`ledger_budgets` | 记账模块独占 |

约定：

- **entity 的 `@TableName` 必须带 schema 前缀**（如 `@TableName("note.notes")`），Mapper 里手写的 SQL 同理。
- 外键跨 schema 由 PostgreSQL 原生支持，模块表指向 `users` 的外键不需要重建。
- 索引与约束随表移动（它们是表的从属对象）。
- `sa_token` 的序列 `sa_token_id_seq` 留在 `public`。
- 测试用 `search_path=<临时schema>,public` 隔离，**注意 schema 不能嵌套**：临时 schema 内再建 `note` 会落到库顶层，所以测试隔离与模块 schema 共用同一个库时需要留意。

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

笔记没有可见性概念：所有笔记都只属于当前用户，没有"发布"这一步。
早期版本有 `visibility` / `published_at` 和 `idx_notes_public` 部分索引，供公开站点读取已发布笔记；V14 已一并删除，
`GET /api/notes` 也不再接受 `visibility` 参数（签名是 `listNotes(userId, limit, offset, tagId, folderId, includeTrash)`）。

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

### audit_events

```sql
id, actor_user_id, actor_username, event_type, target_type, target_id,
metadata jsonb, ip, user_agent, created_at
```

`event_type` / `target_type` 都有 CHECK 约束，取值见 `audit/AuditEventType` 与 `AuditTargetType`。
只记录**非登录类**安全事件（TOTP、改密、Token、授信设备、会话吊销）；登录成功 / 失败 / 登出见下方 `login_logs`。
CHECK 里仍保留 `login_*`、`note_published` 等历史取值（迁移不可改），但枚举与写入方已不再产生它们。

### login_logs

```sql
id             uuid primary key default gen_random_uuid()
user_id        uuid references users (id) on delete set null   -- 用户名输错时为 null
username       text not null default ''                        -- 快照，账号删除后仍可追溯
event_type     text not null check (event_type in (
                 'login_success','login_failure','totp_failure','logout'))
method         text not null default ''    -- password / totp / session
success        boolean not null
failure_reason text                        -- unknown_user / bad_password / bad_code / expired / too_many_attempts
ip             text not null default ''
user_agent     text not null default ''
session_hash   text                        -- 会话 Token 的 SHA-256；失败事件为 null
metadata       jsonb not null default '{}'
created_at     timestamptz not null default now()

create index idx_login_logs_user       on login_logs (user_id, created_at desc);
create index idx_login_logs_username   on login_logs (lower(username), created_at desc);
create index idx_login_logs_created_at on login_logs (created_at desc);
```

**为什么和 `audit_events` 分开**：

- 登录事件写入频率最高，字段形态固定（事件类型 + 失败原因 + 设备），和审计事件的"谁改了什么对象"不是一种东西。
- 失败日志必须在登录事务回滚后**依然保留**，靠 `LoginLogRecorder` 的 `REQUIRES_NEW` 独立事务写入（见 [auth.md](auth.md#6-审计)）。
- `user_id` 用 `ON DELETE SET NULL` 而不是 cascade：删账号不该顺手抹掉"这个 IP 一直在猜密码"的痕迹。
- 用户名输错时 `user_id` 为空，查询接口按 `lower(username)` 兜底匹配，所以自己的登录失败也看得到。

**不自动清理**：这张表只会增长，刻意没有定时 purge——登录历史是排查"谁动了我的账号"的唯一线索。
真要清理请手工按 `created_at` 删，且至少保留 90 天。

`session_hash` 只落库不返回：接口 `GET /api/auth/login-logs` 永不输出该字段。

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

其他表（ledger、issues、login_logs）是硬删除。

## 6. 外键与级联

| 表 | 外键 | 级联 |
| --- | --- | --- |
| `notes.user_id` | → users | cascade |
| `folders.user_id` | → users | cascade |
| `folders.parent_id` | → folders | **set null** |
| `notes.folder_id` | → folders | （无外键，删除时手动迁移到回收站） |
| `note_versions.note_id` | → notes | cascade |
| `audit_events.actor_user_id` | → users | set null（保留审计） |
| `login_logs.user_id` | → users | set null（保留登录历史） |
| `ledger_batches` / `ledger_entries` / `ledger_aliases` 的 `user_id` | → users | cascade |

记账三表的外键是 V11 补的：V4 建表时只写了 `user_id uuid not null`，删用户会留下孤儿账目。
`ledger_entries` 另有 `(user_id, batch_id) → ledger_batches` 的复合外键，保证明细能追溯到批次。

## 7. 索引策略

| 场景 | 索引 |
| --- | --- |
| 按用户列列表 | `(user_id, updated_at desc)` 等复合索引，避免回表 |
| 模糊搜索 | `pg_trgm` GIN 索引（`search_text`、`title`、`tags.name`） |
| 登录历史 | `(user_id, created_at desc)` 与 `(lower(username), created_at desc)`，覆盖"我的日志"与"同名失败尝试"两种查询 |
| 幂等键 | `ledger_batches` 主键 `(user_id, batch_id)` |

> `ledger_entries` 的 `(user_id, batch_id)` 是**普通索引**不是唯一索引。
> 批次级幂等靠 `ledger_batches` 主键保证，条目表本身不阻止同批次重复，
> 因为写入前已经用 `insertIfAbsent` 挡住了重放。

## 8. 数据库扩展

`V1` 里 `create extension if not exists pg_trgm`，需要数据库账号有建扩展权限（托管 PG 常限制）。

测试环境处理方式见 [testing.md](testing.md#pg_trgm-的坑)：
扩展装在 `public`，临时 schema 的 `search_path` 必须包含 `public`。
