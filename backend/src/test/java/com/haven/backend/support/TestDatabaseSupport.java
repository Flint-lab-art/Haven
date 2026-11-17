package com.haven.backend.support;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 测试数据库引导：给整轮测试准备一个干净、隔离的数据库。
 * <p>
 * 为什么不用 dev_db：
 * <ul>
 *   <li>测试之间会互相污染，且 Flyway 版本号会被测试数据"占住"；</li>
 *   <li>误执行 {@code flyway:clean} 会清掉本地开发数据。</li>
 * </ul>
 * <p>
 * 为什么默认不直接上 Testcontainers：很多开发机没有 Docker 守护进程，
 * 让单元测试因此跑不起来是很差的体验。这里的策略是：
 * <ol>
 *   <li>显式要求容器（{@code -Dhaven.test.mode=container}）且容器可用 → 启容器；</li>
 *   <li>否则在同一 PostgreSQL 实例里创建一个<b>临时 schema</b>，测试结束不清理也无妨（schema 名带随机后缀）；</li>
 *   <li>两者都不可用 → 抛带修复指引的异常，而不是静默回落到开发库。</li>
 * </ol>
 * 系统属性 {@link #URL_PROPERTY} / {@link #USERNAME_PROPERTY} / {@link #PASSWORD_PROPERTY}
 * 会被写入，Spring 配置通过它们覆盖数据源。
 */
public final class TestDatabaseSupport {

    /** 指向测试库（或临时 schema）的 JDBC URL。 */
    public static final String URL_PROPERTY = "haven.test.datasource.url";
    /** 测试库用户名。 */
    public static final String USERNAME_PROPERTY = "haven.test.datasource.username";
    /** 测试库口令。 */
    public static final String PASSWORD_PROPERTY = "haven.test.datasource.password";

    private static final String MODE_PROPERTY = "haven.test.mode";
    private static final String MODE_CONTAINER = "container";

    private static final Logger log = LoggerFactory.getLogger(TestDatabaseSupport.class);
    private static final AtomicBoolean INITIALIZED = new AtomicBoolean(false);
    /** 本轮创建出来的临时 schema，JVM 退出时统一清理。 */
    private static final List<String> CREATED_SCHEMAS = new java.util.concurrent.CopyOnWriteArrayList<>();
    /** 临时 schema 的前缀，用于清理历史残留。 */
    private static final String SCHEMA_PREFIX = "haven_test_";

    private TestDatabaseSupport() {}

    /**
     * 幂等地准备测试数据库，并把连接信息写入系统属性。
     * <p>
     * 由 {@code TestDatabaseInitializer} 在 Spring 上下文启动前调用。
     */
    public static void ensurePrepared() {
        if (!INITIALIZED.compareAndSet(false, true)) {
            return;
        }
        if (MODE_CONTAINER.equalsIgnoreCase(System.getProperty(MODE_PROPERTY, ""))) {
            try {
                prepareTestcontainers();
                return;
            } catch (RuntimeException e) {
                log.warn("Testcontainers 不可用，回退到临时 schema：{}", e.getMessage());
            }
        }
        prepareIsolatedSchema();
    }

    /** 用 Testcontainers 启动一次性 PostgreSQL。 */
    private static void prepareTestcontainers() {
        try {
            var postgres = new org.testcontainers.containers.PostgreSQLContainer<>("postgres:16-alpine");
            postgres.start();
            Runtime.getRuntime().addShutdownHook(new Thread(postgres::stop));
            publish(postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword(), "testcontainers");
        } catch (NoClassDefFoundError e) {
            throw new IllegalStateException("类路径缺少 testcontainers 依赖", e);
        }
    }

    /**
     * 在同一 PostgreSQL 实例里开一个临时 schema。
     * <p>
     * 依次尝试候选数据库（默认 {@code dev_db}，其次 {@code postgres}），
     * 只要当前账号能建 schema 即可，无需额外准备实例。
     */
    private static void prepareIsolatedSchema() {
        String user = System.getenv().getOrDefault("TEST_DB_USERNAME", System.getProperty(USERNAME_PROPERTY, "dev"));
        String password =
                System.getenv().getOrDefault("TEST_DB_PASSWORD", System.getProperty(PASSWORD_PROPERTY, "123456"));
        List<String> candidates = candidateUrls();
        SQLException lastError = null;

        for (String baseUrl : candidates) {
            String schema = "haven_test_"
                    + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
            try (Connection connection = DriverManager.getConnection(baseUrl, user, password);
                    Statement statement = connection.createStatement()) {
                dropStaleSchemas(statement, schema);
                statement.execute("CREATE SCHEMA " + schema);
                // 扩展装在 public，迁移里的 CREATE EXTENSION IF NOT EXISTS 才会是幂等的空操作；
                // 同时把 search_path 指到临时 schema，保证建表落在隔离空间里。
                statement.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public");
                CREATED_SCHEMAS.add(schema);
                publish(withSchema(baseUrl, schema), user, password, "临时 schema " + schema);
                return;
            } catch (SQLException e) {
                lastError = e;
                log.debug("跳过候选测试库 {}：{}", baseUrl, e.getMessage());
            }
        }
        throw new IllegalStateException(
                "无法准备测试数据库。请二选一："
                        + "\n  1) 启动 Docker 后用 -Dhaven.test.mode=container 跑容器化 PostgreSQL；"
                        + "\n  2) 用 TEST_DB_URL/TEST_DB_USERNAME/TEST_DB_PASSWORD 指定一个当前账号有建 schema 权限的库。"
                        + "\n已尝试：" + candidates,
                lastError);
    }

    /** 清理上一次异常退出遗留的临时 schema，避免实例里越攒越多。 */
    private static void dropStaleSchemas(Statement statement, String keep) {
        try (ResultSet rs = statement.executeQuery(
                "SELECT nspname FROM pg_namespace WHERE nspname LIKE '" + SCHEMA_PREFIX + "%'")) {
            List<String> stale = new java.util.ArrayList<>();
            while (rs.next()) {
                String name = rs.getString(1);
                if (!name.equals(keep)) {
                    stale.add(name);
                }
            }
            for (String name : stale) {
                statement.execute("DROP SCHEMA IF EXISTS " + name + " CASCADE");
                log.debug("清理遗留测试 schema：{}", name);
            }
        } catch (SQLException e) {
            // 没有权限清理也无所谓，不影响本轮测试
            log.debug("清理遗留测试 schema 失败：{}", e.getMessage());
        }
    }

    /** JVM 退出时删除本轮创建的 schema。 */
    private static void registerCleanup(String url, String user, String password) {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            if (CREATED_SCHEMAS.isEmpty()) {
                return;
            }
            try (Connection connection = DriverManager.getConnection(url, user, password);
                    Statement statement = connection.createStatement()) {
                for (String schema : CREATED_SCHEMAS) {
                    statement.execute("DROP SCHEMA IF EXISTS " + schema + " CASCADE");
                }
                log.info("已清理 {} 个临时测试 schema", CREATED_SCHEMAS.size());
            } catch (SQLException e) {
                log.warn("清理临时测试 schema 失败：{}", e.getMessage());
            }
        }));
    }

    /** 候选数据库：显式配置优先，其余为本地常见默认库。 */
    private static List<String> candidateUrls() {
        String explicitUrl = System.getenv("TEST_DB_URL");
        if (explicitUrl == null || explicitUrl.isBlank()) {
            explicitUrl = System.getProperty(URL_PROPERTY);
        }
        if (explicitUrl != null && !explicitUrl.isBlank()) {
            return List.of(explicitUrl);
        }
        return List.of("jdbc:postgresql://127.0.0.1:5432/dev_db", "jdbc:postgresql://127.0.0.1:5432/postgres");
    }

    /**
     * 把 schema 编码进 JDBC URL。
     * <p>
     * {@code currentSchema} 决定建表位置；{@code search_path} 额外带上 public，
     * 让 {@code gin_trgm_ops} 等扩展提供的 operator class 可被解析。
     */
    private static String withSchema(String url, String schema) {
        String separator = url.contains("?") ? "&" : "?";
        // 只设置 search_path，不用 currentSchema：pgjdbc 会把 currentSchema 写进 options，
        // 从而覆盖 search_path 并丢掉 public，导致 gin_trgm_ops 等扩展 operator class 解析失败。
        // search_path 首项就是临时 schema，建表仍然落在隔离空间里。
        return url + separator + "options=-c%20search_path%3D" + schema + "%2Cpublic";
    }

    private static void publish(String url, String user, String password, String mode) {
        registerCleanup(url, user, password);
        System.setProperty(URL_PROPERTY, url);
        System.setProperty(USERNAME_PROPERTY, user);
        System.setProperty(PASSWORD_PROPERTY, password);
        log.info("测试数据库已就绪（{}）：{}", mode, url);
    }

    /** 测试用：确认连接可用（仅用于自检，不会修改数据）。 */
    static boolean ping(String url, String user, String password) {
        try (Connection connection = DriverManager.getConnection(url, user, password);
                Statement statement = connection.createStatement();
                ResultSet rs = statement.executeQuery("SELECT 1")) {
            rs.next();
            return true;
        } catch (SQLException e) {
            return false;
        }
    }
}
