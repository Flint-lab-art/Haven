package com.haven.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

import java.io.IOException;

/**
 * Web 配置：SPA 路由支持。
 * <p>
 * 前端使用 Vue/React 等 SPA 框架时，路由由前端管理。
 * 对于非 API、非静态资源的请求，返回 index.html，让前端路由接管。
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 静态资源处理
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/")
                .resourceChain(true)
                .addResolver(new PathResourceResolver() {
                    @Override
                    protected Resource getResource(String resourcePath, Resource location) throws IOException {
                        Resource requestedResource = location.createRelative(resourcePath);
                        
                        // 如果请求的资源存在，直接返回
                        if (requestedResource.exists() && requestedResource.isReadable()) {
                            return requestedResource;
                        }
                        
                        // 对于 API 路径，不返回 index.html
                        if (resourcePath.startsWith("api/") || resourcePath.startsWith("uploads/")) {
                            return null;
                        }
                        
                        // 其他情况返回 index.html（SPA 路由回退）
                        return new ClassPathResource("/static/index.html");
                    }
                });
    }
}
