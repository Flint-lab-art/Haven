package com.haven.backend.support;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 测试数据库引导的契约：
 * <ul>
 *   <li>不能静默回落到开发库；</li>
 *   <li>URL 里必须显式指定 search_path，否则 pg_trgm 的 operator class 解析不到；</li>
 *   <li>不能设置 currentSchema（它会覆盖 search_path）。</li>
 * </ul>
 */
class TestDatabaseSupportTest {

    @Test
    @DisplayName("准备的连接串带 search_path，且不覆盖 currentSchema")
    void preparedUrlKeepsPublicInSearchPath() {
        TestDatabaseSupport.ensurePrepared();

        String url = System.getProperty(TestDatabaseSupport.URL_PROPERTY);
        assertNotNull(url, "测试库 URL 未写入系统属性");
        assertFalse(url.contains("currentSchema="), "currentSchema 会覆盖 search_path，导致 pg_trgm 找不到");
        assertTrue(url.contains("search_path%3D"), "必须显式指定 search_path: " + url);
        assertTrue(url.contains("%2Cpublic"), "search_path 必须包含 public: " + url);
    }

    @Test
    @DisplayName("目标不是开发库本身，而是隔离出的 schema")
    void targetsIsolatedSchema() {
        TestDatabaseSupport.ensurePrepared();

        String url = System.getProperty(TestDatabaseSupport.URL_PROPERTY);
        assertTrue(url.contains("haven_test_") || url.contains("testcontainers"), "必须使用隔离库: " + url);
    }
}
