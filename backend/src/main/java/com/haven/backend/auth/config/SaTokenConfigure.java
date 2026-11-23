package com.haven.backend.auth.config;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 拦截器注册。
 * <p>
 * AuthInterceptor 覆盖 /api/**，对需要认证的路走 Session + API Token 双通道；
 * 匿名端点（健康检查、登录两步、版本号占位）用 excludePathPatterns 放行。
 * <p>
 * {@code /api/me} 不走排除列表：它由拦截器按「可选认证」处理，以便带 API Token 的请求也能识别身份。
 */
@Configuration
@RequiredArgsConstructor
public class SaTokenConfigure implements WebMvcConfigurer {

    private final AuthInterceptor authInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(
                        // 健康检查
                        "/api/health",
                        // 登录两步（无需认证）
                        "/api/auth/login",
                        "/api/auth/login/totp",
                        // 运行时前端配置：只返回版本号，不含任何域名/环境变量
                        "/api/app-config");
    }
}
