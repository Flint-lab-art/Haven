-- 授信设备：登录时勾选「信任这台设备」后创建，30 天内同设备登录免 TOTP。
CREATE TABLE trusted_devices
(
    id           uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    device_name  text        NOT NULL DEFAULT '',
    token_hash   text        NOT NULL UNIQUE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    last_used_at timestamptz NOT NULL DEFAULT now(),
    expires_at   timestamptz NOT NULL
);

CREATE INDEX idx_trusted_devices_user ON trusted_devices (user_id);

-- 两步验证期间记录本次登录是否勾选了「信任这台设备」。
ALTER TABLE pending_totp
    ADD COLUMN trust_device boolean NOT NULL DEFAULT false;
