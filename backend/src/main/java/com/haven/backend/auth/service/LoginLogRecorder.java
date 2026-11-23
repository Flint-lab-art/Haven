package com.haven.backend.auth.service;

import com.haven.backend.auth.LoginLogEventType;
import com.haven.backend.auth.entity.LoginLogs;
import com.haven.backend.auth.mapper.LoginLogsMapper;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 登录日志记录器。
 * <p>
 * 用 {@link Propagation#REQUIRES_NEW} 独立事务写入：登录失败时外层
 * {@code loginPrecheck} 会在写完日志后抛 401，如果共用事务，日志会一起回滚。
 * <p>
 * 写入失败只打 warn，不影响登录主流程（登录日志是旁路能力）。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LoginLogRecorder {

    private final LoginLogsMapper loginLogsMapper;
    private final Clock clock;

    /**
     * 记录一条登录日志。
     *
     * @param userId 已识别的用户；用户名不存在时为 null
     * @param username 用户名快照，账号删除后仍可追溯
     * @param method password / totp / session
     * @param failureReason 失败原因代码，成功时为 null
     * @param sessionHash 会话 Token 的 SHA-256，失败时为 null
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void record(
            LoginLogEventType type,
            UUID userId,
            String username,
            String method,
            boolean success,
            String failureReason,
            String ip,
            String userAgent,
            String sessionHash) {
        try {
            LoginLogs entry = new LoginLogs();
            entry.setId(UUID.randomUUID());
            entry.setUserId(userId);
            entry.setUsername(username != null ? username : "");
            entry.setEventType(type.value());
            entry.setMethod(method != null ? method : "");
            entry.setSuccess(success);
            entry.setFailureReason(failureReason);
            entry.setIp(ip != null ? ip : "");
            entry.setUserAgent(userAgent != null ? userAgent : "");
            entry.setSessionHash(sessionHash);
            entry.setCreatedAt(OffsetDateTime.now(clock));
            loginLogsMapper.insert(entry);
        } catch (RuntimeException e) {
            log.warn("写入登录日志失败, type={}, username={}", type.value(), username, e);
        }
    }
}
