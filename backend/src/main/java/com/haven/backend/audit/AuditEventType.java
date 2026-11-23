package com.haven.backend.audit;

/**
 * 非登录类审计事件类型。
 * <p>
 * 登录成功 / 失败 / 登出由 {@code login_logs} 单独记录；{@code audit_events} 的 CHECK
 * 仍保留这些历史取值，但新代码不再写入。
 */
public enum AuditEventType {
    TOTP_BOUND("totp_bound"),
    TOTP_DISABLED("totp_disabled"),
    PASSWORD_CHANGED("password_changed"),
    SESSION_REVOKED("session_revoked"),
    TRUSTED_DEVICE_ADDED("trusted_device_added"),
    TRUSTED_DEVICE_REVOKED("trusted_device_revoked"),
    TOKEN_CREATED("token_created"),
    TOKEN_REVOKED("token_revoked");

    private final String value;

    AuditEventType(String value) {
        this.value = value;
    }

    /** 落库用的字符串值。 */
    public String value() {
        return value;
    }
}
