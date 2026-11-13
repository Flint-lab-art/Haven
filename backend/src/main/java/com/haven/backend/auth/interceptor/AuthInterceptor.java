package com.haven.backend.auth.interceptor;

import cn.dev33.satoken.session.SaTerminalInfo;
import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.auth.entity.Tokens;
import com.haven.backend.exception.BizException;
import com.haven.backend.auth.mapper.TokensMapper;
import com.haven.backend.auth.util.ApiTokenUtil;
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
    public static final String ATTR_TOTP_VERIFIED = "auth_totpVerified";

    /** Sa-Token 终端扩展数据：登录时的 User-Agent。 */
    public static final String EXTRA_USER_AGENT = "user_agent";
    /** Sa-Token 终端扩展数据：本次会话是否通过动态码（或授信设备）验证。 */
    public static final String EXTRA_TOTP_VERIFIED = "totp_verified";

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
        SaTerminalInfo terminal = StpUtil.getTerminalInfo();
        request.setAttribute(ATTR_TOTP_VERIFIED, terminal != null
                && Boolean.TRUE.equals(terminal.getExtra(EXTRA_TOTP_VERIFIED)));
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
        // 只读 Token 不允许执行写操作（GET/HEAD/OPTIONS 之外的方法）。
        if (!isReadOnlyMethod(request.getMethod()) && !"read_write".equals(token.getScope())) {
            writeError(response, 403, "当前 Token 只读，无写权限");
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
        request.setAttribute(ATTR_TOTP_VERIFIED, false);
        return true;
    }

    private static boolean isReadOnlyMethod(String method) {
        return "GET".equalsIgnoreCase(method)
                || "HEAD".equalsIgnoreCase(method)
                || "OPTIONS".equalsIgnoreCase(method);
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

    /**
     * 获取当前用户 ID；未认证时抛出 401。
     * <p>
     * 同时适用于浏览器会话与 API Token 两种通道，控制器不应直接调用 Sa-Token 的 checkLogin。
     */
    public static String requireUserId(HttpServletRequest request) {
        String userId = getUserId(request);
        if (userId == null || userId.isBlank()) {
            throw BizException.unauthorized("未登录或凭证无效");
        }
        return userId;
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

    /** 当前请求是否来自浏览器会话（而不是 API Token）。 */
    public static boolean isSession(HttpServletRequest request) {
        return "session".equals(getAuthType(request));
    }

    /** 当前会话是否已通过动态码（或授信设备）验证。 */
    public static boolean isTotpVerified(HttpServletRequest request) {
        return Boolean.TRUE.equals(request.getAttribute(ATTR_TOTP_VERIFIED));
    }

    /** 仅允许浏览器会话访问；API Token 一律 403。 */
    public static void requireSession(HttpServletRequest request) {
        if (!isSession(request)) {
            throw BizException.forbidden("该操作仅支持浏览器会话，API Token 不可用");
        }
    }

    /** 仅允许已通过动态码验证的浏览器会话访问。 */
    public static void requireSessionTotp(HttpServletRequest request) {
        requireSession(request);
        if (!isTotpVerified(request)) {
            throw BizException.forbidden("请先完成动态码验证后再管理 API Token");
        }
    }
}
