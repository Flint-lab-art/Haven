package com.haven.backend.auth.interceptor;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 声明端点所需的权限级别，由 {@link AuthInterceptor} 在进入 Controller 前统一校验。
 * <p>
 * 不写注解时按 HTTP 方法兜底（GET/HEAD/OPTIONS 视为 READ，其余视为 WRITE）。
 * 当某个 GET 端点实际会写数据（同步、清理、导出落盘等）时，必须显式标注 {@code @RequireAccess(WRITE)}，
 * 否则只读 API Token 能通过它触发写操作。
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface RequireAccess {

    /** 所需权限级别。 */
    RequiredAccess value();
}
