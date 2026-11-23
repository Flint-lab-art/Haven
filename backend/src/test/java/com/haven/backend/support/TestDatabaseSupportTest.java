package com.haven.backend.support;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 测试数据库引导的契约：
 * <ul>
 *   <li>不能静默回落到开发库；</li>
 *   <li>用的是独立测试库，不是临时 schema —— V16 起模块 schema（note/issue/ledger）不能嵌套在临时 schema 里；</li>
 *   <li>测试库里 pg_trgm 装在 public，迁移里的 gin_trgm_ops 才能解析。</li>
 * </ul>
 */
class TestDatabaseSupportTest {

    @Test
    @DisplayName("指向独立测试库，而不是开发库")
    void targetsIsolatedDatabase() {
        TestDatabaseSupport.ensurePrepared();

        String url = System.getProperty(TestDatabaseSupport.URL_PROPERTY);
        assertNotNull(url, "测试库 URL 未写入系统属性");
        assertTrue(url.contains("haven_test_db") || url.contains("testcontainers"), "必须使用独立的测试库，不能是 dev_db: " + url);
        assertFalse(url.endsWith("/dev_db"), "测试不能直接跑在开发库上: " + url);
    }

    @Test
    @DisplayName("不再用 search_path / currentSchema 切 schema（模块 schema 无法嵌套）")
    void doesNotSwitchSchemaViaUrl() {
        TestDatabaseSupport.ensurePrepared();

        String url = System.getProperty(TestDatabaseSupport.URL_PROPERTY);
        assertFalse(url.contains("currentSchema="), "currentSchema 会覆盖 search_path: " + url);
        assertFalse(url.contains("search_path"), "测试库是独立数据库，不需要再靠 search_path 隔离 schema: " + url);
    }

    @Test
    @DisplayName("测试库里 pg_trgm 装在 public")
    void hasTrgmInPublic() throws SQLException {
        TestDatabaseSupport.ensurePrepared();

        String url = System.getProperty(TestDatabaseSupport.URL_PROPERTY);
        String user = System.getProperty(TestDatabaseSupport.USERNAME_PROPERTY);
        String password = System.getProperty(TestDatabaseSupport.PASSWORD_PROPERTY);

        try (Connection connection = DriverManager.getConnection(url, user, password);
                var statement = connection.createStatement();
                ResultSet rs = statement.executeQuery("SELECT n.nspname FROM pg_extension e "
                        + "JOIN pg_namespace n ON n.oid = e.extnamespace WHERE e.extname = 'pg_trgm'")) {
            assertTrue(rs.next(), "测试库缺少 pg_trgm 扩展");
            assertTrue("public".equals(rs.getString(1)), "pg_trgm 必须装在 public，实际在: " + rs.getString(1));
        }
    }
}
