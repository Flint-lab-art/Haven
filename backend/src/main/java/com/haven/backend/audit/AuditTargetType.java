package com.haven.backend.audit;

/**
 * 审计事件的目标类型，与 {@code audit_events.target_type} 的 CHECK 约束保持一致。
 */
public enum AuditTargetType {
    USER("user"),
    SESSION("session"),
    TRUSTED_DEVICE("trusted_device"),
    TOKEN("token"),
    NOTE("note");

    private final String value;

    AuditTargetType(String value) {
        this.value = value;
    }

    /** 落库用的字符串值。 */
    public String value() {
        return value;
    }
}
