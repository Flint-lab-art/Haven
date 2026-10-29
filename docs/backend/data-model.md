# data-model — 数据库 schema

> 本文件回答：数据库有哪些表、每张表有哪些字段、约束、索引与业务规则。
> 依赖：无

## 一、书写约定

每张表统一按四部分书写：用途、字段表、索引、规则。

全局约定：

- 主键统一用 `uuid`，默认 `gen_random_uuid()`。需要 PostgreSQL 13+，或启用 `pgcrypto` 扩展。
- 时间字段统一用 `timestamptz`。
- 命名统一 `snake_case`。
- 枚举值用 `text + CHECK`，不用 PostgreSQL 原生 enum（便于后续加值不改类型）。
- 本期所有删除为硬删除，不做软删除。如需软删除，先改本文件再实现。
- 搜索依赖 `pg_trgm` 扩展，数据库初始化时必须执行 `CREATE EXTENSION IF NOT EXISTS pg_trgm;`。
- 不安装任何中文分词扩展（`zhparser` / `pg_jieba` / `pg_bigm` 等）。搜索走 PostgreSQL 自带的模糊匹配，理由见第八节。
- **所有业务数据表都带 `user_id` 归属字段**，即使本期单人自用。这是技术预留：注册功能本期不实现，`users` 表只放唯一账号，但数据模型从第一天就按“未来可能有第二个账号”设计，避免以后改表。
- **数据表之间的依赖顺序**：`users` → `sessions` / `pending_logins` / `trusted_devices` / `tokens` / `audit_events` → `notes` / `tags` / `portfolio_items` → `note_tags` / `portfolio_repos`。migration 必须按此顺序创建。

## 二、枚举值汇总

各表小节引用此处，不重复定义。

| 枚举名 | 取值 | 说明 |
|---|---|---|
| `note_visibility` | `private` / `public` | 笔记可见性 |
| `repo_platform` | `gogs` / `github` | 作品集仓库托管平台 |
| `token_scope` | `read` / `read_write` | API Token 权限档位 |


## 三、notes — 笔记

**用途**：存储所有笔记内容，私有与公开共用一张表，靠 `visibility` 区分。
`content` 字段内容为 Markdown 源文本，前端负责渲染。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `folder_id` | uuid | NULL, FK → folders(id) ON DELETE SET NULL | NULL | 所属文件夹；NULL 表示未分类 |
| `title` | text | NOT NULL | — | 标题 |
| `content` | text | NOT NULL | `''` | 正文，允许空串 |
| `visibility` | text | NOT NULL, CHECK (visibility IN ('private','public')) | `'private'` | 可见性，默认私有 |
| `published_at` | timestamptz | NULL | NULL | 首次公开发布时间，仅 public 时有意义 |
| `search_text` | text | GENERATED ALWAYS AS (`title || ' ' || content`) STORED | — | 搜索用合并字段，数据库自动维护，应用层只读不写 |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |
| `updated_at` | timestamptz | NOT NULL | `now()` | 最后更新时间，由应用层在每次写入时更新 |

**索引**：

```sql
-- 公开列表：按用户 + 发布时间倒序
CREATE INDEX idx_notes_public ON notes (user_id, published_at DESC)
  WHERE visibility = 'public' AND published_at IS NOT NULL;

-- 私有工作台：按用户 + 最近更新排序
CREATE INDEX idx_notes_updated_at ON notes (user_id, updated_at DESC);

-- 模糊搜索：search_text trigram 索引
CREATE INDEX idx_notes_search_trgm ON notes USING gin (search_text gin_trgm_ops);
```

**规则**：

1. **新建笔记一律 private**：数据库层 `DEFAULT 'private'` + `NOT NULL` 兜底；创建接口不接受 `visibility` 参数（见 `conventions.md` 第四节）。
2. **公开是显式动作**：`private → public` 通过独立的 publish 操作完成，该操作在 `published_at IS NULL` 时写入当前时间。
3. **撤回不清空 `published_at`**：`public → private` 时 `published_at` 保留，语义为“首次公开发布时间”；再次公开不覆盖。
4. **公开可见的判定条件唯一**：`visibility = 'public' AND published_at IS NOT NULL`。任何公开读路径必须使用此条件，不得只看 `visibility`。
5. **`published_at` 对 private 笔记无意义**：private 笔记不因 `published_at` 是否存在而改变可见性，该字段只服务于公开列表排序与未来 RSS。
6. **`search_text` 由数据库自动维护**：应用层不得在 INSERT / UPDATE 时写入该字段，也不得在 Go 代码中手动拼接。搜索查询统一使用 `search_text`，不直接查 `title` 或 `content`。
7. **搜索结果受可见性约束**：搜索查询同样要经过授权中间件的 visibility 过滤（未登录只能搜到 public 笔记）。具体过滤规则见 `docs/backend/auth.md`，本表不重复定义。
8. **笔记归属唯一用户**：所有笔记读写操作必须以当前登录用户为过滤条件，即 `WHERE user_id = current_user_id`。授权中间件在 visibility 过滤之外，必须叠加用户归属过滤。跨用户访问视为越权，返回 404 而非 403（不泄露笔记存在性）。
9. **文件夹归属**：笔记可以属于某个文件夹（`folder_id`），也可以不属于任何文件夹（`folder_id IS NULL`，即“未分类”）。删除文件夹时，笔记不会被删除，而是自动变为未分类。

## 四、tags — 标签

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

## 五、note_tags — 笔记与标签关联

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

## 六、portfolio_items — 作品集条目

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

## 七、portfolio_repos — 作品关联的仓库

**用途**：一个作品可关联多个仓库链接（如同时托管在 Gogs 和 GitHub）。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `portfolio_item_id` | uuid | NOT NULL, FK → portfolio_items(id) ON DELETE CASCADE | — | 所属作品 |
| `platform` | text | NOT NULL, CHECK (platform IN ('gogs','github')) | — | 托管平台 |
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

## 七点五、folders — 文件夹目录树

**用途**：支持无限嵌套的目录结构，用于整理笔记。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | 主键 |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | — | 所属用户 |
| `parent_id` | uuid | NULL, FK → folders(id) ON DELETE CASCADE | NULL | 父文件夹；NULL 表示根目录 |
| `name` | text | NOT NULL | — | 文件夹名称 |
| `sort_order` | int | NOT NULL | `0` | 排序权重，小的在前 |
| `created_at` | timestamptz | NOT NULL | `now()` | 创建时间 |
| `updated_at` | timestamptz | NOT NULL | `now()` | 更新时间 |

**索引**：
```sql
CREATE INDEX idx_folders_user_parent ON folders (user_id, parent_id);
```

**规则**：

1. **无限嵌套**：通过 `parent_id` 实现无限层级。
2. **删除策略**：删除父文件夹时，子文件夹通过 `ON DELETE CASCADE` 级联删除；文件夹内的笔记通过 `ON DELETE SET NULL` 自动迁移到未分类，绝对不级联删除笔记。
3. **命名唯一性**：同一个父目录下，不允许有同名的文件夹（应用层校验）。


## 八、搜索设计说明

**范围**：笔记标题、笔记正文、标签名。三处都支持模糊包含查询。

**技术**：

- 笔记标题 + 正文：通过 `notes.search_text` 生成列合并，对合并字段建 `pg_trgm` GIN 索引，查询 `WHERE user_id = ? AND search_text ILIKE '%关键词%'`。
- 标签名：对 `tags.name` 建 `pg_trgm` GIN 索引，查询 `WHERE user_id = ? AND name ILIKE '%关键词%'`。
- 不安装中文分词扩展。1–2 个字的查询会退化为全表扫描，接受这一代价（数据量小，且实际使用中很少只搜一两个字）。

**已知限制**：本期搜索为子串匹配，只处理“包含”语义。不处理同义词（如“知识中台”搜不到“知识管理平台”）、不处理繁体与简体互通、不纠正错别字。这是刻意的取舍：自用场景、数据量小，子串匹配足够日常检索；语义检索与分词留到第二版评估。

**返回**：

- 笔记搜索结果返回笔记列表，同时返回每篇笔记的标签（联查 `note_tags` + `tags`）。
- 标签搜索结果返回标签列表，点进去看该标签下的笔记。
- 搜索本身是一个接口还是两个接口，由 `api.md` 定义，本文件不规定。

## 九、鉴权与审计相关表

以下表的完整字段与规则见 `docs/backend/auth.md` 与 `docs/backend/audit.md`：

- `users` — 用户账号（见 auth.md 第九节）
- `sessions` — 正式登录会话（见 auth.md 第三节）
- `pending_logins` — 待验证登录（账密已过、TOTP 待验，见 auth.md 第 3.1 节）
- `trusted_devices` — 可授信浏览器设备（见 auth.md 第四节）
- `tokens` — 长期 API Token（见 auth.md 第五节）
- `audit_events` — 审计事件（见 audit.md 第二节）

 **migration 顺序**：`users` 必须最先创建；`sessions`、`pending_logins`、`trusted_devices`、`tokens`、`audit_events` 依赖 `users`；`folders` 依赖 `users`（且通过 `parent_id` 自引用）；`notes`、`tags`、`portfolio_items` 依赖 `users`，且 `notes` 依赖 `folders`。
