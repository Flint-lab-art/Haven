package com.haven.backend.interceptor;

import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.entity.Tokens;
import com.haven.backend.mapper.TokensMapper;
import com.haven.backend.util.ApiTokenUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.time.OffsetDateTime;

/**
 * 统一认证拦截器：Session + API Token 双通道。
 * <p>
 * 优先检查 Authorization: Bearer（API Token），未提供时回退到 Sa-Token 会话验证。
 * 身份上下文通过 request attribute 注入，供 Controller 读取。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final TokensMapper tokensMapper;

    public static final String ATTR_USER_ID = "auth_userId";
    public static final String ATTR_SCOPE = "auth_scope";
    public static final String ATTR_AUTH_TYPE = "auth_type";
    private static final String BEARER_PREFIX = "Bearer ";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String authHeader = request.getHeader("Authorization");

        // 通道 1：API Token（Bearer）
        if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
            String rawToken = authHeader.substring(BEARER_PREFIX.length()).trim();
            return handleApiToken(request, response, rawToken);
        }

        // 通道 2：Sa-Token 会话（Cookie / Header）
        StpUtil.checkLogin();
        String userId = StpUtil.getLoginIdAsString();
        request.setAttribute(ATTR_USER_ID, userId);
        request.setAttribute(ATTR_SCOPE, "read_write");
        request.setAttribute(ATTR_AUTH_TYPE, "session");
        return true;
    }

    private boolean handleApiToken(HttpServletRequest request, HttpServletResponse response, String rawToken) {
        String hash = ApiTokenUtil.hash(rawToken);
        Tokens token = tokensMapper.selectOne(
                new LambdaQueryWrapper<Tokens>()
                        .eq(Tokens::getTokenHash, hash));

        if (token == null || token.getRevokedAt() != null) {
            writeError(response, 401, "Token 无效或已撤销");
            return false;
        }
        if (token.getExpiresAt() != null && token.getExpiresAt().isBefore(OffsetDateTime.now())) {
            writeError(response, 401, "Token 已过期");
            return false;
        }

        // 尽力刷新 last_used_at（失败不影响请求）
        try {
            token.setLastUsedAt(OffsetDateTime.now());
            tokensMapper.updateById(token);
        } catch (Exception e) {
            log.warn("刷新 API Token last_used_at 失败: {}", e.getMessage());
        }

        request.setAttribute(ATTR_USER_ID, token.getUserId());
        request.setAttribute(ATTR_SCOPE, token.getScope());
        request.setAttribute(ATTR_AUTH_TYPE, "token");
        return true;
    }

    private void writeError(HttpServletResponse response, int status, String message) {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        try {
            response.getWriter().write(
                    "{\"code\":" + status + ",\"message\":\"" + message + "\",\"data\":null}");
        } catch (Exception ignored) {
        }
    }

    // ---- 静态工具：供 Controller 读取当前请求的身份上下文 ----

    public static String getUserId(HttpServletRequest request) {
        Object v = request.getAttribute(ATTR_USER_ID);
        return v != null ? v.toString() : null;
    }

    public static String getScope(HttpServletRequest request) {
        Object v = request.getAttribute(ATTR_SCOPE);
        return v != null ? v.toString() : null;
    }

    public static String getAuthType(HttpServletRequest request) {
        Object v = request.getAttribute(ATTR_AUTH_TYPE);
        return v != null ? v.toString() : null;
    }

    /** 校验当前请求是否具有写权限（scope = read_write）。 */
    public static boolean requireWrite(HttpServletRequest request) {
        return "read_write".equals(getScope(request));
    }
}
