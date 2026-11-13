package com.haven.backend.auth.service.impl;

import cn.dev33.satoken.session.SaTerminalInfo;
import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.exception.BizException;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.service.SessionService;
import com.haven.backend.auth.util.ApiTokenUtil;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class SessionServiceImpl implements SessionService {

    @Override
    public List<Map<String, Object>> listSessions(String userId) {
        String currentToken = StpUtil.getTokenValue();

        List<SaTerminalInfo> terminals = new ArrayList<>(StpUtil.getTerminalListByLoginId(userId));
        terminals.removeIf(terminal -> !StpUtil.getStpLogic().isValidToken(terminal.getTokenValue()));
        terminals.sort(Comparator.comparingLong(SaTerminalInfo::getCreateTime).reversed());

        List<Map<String, Object>> result = new ArrayList<>();
        for (SaTerminalInfo terminal : terminals) {
            String tokenValue = terminal.getTokenValue();
            String userAgent = stringExtra(terminal, AuthInterceptor.EXTRA_USER_AGENT);

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", sessionId(tokenValue));
            item.put("user_agent", userAgent);
            item.put("created_at", toOffsetDateTime(terminal.getCreateTime(), OffsetDateTime.now()));
            item.put("last_used_at", lastUsedAt(tokenValue, terminal.getCreateTime()));
            item.put("is_current", tokenValue.equals(currentToken));
            result.add(item);
        }
        return result;
    }

    @Override
    public void revokeSession(String userId, String sessionId) {
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
            return;
        }

        throw BizException.notFound("会话不存在或已结束");
    }

    /**
     * 会话对外 ID 使用 token 的 SHA-256，避免把可直接登录的凭证明文发给前端。
     */
    private String sessionId(String tokenValue) {
        return ApiTokenUtil.hash(tokenValue);
    }

    private String stringExtra(SaTerminalInfo terminal, String key) {
        Object value = terminal.getExtra(key);
        return value != null ? value.toString() : "";
    }

    private OffsetDateTime lastUsedAt(String tokenValue, long fallbackMillis) {
        long millis = StpUtil.getStpLogic().getTokenLastActiveTime(tokenValue);
        return toOffsetDateTime(millis > 0 ? millis : fallbackMillis, OffsetDateTime.now());
    }

    private OffsetDateTime toOffsetDateTime(long millis, OffsetDateTime fallback) {
        if (millis <= 0) {
            return fallback;
        }
        return OffsetDateTime.ofInstant(Instant.ofEpochMilli(millis), ZoneId.systemDefault());
    }
}
