BEGIN;

-- 搜索依赖 pg_trgm
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- users 用户表（保留，仅会话相关字段全部移除）
-- ---------------------------------------------------------------------------
CREATE TABLE users
(
    id            uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    username      text        NOT NULL,
    password_hash text        NOT NULL,
    totp_secret   text        NULL     DEFAULT NULL,
    totp_enabled  boolean     NOT NULL DEFAULT false,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_users_username_lower ON users (lower(username));

-- ---------------------------------------------------------------------------
-- sa_token : Sa-Token JDBC持久化主表（会话、登录凭证）
-- ---------------------------------------------------------------------------
CREATE TABLE sa_token
(
    id               bigserial PRIMARY KEY,
    token_value      text        NOT NULL,
    token_type       text        NOT NULL,
    login_id         text        NOT NULL,
    device           text        NOT NULL,
    token_timeout    bigint      NOT NULL,
    session_timeout  bigint      NOT NULL,
    extra_data       jsonb       NOT NULL DEFAULT '{}'::jsonb,
    create_time      timestamptz NOT NULL DEFAULT now(),
    last_active_time timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_sa_token_login_id ON sa_token (login_id);
CREATE INDEX idx_sa_token_token_value ON sa_token (token_value);
CREATE INDEX idx_sa_token_timeout ON sa_token (token_timeout);

-- ---------------------------------------------------------------------------
-- pending_totp 两步验证临时表（账号密码通过，等待TOTP校验）
-- 校验成功后删除本条记录，再创建Sa-Token会话
-- ---------------------------------------------------------------------------
CREATE TABLE pending_totp
(
    id         uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token      text        NOT NULL UNIQUE,
    ip         text        NOT NULL DEFAULT '',
    user_agent text        NOT NULL DEFAULT '',
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_pending_totp_token ON pending_totp (token);
CREATE INDEX idx_pending_totp_user ON pending_totp (user_id, expires_at);

-- ---------------------------------------------------------------------------
-- tokens 独立API密钥表（和网页Sa-Token会话隔离，原样保留）
-- ---------------------------------------------------------------------------
CREATE TABLE tokens
(
    id           uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
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
CREATE INDEX idx_tokens_user ON tokens (user_id);

-- ---------------------------------------------------------------------------
-- audit_events 审计表（原样保留，业务手动写入）
-- ---------------------------------------------------------------------------
CREATE TABLE audit_events
(
    id             uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
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
-- folders 文件夹
-- ---------------------------------------------------------------------------
CREATE TABLE folders
(
    id         uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    parent_id  uuid        NULL REFERENCES folders (id) ON DELETE CASCADE,
    name       text        NOT NULL,
    sort_order int         NOT NULL DEFAULT -1,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    icon       text        NULL,
    is_inbox   boolean     NOT NULL DEFAULT false
);

CREATE INDEX idx_folders_user_parent ON folders (user_id, parent_id);
CREATE UNIQUE INDEX idx_folders_inbox ON folders (user_id) WHERE is_inbox;

-- ---------------------------------------------------------------------------
-- notes 笔记
-- ---------------------------------------------------------------------------
CREATE TABLE notes
(
    id           uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title        text        NOT NULL,
    content      text        NOT NULL DEFAULT '',
    visibility   text        NOT NULL DEFAULT 'private'
        CHECK (visibility IN ('private', 'public')),
    published_at timestamptz NULL     DEFAULT NULL,
    search_text  text        NOT NULL DEFAULT '',
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    folder_id    uuid        NULL REFERENCES folders (id) ON DELETE SET NULL,
    sort_order   int         NOT NULL DEFAULT -1,
    deleted_at   timestamptz NULL     DEFAULT NULL
);

CREATE INDEX idx_notes_public ON notes (user_id, published_at DESC)
    WHERE visibility = 'public' AND published_at IS NOT NULL;
CREATE INDEX idx_notes_updated_at ON notes (user_id, updated_at DESC);
CREATE INDEX idx_notes_search_trgm ON notes USING gin (search_text gin_trgm_ops);
CREATE INDEX idx_notes_folder_sort ON notes (user_id, folder_id, sort_order);
CREATE INDEX idx_notes_deleted ON notes (user_id, deleted_at DESC)
    WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_notes_title_trgm ON notes USING gin (title gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- tags 标签
-- ---------------------------------------------------------------------------
CREATE TABLE tags
(
    id         uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       text        NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_tags_user_name_lower ON tags (user_id, lower(name));
CREATE INDEX idx_tags_name_trgm ON tags USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- note_tags 笔记标签关联
-- ---------------------------------------------------------------------------
CREATE TABLE note_tags
(
    note_id uuid NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
    tag_id  uuid NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
    PRIMARY KEY (note_id, tag_id)
);
CREATE INDEX idx_note_tags_tag_id ON note_tags (tag_id);

-- ---------------------------------------------------------------------------
-- portfolio_items 作品集项目
-- ---------------------------------------------------------------------------
CREATE TABLE portfolio_items
(
    id          uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title       text        NOT NULL,
    description text        NOT NULL DEFAULT '',
    sort_order  int         NOT NULL DEFAULT -1,
    created_at  timestamptz NOT NULL DEFAULT now(),
    content     text        NOT NULL DEFAULT ''
);
CREATE INDEX idx_portfolio_items_sort ON portfolio_items (user_id, sort_order);

-- ---------------------------------------------------------------------------
-- portfolio_repos 作品集仓库链接
-- ---------------------------------------------------------------------------
CREATE TABLE portfolio_repos
(
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_item_id uuid    NOT NULL REFERENCES portfolio_items (id) ON DELETE CASCADE,
    url               text    NOT NULL DEFAULT '',
    title             text    NOT NULL DEFAULT '',
    is_primary        boolean NOT NULL DEFAULT false
);
CREATE UNIQUE INDEX idx_portfolio_repos_unique
    ON portfolio_repos (portfolio_item_id, url);
CREATE UNIQUE INDEX idx_portfolio_repos_primary
    ON portfolio_repos (portfolio_item_id)
    WHERE is_primary = true;

-- ---------------------------------------------------------------------------
-- note_versions 笔记历史版本
-- ---------------------------------------------------------------------------
CREATE TABLE note_versions
(
    id         uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    note_id    uuid        NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title      text        NOT NULL,
    content    text        NULL DEFAULT '',
    folder_id  uuid        NULL,
    tag_ids    uuid[]      NOT NULL DEFAULT '{}',
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_note_versions_note ON note_versions (note_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- issues 需求/bug
-- ---------------------------------------------------------------------------
CREATE TABLE issues
(
    id          uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title       text        NOT NULL,
    description text        NOT NULL DEFAULT '',
    type        text        NOT NULL CHECK (type IN ('bug', 'feature')),
    status      text        NOT NULL DEFAULT 'todo'
        CHECK (status IN ('todo', 'in_progress', 'done')),
    priority    text        NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high')),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    parent_id   uuid        NULL REFERENCES issues (id) ON DELETE CASCADE
);
CREATE INDEX idx_issues_user_created ON issues (user_id, created_at DESC);
CREATE INDEX idx_issues_user_status ON issues (user_id, status, created_at DESC);
CREATE INDEX idx_issues_parent ON issues (parent_id)
    WHERE parent_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- issue_status_events 工单状态变更事件
-- ---------------------------------------------------------------------------
CREATE TABLE issue_status_events
(
    id          uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    issue_id    uuid        NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    from_status text        NULL CHECK (from_status IN ('todo', 'in_progress', 'done')),
    to_status   text        NOT NULL CHECK (to_status IN ('todo', 'in_progress', 'done')),
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_issue_status_events_issue
    ON issue_status_events (issue_id, created_at DESC);

COMMIT;
