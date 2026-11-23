package com.haven.backend.auth.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 登录日志的响应契约。
 * <p>
 * 不返回 {@code session_hash}：它虽然不可逆，但属于会话关联信息，前端展示用不到。
 */
public final class LoginLogDtos {

    private LoginLogDtos() {}

    /** 一条登录日志。 */
    public record LoginLogSummary(
            UUID id,
            String eventType,
            String username,
            String method,
            boolean success,
            String failureReason,
            String ip,
            String userAgent,
            OffsetDateTime createdAt) {}

    /** 登录日志分页列表。 */
    public record LoginLogPage(List<LoginLogSummary> items, long total) {}
}
