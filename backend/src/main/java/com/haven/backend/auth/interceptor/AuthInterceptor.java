package com.haven.backend.auth.interceptor;

import cn.dev33.satoken.session.SaTerminalInfo;
import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.auth.entity.Tokens;
import com.haven.backend.auth.mapper.TokensMapper;
import com.haven.backend.auth.util.ApiTokenUtil;
import com.haven.backend.exception.BizException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 统一认证拦截器：Session + API Token 双通道。
 * <p>
 * 优先检查 Authorization: Bearer（API Token），未提供时回退到 Sa-Token 会话验证。
 * 身份上下文通过 request attribute 注入，供 Controller 读取。
 * <p>
 * 认证失败一律抛 {@link BizException}，由 {@link com.haven.backend.exception.GlobalExceptionHandler}
 * 统一输出 {@code {error,message}}，避免拦截器和全局异常处理器出现两套错误契约。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    /**
     * 允许匿名访问、但携带凭证时仍要识别身份的路径。
     * <p>
     * 这类接口在无凭证或凭证失效时按匿名处理，而不是返回 401。
     */
    private static final Set<String> OPTIONAL_AUTH_PATHS = Set.of("/api/me");

    private final TokensMapper tokensMapper;
    private final Clock clock;

    public static final String ATTR_USER_ID = "auth_userId";
    public static final String ATTR_SCOPE = "auth_scope";
    public static final String ATTR_AUTH_TYPE = "auth_type";
    public static final String ATTR_TOTP_VERIFIED = "auth_totpVerified";

    /** Sa-Token 终端扩展数据：登录时的 User-Agent。 */
    public static final String EXTRA_USER_AGENT = "user_agent";
    /** Sa-Token 终端扩展数据：本次会话是否通过动态码（或授信设备）验证。 */
    public static final String EXTRA_TOTP_VERIFIED = "totp_verified";

    private static final String BEARER_PREFIX = "Bearer ";
    /** last_used_at 写入节流：距上次使用超过该分钟数才写库。 */
    private static final long LAST_USED_THROTTLE_MINUTES = 5;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        boolean optional = OPTIONAL_AUTH_PATHS.contains(request.getRequestURI());
        // /api/me 允许匿名，其余端点进入前都要按所需权限校验
        RequiredAccess required = requiredAccess(handler, request);
        String authHeader = request.getHeader("Authorization");

        // 通道 1：API Token（Bearer）
        if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
            String rawToken = authHeader.substring(BEARER_PREFIX.length()).trim();
            if (!handleApiToken(request, rawToken, optional)) {
                // 可选认证路径上的无效凭证按匿名处理，不校验权限
                return true;
            }
            if (!optional) {
                RequiredAccess.require(request, required);
            }
            return true;
        }

        // 通道 2：Sa-Token 会话（Cookie / Header）
        if (optional) {
            applySessionIfPresent(request);
        } else {
            applySession(request);
        }
        if (!optional) {
            RequiredAccess.require(request, required);
        }
        return true;
    }

    /**
     * 解析端点声明的权限级别。
     * <p>
     * 优先使用 {@link RequireAccess} 注解；没有注解时按 HTTP 方法推断（读方法 READ，其余 WRITE），
     * 保证「按方法判断」只是兜底而不是唯一依据，GET 触发副作用的端点可以显式声明 WRITE。
     */
    private static RequiredAccess requiredAccess(Object handler, HttpServletRequest request) {
        if (handler instanceof HandlerMethod handlerMethod) {
            RequireAccess annotation = handlerMethod.getMethodAnnotation(RequireAccess.class);
            if (annotation == null) {
                annotation = handlerMethod.getBeanType().getAnnotation(RequireAccess.class);
            }
            if (annotation != null) {
                return annotation.value();
            }
        }
        return RequiredAccess.defaultForMethod(request.getMethod());
    }

    /** 强制校验会话，未登录时由 Sa-Token 抛出 401。 */
    private void applySession(HttpServletRequest request) {
        StpUtil.checkLogin();
        applySessionContext(request);
    }

    /** 尽力识别会话，未登录时保持匿名。 */
    private void applySessionIfPresent(HttpServletRequest request) {
        if (!StpUtil.isLogin()) {
            return;
        }
        applySessionContext(request);
    }

    private void applySessionContext(HttpServletRequest request) {
        String userId = StpUtil.getLoginIdAsString();
        request.setAttribute(ATTR_USER_ID, userId);
        request.setAttribute(ATTR_SCOPE, "read_write");
        request.setAttribute(ATTR_AUTH_TYPE, "session");
        SaTerminalInfo terminal = StpUtil.getTerminalInfo();
        request.setAttribute(
                ATTR_TOTP_VERIFIED, terminal != null && Boolean.TRUE.equals(terminal.getExtra(EXTRA_TOTP_VERIFIED)));
    }

    /**
     * 校验 API Token 并注入身份上下文。
     *
     * @param optional 为 {@code true} 时（如 {@code /api/me}），凭证无效按匿名处理而不是 401
     */
    private boolean handleApiToken(HttpServletRequest request, String rawToken, boolean optional) {
        String hash = ApiTokenUtil.hash(rawToken);
        Tokens token = tokensMapper.selectOne(new LambdaQueryWrapper<Tokens>().eq(Tokens::getTokenHash, hash));

        if (token == null || token.getRevokedAt() != null) {
            if (optional) {
                return true;
            }
            throw BizException.unauthorized("Token 无效或已撤销");
        }
        if (token.getExpiresAt() != null && token.getExpiresAt().isBefore(OffsetDateTime.now(clock))) {
            if (optional) {
                return true;
            }
            throw BizException.unauthorized("Token 已过期");
        }
        // 只读写权限判断统一由 RequiredAccess.require 完成（见 preHandle），这里只注入身份。
        // 尽力刷新 last_used_at：只在距上次使用超过 5 分钟时写库，避免每个请求一次全字段 UPDATE
        OffsetDateTime now = OffsetDateTime.now(clock);
        if (token.getLastUsedAt() == null
                || token.getLastUsedAt().isBefore(now.minusMinutes(LAST_USED_THROTTLE_MINUTES))) {
            try {
                Tokens patch = new Tokens();
                patch.setId(token.getId());
                patch.setLastUsedAt(now);
                tokensMapper.updateById(patch);
            } catch (RuntimeException e) {
                log.warn("刷新 API Token last_used_at 失败, tokenId={}", token.getId(), e);
            }
        }

        request.setAttribute(ATTR_USER_ID, token.getUserId());
        request.setAttribute(ATTR_SCOPE, token.getScope());
        request.setAttribute(ATTR_AUTH_TYPE, "token");
        request.setAttribute(ATTR_TOTP_VERIFIED, false);
        return true;
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
        RequiredAccess.require(request, RequiredAccess.SESSION);
    }

    /** 仅允许已通过动态码验证的浏览器会话访问。 */
    public static void requireSessionTotp(HttpServletRequest request) {
        RequiredAccess.require(request, RequiredAccess.SESSION_TOTP);
    }
}
