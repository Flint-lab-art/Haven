package com.haven.backend.auth.interceptor;

import com.haven.backend.exception.BizException;
import jakarta.servlet.http.HttpServletRequest;

/**
 * 要求的权限级别。
 * <p>
 * 比起「按 HTTP 方法判断是否写操作」，显式声明所需权限能覆盖 GET 触发副作用的场景
 * （例如同步、清理、导出），并且让只读 Token 的边界由接口语义决定而不是请求方法。
 */
public enum RequiredAccess {
    /** 读数据即可：GET/HEAD/OPTIONS 默认要求此项。 */
    READ,
    /** 写数据：新增、修改、删除，默认要求写权限。 */
    WRITE,
    /** 仅浏览器会话（API Token 不可用），例如会话管理、授信设备管理。 */
    SESSION,
    /** 浏览器会话且已通过动态码（或授信设备）验证，例如 API Token 管理与 TOTP 变更。 */
    SESSION_TOTP;

    /** 请求方法对应的默认权限：读方法 READ，其余 WRITE。 */
    public static RequiredAccess defaultForMethod(String method) {
        String normalized = method == null ? "" : method.toUpperCase();
        return switch (normalized) {
            case "GET", "HEAD", "OPTIONS" -> READ;
            default -> WRITE;
        };
    }

    /** 该级别是否要求 read_write Token / 已登录会话。 */
    public boolean requiresWrite() {
        return this == WRITE || this == SESSION || this == SESSION_TOTP;
    }

    /** 该级别是否要求浏览器会话。 */
    public boolean requiresSession() {
        return this == SESSION || this == SESSION_TOTP;
    }

    /** 该级别是否要求会话中已通过 TOTP。 */
    public boolean requiresTotp() {
        return this == SESSION_TOTP;
    }

    /**
     * 校验当前请求是否满足该级别，不满足时抛 401/403。
     * <p>
     * 供 Controller 显式声明端点权限；{@link AuthInterceptor} 也用同一套判断在拦截阶段兜底。
     */
    public static void require(HttpServletRequest request, RequiredAccess required) {
        AuthInterceptor.requireUserId(request);
        if (required.requiresSession() && !AuthInterceptor.isSession(request)) {
            throw BizException.forbidden("该操作仅支持浏览器会话，API Token 不可用");
        }
        if (required.requiresWrite() && !"read_write".equals(AuthInterceptor.getScope(request))) {
            throw BizException.forbidden("当前 Token 只读，无写权限");
        }
        if (required.requiresTotp() && !AuthInterceptor.isTotpVerified(request)) {
            throw BizException.forbidden("请先完成动态码验证后再执行该操作");
        }
    }
}
