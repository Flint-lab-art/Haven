package com.haven.backend.support;

import java.util.List;
import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

/**
 * 在任何 Spring 上下文启动前准备测试数据库，并把连接信息注入环境。
 * <p>
 * 通过 {@code META-INF/spring.factories} 注册，因此 {@code @SpringBootTest}
 * 也会先经过这里；只有激活 {@code test} profile 时才生效。
 */
public class TestDatabaseInitializer implements EnvironmentPostProcessor {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        if (!isTestProfile(environment)) {
            return;
        }
        TestDatabaseSupport.ensurePrepared();

        // ensurePrepared 返回时连接信息一定已就绪；这里再兜一层，
        // 万一为空就给出可读的错误，而不是让 Map.of 抛一个没上下文的 NPE。
        String url = System.getProperty(TestDatabaseSupport.URL_PROPERTY);
        String user = System.getProperty(TestDatabaseSupport.USERNAME_PROPERTY);
        String password = System.getProperty(TestDatabaseSupport.PASSWORD_PROPERTY);
        if (url == null || url.isBlank()) {
            throw new IllegalStateException(
                    "测试数据库未就绪：ensurePrepared() 返回但 " + TestDatabaseSupport.URL_PROPERTY + " 仍为空");
        }

        environment
                .getPropertySources()
                .addFirst(new MapPropertySource(
                        "havenTestDatasource",
                        Map.of(
                                "spring.datasource.url", url,
                                "spring.datasource.username", user != null ? user : "",
                                "spring.datasource.password", password != null ? password : "")));
    }

    private boolean isTestProfile(ConfigurableEnvironment environment) {
        return List.of(environment.getActiveProfiles()).contains("test");
    }
}
