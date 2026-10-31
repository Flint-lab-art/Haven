# data-model — 数据库 schema

> 本文件回答：数据库有哪些表、每张表有哪些字段、约束、索引与业务规则。
> 依赖：无

**本文件是全部数据库表结构的唯一出处。** `auth.md`、`audit.md`、`search.md` 等文件需要表结构时一律引用本文件，不重复定义。

## 一、书写约定

每张表统一按四部分书写：用途、字段表、索引、规则。

全局约定：

- 主键统一用 `uuid`，默认 `gen_random_uuid()`。需要 PostgreSQL 13+，或启用 `pgcrypto` 扩展。
- 时间字段统一用 `timestamptz`。
- 命名统一 `snake_case`。
- 枚举值用 `text + CHECK`，不用 PostgreSQL 原生 enum（便于后续加值不改类型）。
- 本期所有删除为硬删除，不做软删除。如需软删除，先改本文件再实现。
- 搜索依赖 `pg_trgm` 扩展，数据库初始化时必须执行 `CREATE EXTENSION IF NOT EXISTS pg_trgm;`。索引与查询写法见 `search.md`。
- 不安装任何中文分词扩展（`zhparser` / `pg_jieba` / `pg_bigm` 等）。理由见 `search.md`。
- **所有业务数据表都带 `user_id` 归属字段**，即使本期单人自用。这是技术预留：注册功能本期不实现，`users` 表只放唯一账号，但数据模型从第一天就按“未来可能有第二个账号”设计，避免以后改表。

**依赖顺序**（migration 按此顺序创建）：

1. `users`
2. `sessions` / `pending_logins` / `trusted_devices` / `tokens` / `audit_events`
3. `folders`（依赖 `users`，通过 `parent_id` 自引用）
4. `notes` / `tags` / `portfolio_items`（`notes` 依赖 `folders`）
5. `note_tags` / `portfolio_repos`

## 二、枚举值汇总

各表小节引用此处，不重复定义。

| 枚举名 | 取值 | 说明 |
|---|---|---|
| `note_visibility` | `private` / `public` | 笔记可见性 |
| `token_scope` | `read` / `read_write` | API Token 权限档位 |
| `repo_platform` | `gogs` / `github` | 作品集仓库托管平台 |
| `audit_event_type` | 见 `audit.md` 第三节 | 审计事件类型 |
| `audit_target_type` | `null` / `user` / `session` / `trusted_device` / `token` / `note` | 审计对象类型 |

## 三、users — 用户账号

**用途**：账号本身。本期只有一个账号，不提供注册。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `username` | text | NOT NULL（唯一性见规则 3） | — | 登录名 |
| `password_hash` | text | NOT NULL | — | bcrypt 哈希（见 `auth.md` 8.1） |
| `totp_secret` | text | NULL | NULL | TOTP 密钥，未绑定为 NULL（存储方式见 `auth.md` 8.2） |
| `totp_enabled` | boolean | NOT NULL | `false` | 是否已启用 TOTP |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |
| `updated_at` | timestamptz | NOT NULL | `now()` | 更新时间 |

**索引**：

```sql
-- username 不区分大小写唯一
CREATE UNIQUE INDEX idx_users_username_lower ON users (lower(username));
```

**规则**：

1. 本期只有一条记录，由部署时的初始化脚本创建（`cmd/haven-init-user`，见 `architecture.md`）。
2. **不提供注册接口**。第二个账号如需创建，只能通过命令行脚本或直接操作数据库，不在 API 层暴露。
3. `username` 不区分大小写唯一：`Admin` 与 `admin` 视为同一个，避免登录时混淆。

## 四、sessions — 正式登录会话

**用途**：维护“已登录”状态，是最短命的凭证。授权规则见 `auth.md` 第三节。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `token_hash` | text | NOT NULL, UNIQUE | — | 会话 token 的 SHA-256 哈希，明文只存在于 cookie |
| `expires_at` | timestamptz | NOT NULL | — | 过期时间，默认创建后 7 天 |
| `last_used_at` | timestamptz | NOT NULL | — | 最后使用时间，每次请求更新 |
| `user_agent` | text | NOT NULL | `''` | 创建会话时的 UA，仅用于设置页展示 |
| `created_at` | timestamptz | NOT NULL | — | 创建时间 |

**索引**：

```sql
CREATE UNIQUE INDEX idx_sessions_token_hash ON sessions (token_hash);
CREATE INDEX idx_sessions_user ON sessions (user_id, created_at DESC);
```

**规则**：见 `auth.md` 第三节。本表只存正式会话；待验证的登录在 `pending_logins`。

## 五、pending_logins — 待验证登录

**用途**：暂存“账密已通过、TOTP 待验证”的登录请求。规则见 `auth.md` 3.1。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `token_hash` | text | NOT NULL, UNIQUE | — | 临时 token 的 SHA-256 哈希 |
| `expires_at` | timestamptz | NOT NULL | — | 创建后 5 分钟 |
| `created_at` | timestamptz | NOT NULL | — | 创建时间 |

**索引**：

```sql
CREATE UNIQUE INDEX idx_pending_logins_token_hash ON pending_logins (token_hash);
CREATE INDEX idx_pending_logins_expires_at ON pending_logins (expires_at);
```

## 六、trusted_devices — 授信设备

**用途**：标记“这台浏览器可信”，用于跳过 TOTP。规则见 `auth.md` 第四节。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `token_hash` | text | NOT NULL, UNIQUE | — | 设备 token 的 SHA-256 哈希 |
| `device_name` | text | NOT NULL | `''` | 用户可命名，如“家里台式机” |
| `expires_at` | timestamptz | NOT NULL | — | 默认 30 天 |
| `last_used_at` | timestamptz | NOT NULL | — | 最后使用时间 |
| `created_at` | timestamptz | NOT NULL | — | 创建时间 |

**索引**：

```sql
CREATE UNIQUE INDEX idx_trusted_devices_token_hash ON trusted_devices (token_hash);
CREATE INDEX idx_trusted_devices_user ON trusted_devices (user_id, created_at DESC);
```

## 七、tokens — API Token

**用途**：供 TUI / Neovim / 脚本长期使用的凭证。规则见 `auth.md` 第五节。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `name` | text | NOT NULL | — | 用户命名，如“TUI @ 家里” |
| `token_hash` | text | NOT NULL, UNIQUE | — | Token 的 SHA-256 哈希 |
| `token_prefix` | text | NOT NULL | — | 明文前 8 位，用于设置页展示与识别，不用于鉴权 |
| `scope` | text | NOT NULL, CHECK (`token_scope`) | — | 权限档位 |
| `expires_at` | timestamptz | NULL | NULL | NULL 表示永不过期 |
| `last_used_at` | timestamptz | NULL | NULL | 从未使用时为 NULL |
| `revoked_at` | timestamptz | NULL | NULL | 非 NULL 表示已撤销 |
| `created_at` | timestamptz | NOT NULL | — | 创建时间 |

**索引**：

```sql
CREATE UNIQUE INDEX idx_tokens_token_hash ON tokens (token_hash);
CREATE INDEX idx_tokens_user ON tokens (user_id, created_at DESC);
```

## 八、audit_events — 审计事件

**用途**：只追加的审计记录。事件清单与写入时机见 `audit.md`。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `actor_user_id` | uuid | NULL, FK → users(id) ON DELETE SET NULL | NULL | 事件发起者；未登录事件为 NULL |
| `actor_username` | text | NOT NULL | `''` | 事件发起者用户名快照；用户被删除后仍保留 |
| `event_type` | text | NOT NULL, CHECK (`audit_event_type`) | — | 事件类型 |
| `target_type` | text | NULL, CHECK (`audit_target_type`) | NULL | 被操作对象类型，无对象时为 NULL |
| `target_id` | uuid | NULL | NULL | 被操作对象 id，无对象时为 NULL |
| `metadata` | jsonb | NOT NULL | `'{}'` | 事件附加信息，结构由 event_type 决定 |
| `ip` | text | NOT NULL | `''` | 请求来源 IP，未取到时为空串 |
| `user_agent` | text | NOT NULL | `''` | 请求 UA |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |

**索引**：

```sql
CREATE INDEX idx_audit_events_created_at ON audit_events (created_at DESC);
CREATE INDEX idx_audit_events_event_type ON audit_events (event_type, created_at DESC);
CREATE INDEX idx_audit_events_actor ON audit_events (actor_user_id, created_at DESC)
  WHERE actor_user_id IS NOT NULL;
```

**规则**：见 `audit.md` 第二节。

## 九、folders — 文件夹目录树

**用途**：支持无限嵌套的目录结构，用于整理笔记。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `parent_id` | uuid | NULL, FK → folders(id) ON DELETE CASCADE | NULL | 父文件夹；NULL 表示根目录 |
| `name` | text | NOT NULL | — | 文件夹名称 |
| `sort_order` | int | NOT NULL | `0` | 排序权重，小的在前 |
| `icon` | text | NULL | NULL | 自定义图标（Emoji 或图标名），为空则前端显示默认文件夹图标 |
| `is_inbox` | boolean | NOT NULL | `false` | 是否为收件箱；每个用户最多一个 |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |
| `updated_at` | timestamptz | NOT NULL | `now()` | 更新时间 |

**索引**：

```sql
CREATE INDEX idx_folders_user_parent ON folders (user_id, parent_id);

-- 每个用户最多一个收件箱
CREATE UNIQUE INDEX idx_folders_inbox ON folders (user_id) WHERE is_inbox;
```

**规则**：

1. **无限嵌套**：通过 `parent_id` 实现无限层级。
2. **删除策略**：删除普通文件夹时，先把该文件夹及子文件夹内的所有笔记移到收件箱，再删除文件夹；收件箱不可删除。子文件夹通过 `ON DELETE CASCADE` 清理，笔记绝不级联删除。
3. **命名唯一性**：同一个父目录下，不允许有同名的文件夹（应用层校验）。文件夹名长度上限 32 个 rune（应用层校验，见 `api.md` 7.2）。
4. **收件箱**：每个用户有且只有一个 `is_inbox = true` 的文件夹，`parent_id` 必须为 `NULL`，固定显示在根目录第一位，不参与排序；允许改名和更换图标，不允许删除或移动。
5. **默认归属**：新建笔记未指定 `folder_id` 时归入收件箱。

**迁移**：为每个用户创建或复用收件箱，把 `notes.folder_id IS NULL` 的笔记归入收件箱；此后正常写入不再产生 `NULL`。

## 十、notes — 笔记

**用途**：存储所有笔记内容，私有与公开共用一张表，靠 `visibility` 区分。
`content` 字段内容为 Markdown 源文本，前端负责渲染。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `folder_id` | uuid | NULL, FK → folders(id) ON DELETE SET NULL | NULL | 所属文件夹；正常笔记都归属收件箱，`NULL` 仅作历史兜底 |
| `sort_order` | int | NOT NULL | `0` | 同一文件夹内排序，小的在前 |
| `title` | text | NOT NULL | — | 标题 |
| `content` | text | NOT NULL | `''` | 正文（Markdown 源文本），允许空串 |
| `visibility` | text | NOT NULL, CHECK (`note_visibility`) | `'private'` | 可见性，默认私有 |
| `published_at` | timestamptz | NULL | NULL | 首次公开发布时间，仅 public 时有意义 |
| `search_text` | text | GENERATED ALWAYS AS (`title || ' ' || content`) STORED | — | 搜索用合并字段，数据库自动维护，应用层只读不写 |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |
| `updated_at` | timestamptz | NOT NULL | `now()` | 最后更新时间，由应用层在每次写入时更新；仅调整 `sort_order` 时不更新 |

**索引**：

```sql
-- 公开列表：按用户 + 发布时间倒序
CREATE INDEX idx_notes_public ON notes (user_id, published_at DESC)
  WHERE visibility = 'public' AND published_at IS NOT NULL;

-- 私有工作台：按用户 + 最近更新排序
CREATE INDEX idx_notes_updated_at ON notes (user_id, updated_at DESC);

-- 目录内自定义排序
CREATE INDEX idx_notes_folder_sort ON notes (user_id, folder_id, sort_order);
```

**搜索索引** `idx_notes_search_trgm`（`search_text` 的 trigram GIN 索引）定义在 `search.md`。

**规则**：

1. **新建笔记一律 private**：数据库层 `DEFAULT 'private'` + `NOT NULL` 兜底；创建接口不接受 `visibility` 参数（见 `conventions.md` 第四节）。
2. **公开是显式动作**：`private → public` 通过独立的 publish 操作完成，该操作在 `published_at IS NULL` 时写入当前时间。
3. **撤回不清空 `published_at`**：`public → private` 时 `published_at` 保留，语义为“首次公开发布时间”；再次公开不覆盖。
4. **公开可见的判定条件唯一**：`visibility = 'public' AND published_at IS NOT NULL`。任何公开读路径必须使用此条件，不得只看 `visibility`。
5. **`published_at` 对 private 笔记无意义**：private 笔记不因 `published_at` 是否存在而改变可见性，该字段只服务于公开列表排序与未来 RSS。
6. **`search_text` 由数据库自动维护**：应用层不得在 INSERT / UPDATE 时写入该字段，也不得在 Go 代码中手动拼接。搜索查询统一使用 `search_text`，不直接查 `title` 或 `content`。
7. **搜索结果受可见性约束**：搜索查询同样要经过授权中间件的 visibility 过滤（未登录只能搜到 public 笔记）。过滤规则见 `auth.md` 6.3。
8. **笔记归属唯一用户**：所有笔记读写操作必须以当前登录用户为过滤条件，即 `WHERE user_id = current_user_id`。授权中间件在 visibility 过滤之外，必须叠加用户归属过滤。跨用户访问视为越权，返回 404 而非 403（不泄露笔记存在性）。
9. **文件夹归属**：笔记必须归属某个文件夹；不传 `folder_id` 时归入当前用户的收件箱。`NULL` 仅作为历史数据兜底，正常写入不应产生。
10. **目录内排序**：`sort_order` 只在同一文件夹内生效，小的在前；列表按 `sort_order ASC, updated_at DESC` 排序。允许重复，重复时以 `updated_at DESC` 兜底。新建笔记和移入新文件夹的笔记 `sort_order` 置 `0`，出现在该目录顶部。仅调整 `sort_order` 不更新 `updated_at`。

## 十一、tags — 标签

**用途**：存储所有标签名，标签本身独立于笔记存在（允许创建后暂不关联任何笔记）。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `name` | text | NOT NULL | — | 标签名 |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |

**索引**：

```sql
-- 同一用户下标签名不区分大小写唯一
CREATE UNIQUE INDEX idx_tags_user_name_lower ON tags (user_id, lower(name));

-- 标签名模糊搜索
CREATE INDEX idx_tags_name_trgm ON tags USING gin (name gin_trgm_ops);
```

**规则**：

1. **标签按用户隔离**：不同用户可拥有同名标签，互不影响。唯一性判断范围是 `(user_id, lower(name))`。
2. **标签名不区分大小写**：`Go` 和 `go` 在同一用户下视为同一个标签。写入时应用层可保留原样，但唯一性判断以 `lower(name)` 为准。
3. **不提供重命名接口**：本期标签只能创建和删除。删除标签时，`note_tags` 中的关联由外键 `ON DELETE CASCADE` 自动清理。如需重命名，先改本文件。
4. **标签查询受用户归属约束**：所有标签查询必须加 `WHERE user_id = current_user_id`。

## 十二、note_tags — 笔记与标签关联

**用途**：多对多关联表，一篇笔记可挂多个标签，一个标签可用于多篇笔记。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `note_id` | uuid | NOT NULL, FK → notes(id) ON DELETE CASCADE | — | 笔记 |
| `tag_id` | uuid | NOT NULL, FK → tags(id) ON DELETE CASCADE | — | 标签 |

**主键**：`(note_id, tag_id)` 复合主键，天然防止重复关联。

**索引**：

```sql
-- 复合主键已覆盖 note_id 开头的查询；单独为 tag_id 建索引，支持"按标签查笔记"
CREATE INDEX idx_note_tags_tag_id ON note_tags (tag_id);
```

**规则**：

1. 关联无额外字段，保持最简。
2. 删除笔记或标签时关联自动清理，不在应用层做级联删除。
3. **跨用户关联防护**：`note_tags` 本身没有 `user_id`，用户归属由 `notes.user_id` 和 `tags.user_id` 分别保证。应用层在创建关联时必须校验 `notes.user_id = tags.user_id = current_user_id`，防止把 A 用户的标签挂到 B 用户的笔记上。这一校验在应用层完成，数据库层不强制（可以用触发器强制，但增加复杂度，本期不做）。

## 十三、portfolio_items — 作品集条目

**用途**：主页作品集的条目本体，一个作品可以关联多个仓库链接。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `title` | text | NOT NULL | — | 作品标题 |
| `description` | text | NOT NULL | `''` | 简介 |
| `sort_order` | int | NOT NULL | `0` | 主页排序，小的在前 |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |

**索引**：

```sql
CREATE INDEX idx_portfolio_items_sort ON portfolio_items (user_id, sort_order);
```

**规则**：

1. 作品不直接持有平台信息，平台信息在 `portfolio_repos` 表中。
2. 一个作品至少关联一个仓库（应用层校验，不在数据库层强制，避免“先建作品后加仓库”的两步操作被卡住）。
3. **作品归属唯一用户**：本期主页按站点聚合展示（站点只有一个用户），查询时仍建议加 `WHERE user_id = ?` 作为未来扩展的保险。

## 十四、portfolio_repos — 作品关联的仓库

**用途**：一个作品可关联多个仓库链接（如同时托管在 Gogs 和 GitHub）。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `portfolio_item_id` | uuid | NOT NULL, FK → portfolio_items(id) ON DELETE CASCADE | — | 所属作品 |
| `platform` | text | NOT NULL, CHECK (`repo_platform`) | — | 托管平台 |
| `repo_path` | text | NOT NULL | — | 如 `username/repo-name` |
| `is_primary` | boolean | NOT NULL | `false` | 是否主链接，主页默认跳转这一个 |

**索引**：

```sql
-- 同一作品下平台 + 路径唯一
CREATE UNIQUE INDEX idx_portfolio_repos_unique ON portfolio_repos (portfolio_item_id, platform, repo_path);

-- 每个作品最多一个主链接
CREATE UNIQUE INDEX idx_portfolio_repos_primary ON portfolio_repos (portfolio_item_id)
  WHERE is_primary = true;
```

**规则**：

1. **仓库地址只存 `repo_path`，不存完整 URL**：完整 URL 由 `platform` + 配置中的 base URL 拼接。Gogs 的 base URL 放在应用配置里（见 `architecture.md`），GitHub 固定为 `https://github.com`。
2. **每个作品最多一个主链接**：由部分唯一索引保证。没有主链接时，主页按平台顺序取第一个。
3. **主链接不强制存在**：作品可以没有 `is_primary = true` 的仓库，主页展示逻辑需处理这种情况。
4. **仓库归属通过作品间接确定**：`portfolio_repos` 不单独带 `user_id`，归属由所属作品决定。任何仓库操作必须先校验所属作品的 `user_id = current_user_id`。
