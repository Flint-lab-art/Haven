package com.haven.backend.auth;

/**
 * 登录日志事件类型，与 {@code login_logs.event_type} 的 CHECK 约束保持一致。
 */
public enum LoginLogEventType {
    LOGIN_SUCCESS("login_success"),
    LOGIN_FAILURE("login_failure"),
    TOTP_FAILURE("totp_failure"),
    LOGOUT("logout");

    private final String value;

    LoginLogEventType(String value) {
        this.value = value;
    }

    /** 落库用的字符串值。 */
    public String value() {
        return value;
    }
}
