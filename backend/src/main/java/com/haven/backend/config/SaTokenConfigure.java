package com.haven.backend.config;

import com.haven.backend.interceptor.AuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 拦截器注册。
 * <p>
 * AuthInterceptor 覆盖 /api/**，对需要认证的路走 Session + API Token 双通道；
 * 公开路由 excludePathPatterns 放行。
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
                        // 当前身份（匿名也返回结果）
                        "/api/me",
                        // 运行时前端配置（决定当前域名是公开域还是私有域）
                        "/api/app-config",
                        // 公开侧接口
                        "/api/public/**"
                );
    }
}
