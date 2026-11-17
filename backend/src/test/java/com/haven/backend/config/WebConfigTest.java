package com.haven.backend.config;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.web.servlet.resource.PathResourceResolver;

/**
 * SPA 资源解析：回退 index.html 且不绕过 Spring 的路径归属校验。
 * <p>
 * 这里反射调用 protected 的 getResource，验证 API / 上传路径不回退、普通路由回退。
 */
class WebConfigTest {

    private final PathResourceResolver resolver = new WebConfig.SpaResourceResolver();

    private final Resource location = new PathMatchingResourcePatternResolver().getResource("classpath:/static/");

    @Test
    @DisplayName("普通前端路由回退 index.html")
    void spaRouteFallsBackToIndex() throws Exception {
        Resource resource = resolve("notes/123");

        assertNotNull(resource);
        assertTrue(read(resource).contains("haven-spa"));
    }

    @Test
    @DisplayName("API 路径不返回 index.html")
    void apiPathDoesNotFallBack() throws Exception {
        assertNull(resolve("api/unknown"));
    }

    @Test
    @DisplayName("上传路径不返回 index.html")
    void uploadsPathDoesNotFallBack() throws Exception {
        assertNull(resolve("uploads/unknown.png"));
    }

    @Test
    @DisplayName("路径穿越请求不会读到 classpath 外的文件，只回退到 SPA 入口")
    void pathTraversalIsRejected() throws Exception {
        // Spring 会先拦下 ../ 这类非法路径，不会落到真实文件；最多回退 index.html
        Resource resource = resolve("../../application.yaml");

        assertTrue(resource == null || read(resource).contains("haven-spa"));
    }

    private Resource resolve(String path) throws ReflectiveOperationException, IOException {
        var method = PathResourceResolver.class.getDeclaredMethod("getResource", String.class, Resource.class);
        method.setAccessible(true);
        return (Resource) method.invoke(resolver, path, location);
    }

    private String read(Resource resource) throws IOException {
        try (var in = resource.getInputStream()) {
            return new String(in.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
        }
    }
}
