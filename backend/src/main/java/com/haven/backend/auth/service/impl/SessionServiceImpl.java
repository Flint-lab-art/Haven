package com.haven.backend.auth.service.impl;

import cn.dev33.satoken.session.SaTerminalInfo;
import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.audit.AuditEventType;
import com.haven.backend.audit.AuditRecorder;
import com.haven.backend.audit.AuditTargetType;
import com.haven.backend.auth.dto.AuthDtos.SessionList;
import com.haven.backend.auth.dto.AuthDtos.SessionSummary;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.service.SessionService;
import com.haven.backend.auth.util.ApiTokenUtil;
import com.haven.backend.exception.BizException;
import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class SessionServiceImpl implements SessionService {

    private final Clock clock;
    private final AuditRecorder auditRecorder;

    @Override
    public SessionList listSessions(String userId) {
        String currentToken = StpUtil.getTokenValue();

        List<SaTerminalInfo> terminals = new ArrayList<>(StpUtil.getTerminalListByLoginId(userId));
        terminals.removeIf(terminal -> !StpUtil.getStpLogic().isValidToken(terminal.getTokenValue()));
        terminals.sort(Comparator.comparingLong(SaTerminalInfo::getCreateTime).reversed());

        List<SessionSummary> result = new ArrayList<>();
        for (SaTerminalInfo terminal : terminals) {
            String tokenValue = terminal.getTokenValue();
            result.add(new SessionSummary(
                    sessionId(tokenValue),
                    stringExtra(terminal, AuthInterceptor.EXTRA_USER_AGENT),
                    toOffsetDateTime(terminal.getCreateTime(), OffsetDateTime.now(clock)),
                    lastUsedAt(tokenValue, terminal.getCreateTime()),
                    tokenValue.equals(currentToken)));
        }
        return new SessionList(result, result.size());
    }

    @Override
    public void revokeSession(String userId, UUID sessionId) {
        String currentToken = StpUtil.getTokenValue();

        for (SaTerminalInfo terminal : StpUtil.getTerminalListByLoginId(userId)) {
            String tokenValue = terminal.getTokenValue();
            if (!sessionId(tokenValue).equals(sessionId)) {
                continue;
            }
            if (tokenValue.equals(currentToken)) {
                throw BizException.validation("当前会话请用「退出」结束");
            }
            StpUtil.kickoutByTokenValue(tokenValue);
            auditRecorder.record(
                    UUID.fromString(userId),
                    null,
                    AuditEventType.SESSION_REVOKED,
                    AuditTargetType.SESSION,
                    sessionId,
                    null,
                    null);
            return;
        }

        throw BizException.notFound("会话不存在或已结束");
    }

    /**
     * 会话对外 ID 使用 token 的 SHA-256，避免把可直接登录的凭证明文发给前端。
     */
    private UUID sessionId(String tokenValue) {
        // sha256 十六进制前 32 位构成 UUID 形式，与前端契约保持不变
        String hex = ApiTokenUtil.hash(tokenValue);
        return new UUID(
                Long.parseUnsignedLong(hex.substring(0, 16), 16), Long.parseUnsignedLong(hex.substring(16, 32), 16));
    }

    private String stringExtra(SaTerminalInfo terminal, String key) {
        Object value = terminal.getExtra(key);
        return value != null ? value.toString() : "";
    }

    private OffsetDateTime lastUsedAt(String tokenValue, long fallbackMillis) {
        long millis = StpUtil.getStpLogic().getTokenLastActiveTime(tokenValue);
        return toOffsetDateTime(millis > 0 ? millis : fallbackMillis, OffsetDateTime.now(clock));
    }

    private OffsetDateTime toOffsetDateTime(long millis, OffsetDateTime fallback) {
        if (millis <= 0) {
            return fallback;
        }
        return OffsetDateTime.ofInstant(Instant.ofEpochMilli(millis), clock.getZone());
    }
}
