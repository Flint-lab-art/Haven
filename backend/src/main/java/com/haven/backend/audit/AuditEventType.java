package com.haven.backend.audit;

/**
 * 审计事件类型，与 {@code audit_events.event_type} 的 CHECK 约束保持一致。
 */
public enum AuditEventType {
    LOGIN_SUCCESS("login_success"),
    LOGIN_FAILURE("login_failure"),
    LOGOUT("logout"),
    TOTP_BOUND("totp_bound"),
    TOTP_DISABLED("totp_disabled"),
    PASSWORD_CHANGED("password_changed"),
    SESSION_REVOKED("session_revoked"),
    TRUSTED_DEVICE_ADDED("trusted_device_added"),
    TRUSTED_DEVICE_REVOKED("trusted_device_revoked"),
    TOKEN_CREATED("token_created"),
    TOKEN_REVOKED("token_revoked"),
    NOTE_PUBLISHED("note_published"),
    NOTE_UNPUBLISHED("note_unpublished");

    private final String value;

    AuditEventType(String value) {
        this.value = value;
    }

    /** 落库用的字符串值。 */
    public String value() {
        return value;
    }
}
