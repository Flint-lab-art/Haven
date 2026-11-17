package com.haven.backend.config;

import java.io.IOException;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

/**
 * Web 配置：SPA 路由支持。
 * <p>
 * 前端使用 Vue 等 SPA 框架时，路由由前端管理：
 * 静态资源存在就返回，非 API / 非上传路径回退到 index.html。
 * <p>
 * 解析时先调用 {@code super.getResource}，保留 Spring 自带的路径归属校验
 * （{@code isResourceUnderLocation} 等），避免自定义实现绕过防护。
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    private static final String INDEX_HTML = "/static/index.html";

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/")
                .resourceChain(true)
                .addResolver(new SpaResourceResolver());
    }

    /** 先走 Spring 的默认解析（含安全校验），未命中再回退 index.html。 */
    static final class SpaResourceResolver extends PathResourceResolver {

        @Override
        protected Resource getResource(String resourcePath, Resource location) throws IOException {
            // API 与上传目录不做 SPA 回退，保持 404 语义
            if (resourcePath.startsWith("api/") || resourcePath.startsWith("uploads/")) {
                return null;
            }
            Resource found = super.getResource(resourcePath, location);
            if (found != null) {
                return found;
            }
            Resource index = new ClassPathResource(INDEX_HTML);
            return index.exists() ? index : null;
        }
    }
}
