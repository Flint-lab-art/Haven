-- 0001_init
--
-- Haven 初始 schema。依据：
--   docs/backend/data-model.md（表、索引、枚举）
--   docs/backend/auth.md 第三节 / 3.1 / 四 / 五 / 九（sessions、pending_logins、
--     trusted_devices、tokens、users）
--   docs/backend/audit.md 第二节 / 第三节（audit_events）
--
-- 建表顺序遵循 data-model.md 第一节：
--   users -> sessions / pending_logins / trusted_devices / tokens / audit_events
--         -> notes / tags / portfolio_items
--         -> note_tags / portfolio_repos
--
-- 本文件由部署脚本执行，后端启动时不自动跑 migration
-- （docs/architecture.md 5.6）。

-- 搜索依赖 pg_trgm（data-model.md 第一节）。
-- PostgreSQL >= 15 自带 gen_random_uuid()，无需 pgcrypto。
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- users（字段以 docs/backend/auth.md 第九节为准）
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    username      text        NOT NULL,
    password_hash text        NOT NULL,
    totp_secret   text        NULL DEFAULT NULL,
    totp_enabled  boolean     NOT NULL DEFAULT false,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

-- username 不区分大小写唯一（auth.md 第九节规则 3）。
-- 只建小写唯一索引，不再额外加普通 UNIQUE，避免 Admin / admin 同时存在。
CREATE UNIQUE INDEX idx_users_username_lower ON users (lower(username));

-- ---------------------------------------------------------------------------
-- sessions（auth.md 第三节）
-- ---------------------------------------------------------------------------
CREATE TABLE sessions (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash   text        NOT NULL UNIQUE,
    expires_at   timestamptz NOT NULL,
    last_used_at timestamptz NOT NULL,
    user_agent   text        NOT NULL DEFAULT '',
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- pending_logins（auth.md 3.1）
-- ---------------------------------------------------------------------------
CREATE TABLE pending_logins (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash text        NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- trusted_devices（auth.md 第四节）
-- ---------------------------------------------------------------------------
CREATE TABLE trusted_devices (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash   text        NOT NULL UNIQUE,
    device_name  text        NOT NULL DEFAULT '',
    expires_at   timestamptz NOT NULL,
    last_used_at timestamptz NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- tokens（auth.md 第五节）
-- ---------------------------------------------------------------------------
CREATE TABLE tokens (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name         text        NOT NULL,
    token_hash   text        NOT NULL UNIQUE,
    token_prefix text        NOT NULL,
    scope        text        NOT NULL CHECK (scope IN ('read', 'read_write')),
    expires_at   timestamptz NULL,
    last_used_at timestamptz NULL,
    revoked_at   timestamptz NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- audit_events（audit.md 第二节、第三节）
-- 只追加，不修改，不删除。
-- ---------------------------------------------------------------------------
CREATE TABLE audit_events (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id  uuid        NULL REFERENCES users (id) ON DELETE SET NULL,
    actor_username text        NOT NULL DEFAULT '',
    event_type     text        NOT NULL CHECK (event_type IN (
                       'login_success',
                       'login_failure',
                       'logout',
                       'totp_bound',
                       'totp_disabled',
                       'password_changed',
                       'session_revoked',
                       'trusted_device_added',
                       'trusted_device_revoked',
                       'token_created',
                       'token_revoked',
                       'note_published',
                       'note_unpublished'
                   )),
    -- 'null' 为字符串字面量，表示“无对象”，与 SQL NULL 区分（audit.md 第三节说明）
    target_type    text        NULL CHECK (target_type IN (
                       'null', 'user', 'session', 'trusted_device', 'token', 'note'
                   )),
    target_id      uuid        NULL,
    metadata       jsonb       NOT NULL DEFAULT '{}'::jsonb,
    ip             text        NOT NULL DEFAULT '',
    user_agent     text        NOT NULL DEFAULT '',
    created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_events_created_at ON audit_events (created_at DESC);
CREATE INDEX idx_audit_events_event_type ON audit_events (event_type, created_at DESC);
CREATE INDEX idx_audit_events_actor ON audit_events (actor_user_id, created_at DESC)
    WHERE actor_user_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- notes（data-model.md 第三节）
-- ---------------------------------------------------------------------------
CREATE TABLE notes (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title        text        NOT NULL,
    content      text        NOT NULL DEFAULT '',
    visibility   text        NOT NULL DEFAULT 'private'
                     CHECK (visibility IN ('private', 'public')),
    published_at timestamptz NULL DEFAULT NULL,
    -- 搜索用合并字段，数据库自动维护，应用层只读不写（data-model.md 第三节规则 6）
    search_text  text        GENERATED ALWAYS AS (title || ' ' || content) STORED,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);

-- 公开列表：按用户 + 发布时间倒序
CREATE INDEX idx_notes_public ON notes (user_id, published_at DESC)
    WHERE visibility = 'public' AND published_at IS NOT NULL;

-- 私有工作台：按用户 + 最近更新排序
CREATE INDEX idx_notes_updated_at ON notes (user_id, updated_at DESC);

-- 模糊搜索：search_text trigram 索引
CREATE INDEX idx_notes_search_trgm ON notes USING gin (search_text gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- tags（data-model.md 第四节）
-- ---------------------------------------------------------------------------
CREATE TABLE tags (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       text        NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 同一用户下标签名不区分大小写唯一
CREATE UNIQUE INDEX idx_tags_user_name_lower ON tags (user_id, lower(name));

-- 标签名模糊搜索
CREATE INDEX idx_tags_name_trgm ON tags USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- portfolio_items（data-model.md 第六节）
-- ---------------------------------------------------------------------------
CREATE TABLE portfolio_items (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title       text        NOT NULL,
    description text        NOT NULL DEFAULT '',
    sort_order  int         NOT NULL DEFAULT 0,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_portfolio_items_sort ON portfolio_items (user_id, sort_order);

-- ---------------------------------------------------------------------------
-- note_tags（data-model.md 第五节）
-- 无 user_id：归属由 notes.user_id 与 tags.user_id 在应用层校验。
-- ---------------------------------------------------------------------------
CREATE TABLE note_tags (
    note_id uuid NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
    tag_id  uuid NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
    PRIMARY KEY (note_id, tag_id)
);

-- 复合主键已覆盖 note_id 开头的查询；单独为 tag_id 建索引，支持“按标签查笔记”
CREATE INDEX idx_note_tags_tag_id ON note_tags (tag_id);

-- ---------------------------------------------------------------------------
-- portfolio_repos（data-model.md 第七节）
-- 无 user_id：归属通过 portfolio_items 间接确定。
-- ---------------------------------------------------------------------------
CREATE TABLE portfolio_repos (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_item_id uuid    NOT NULL REFERENCES portfolio_items (id) ON DELETE CASCADE,
    platform          text    NOT NULL CHECK (platform IN ('gogs', 'github')),
    repo_path         text    NOT NULL,
    is_primary        boolean NOT NULL DEFAULT false
);

-- 同一作品下平台 + 路径唯一
CREATE UNIQUE INDEX idx_portfolio_repos_unique
    ON portfolio_repos (portfolio_item_id, platform, repo_path);

-- 每个作品最多一个主链接
CREATE UNIQUE INDEX idx_portfolio_repos_primary
    ON portfolio_repos (portfolio_item_id)
    WHERE is_primary = true;
