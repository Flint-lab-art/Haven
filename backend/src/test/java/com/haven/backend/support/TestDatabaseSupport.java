package com.haven.backend.support;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
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
 * 为什么用<b>独立测试库</b>而不是临时 schema：
 * V16 起业务表按模块分在 {@code note} / {@code issue} / {@code ledger} 三个 schema，
 * 而 PostgreSQL 的 schema 不能嵌套——临时 schema 里无法再建 module schema，
 * 迁移里的 {@code CREATE SCHEMA note} 会直接落到库顶层、污染开发库。
 * 因此改成每轮重建一个独立数据库，迁移路径与生产完全一致。
 * <p>
 * 策略：
 * <ol>
 *   <li>显式要求容器（{@code -Dhaven.test.mode=container}）且容器可用 → 启容器；</li>
 *   <li>否则连同一 PostgreSQL 实例，<b>DROP + CREATE</b> 一个独立数据库（默认 {@code haven_test_db}）；</li>
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
    /**
     * 是否已经有线程在做初始化。
     *
     * 不能用「init 完就返回」的做法：别的 Spring 上下文会立刻用这份连接信息去查表，
     * 而此时 Flyway 可能还没把这个上下文需要的表建完，表现为偶发的
     * 「relation "users" does not exist」。
     * 所以这里只在第一个线程里建库，其余线程等它完成后直接复用。
     */
    private static volatile boolean initialized = false;

    /** 初始化完成后的连接信息（供后来者直接复用）。 */
    private static volatile String preparedUrl;

    private static volatile String preparedUser;
    private static volatile String preparedPassword;
    /** 测试专用数据库名，每轮重建。 */
    private static final String TEST_DB = System.getenv().getOrDefault("TEST_DB_NAME", "haven_test_db");

    private TestDatabaseSupport() {}

    /**
     * 幂等地准备测试数据库，并把连接信息写入系统属性。
     * <p>
     * 由 {@code TestDatabaseInitializer} 在 Spring 上下文启动前调用。
     */
    public static synchronized void ensurePrepared() {
        if (initialized) {
            // 后来者：把已有的连接信息重新写回系统属性（可能被别的上下文覆盖过）
            republish();
            return;
        }
        if (MODE_CONTAINER.equalsIgnoreCase(System.getProperty(MODE_PROPERTY, ""))) {
            try {
                prepareTestcontainers();
                initialized = true;
                return;
            } catch (RuntimeException e) {
                log.warn("Testcontainers 不可用，改用独立测试库：{}", e.getMessage());
            }
        }
        prepareIsolatedDatabase();
        initialized = true;
    }

    /** 把已准备好的连接信息写回系统属性。 */
    private static void republish() {
        if (preparedUrl == null) {
            return;
        }
        System.setProperty(URL_PROPERTY, preparedUrl);
        System.setProperty(USERNAME_PROPERTY, preparedUser);
        System.setProperty(PASSWORD_PROPERTY, preparedPassword);
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
     * 在同一 PostgreSQL 实例里重建一个独立测试数据库。
     * <p>
     * 先连维护库（{@code postgres}，回退到 {@code dev_db}）执行 DROP / CREATE，
     * 再用新库跑迁移。数据库名固定，避免遗留库越攒越多。
     */
    private static void prepareIsolatedDatabase() {
        String user = System.getenv().getOrDefault("TEST_DB_USERNAME", System.getProperty(USERNAME_PROPERTY, "dev"));
        String password =
                System.getenv().getOrDefault("TEST_DB_PASSWORD", System.getProperty(PASSWORD_PROPERTY, "123456"));

        String targetUrl = databaseUrl(TEST_DB);
        SQLException lastError = null;

        for (String adminUrl : adminUrls()) {
            try (Connection connection = DriverManager.getConnection(adminUrl, user, password);
                    Statement statement = connection.createStatement()) {
                /*
                 * 已经建好并且迁移过的库直接复用，不重建。
                 *
                 * 重建时必须先 pg_terminate_backend，这会掐断所有在用连接；
                 * 如果某个测试上下文已经连着这个库，就会看到
                 * 「terminating connection due to administrator command」并整片失败。
                 * 同一轮测试里库只需建一次，之后的调用一律复用。
                 */
                if (hasMigratedTables(statement)) {
                    log.debug("测试库 {} 已就绪，复用", TEST_DB);
                    ensureExtension(targetUrl, user, password);
                    publish(targetUrl, user, password, "独立测试库 " + TEST_DB + "（复用）");
                    return;
                }
                statement.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity " + "WHERE datname = '"
                        + TEST_DB + "' AND pid <> pg_backend_pid()");
                statement.execute("DROP DATABASE IF EXISTS " + TEST_DB);
                statement.execute("CREATE DATABASE " + TEST_DB);
            } catch (SQLException e) {
                lastError = e;
                log.debug("跳过维护库 {}：{}", adminUrl, e.getMessage());
                continue;
            }
            // 扩展要装在测试库自己的 public 里，迁移里的 CREATE EXTENSION 才会是幂等空操作
            try {
                ensureExtension(targetUrl, user, password);
            } catch (SQLException e) {
                lastError = e;
                log.debug("初始化测试库扩展失败：{}", e.getMessage());
                continue;
            }
            publish(targetUrl, user, password, "独立测试库 " + TEST_DB);
            return;
        }

        throw new IllegalStateException(
                "无法准备测试数据库。请二选一："
                        + "\n  1) 启动 Docker 后用 -Dhaven.test.mode=container 跑容器化 PostgreSQL；"
                        + "\n  2) 让测试账号拥有 CREATEDB 权限（ALTER ROLE <user> CREATEDB），"
                        + "或用 TEST_DB_URL/TEST_DB_USERNAME/TEST_DB_PASSWORD 指向可建库的实例。"
                        + "\n维护库已尝试：" + adminUrls(),
                lastError);
    }

    /**
     * 测试库是否已经建好并跑过迁移。
     *
     * 看 {@code public.users}：V1 建的第一张表，它在就说明 Flyway 至少跑到了 V1。
     */
    private static boolean hasMigratedTables(Statement admin) throws SQLException {
        try (ResultSet rs = admin.executeQuery("SELECT 1 FROM pg_database WHERE datname = '" + TEST_DB + "'")) {
            if (!rs.next()) {
                return false;
            }
        }
        // 再连到目标库确认 users 表在（库存在但没迁移过时它不在）
        String user = System.getenv().getOrDefault("TEST_DB_USERNAME", System.getProperty(USERNAME_PROPERTY, "dev"));
        String password =
                System.getenv().getOrDefault("TEST_DB_PASSWORD", System.getProperty(PASSWORD_PROPERTY, "123456"));
        try (Connection connection = DriverManager.getConnection(databaseUrl(TEST_DB), user, password);
                Statement statement = connection.createStatement();
                ResultSet rs = statement.executeQuery("SELECT 1 FROM information_schema.tables "
                        + "WHERE table_schema = 'public' AND table_name = 'users'")) {
            return rs.next();
        } catch (SQLException e) {
            // 库不存在或连不上：当作没准备好
            return false;
        }
    }

    /** 确保 pg_trgm 装在测试库的 public 里。 */
    private static void ensureExtension(String url, String user, String password) throws SQLException {
        try (Connection connection = DriverManager.getConnection(url, user, password);
                Statement statement = connection.createStatement()) {
            statement.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public");
        }
    }

    /** 维护连接：优先 postgres 库，其次 dev_db。 */
    private static List<String> adminUrls() {
        String host = System.getenv().getOrDefault("TEST_DB_HOST", "127.0.0.1");
        String port = System.getenv().getOrDefault("TEST_DB_PORT", "5432");
        return List.of(
                "jdbc:postgresql://" + host + ":" + port + "/postgres",
                "jdbc:postgresql://" + host + ":" + port + "/dev_db");
    }

    /** 目标测试库的 JDBC URL，可由 TEST_DB_URL 整体覆盖。 */
    private static String databaseUrl(String database) {
        String explicit = System.getenv("TEST_DB_URL");
        if (explicit != null && !explicit.isBlank()) {
            return explicit;
        }
        String host = System.getenv().getOrDefault("TEST_DB_HOST", "127.0.0.1");
        String port = System.getenv().getOrDefault("TEST_DB_PORT", "5432");
        return "jdbc:postgresql://" + host + ":" + port + "/" + database;
    }

    private static void publish(String url, String user, String password, String mode) {
        preparedUrl = url;
        preparedUser = user;
        preparedPassword = password;
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
