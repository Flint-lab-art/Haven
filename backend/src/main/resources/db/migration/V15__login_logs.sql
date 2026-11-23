-- 登录审计：单独记录登录相关事件，便于在设置页查看自己的登录历史。
-- 与 audit_events 分开：登录事件写入频率高、字段形态固定，且失败日志必须在登录事务回滚后仍然保留。

CREATE TABLE login_logs
(
    id             uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id        uuid        NULL REFERENCES users (id) ON DELETE SET NULL,
    username       text        NOT NULL DEFAULT '',
    event_type     text        NOT NULL CHECK (event_type IN (
                                                              'login_success',
                                                              'login_failure',
                                                              'totp_failure',
                                                              'logout'
        )),
    method         text        NOT NULL DEFAULT '',
    success        boolean     NOT NULL,
    failure_reason text        NULL,
    ip             text        NOT NULL DEFAULT '',
    user_agent     text        NOT NULL DEFAULT '',
    session_hash   text        NULL,
    metadata       jsonb       NOT NULL DEFAULT '{}'::jsonb,
    created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_login_logs_user ON login_logs (user_id, created_at DESC);
CREATE INDEX idx_login_logs_username ON login_logs (lower(username), created_at DESC);
CREATE INDEX idx_login_logs_created_at ON login_logs (created_at DESC);
