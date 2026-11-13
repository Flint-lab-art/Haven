package com.haven.backend.config;

import com.haven.backend.typehandler.UuidTypeHandler;
import jakarta.annotation.PostConstruct;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.context.annotation.Configuration;

import java.util.UUID;

/**
 * MyBatis-Plus 配置：注册自定义 TypeHandler。
 * <p>
 * 将 UuidTypeHandler 全局注册到 MyBatis，
 * 使所有 Java UUID ↔ PostgreSQL uuid 的映射都走此 Handler。
 */
@Configuration
public class MybatisPlusConfig {

    private final SqlSessionFactory sqlSessionFactory;

    MybatisPlusConfig(SqlSessionFactory sqlSessionFactory) {
        this.sqlSessionFactory = sqlSessionFactory;
    }

    @PostConstruct
    public void registerTypeHandlers() {
        var typeHandlerRegistry = sqlSessionFactory.getConfiguration().getTypeHandlerRegistry();
        typeHandlerRegistry.register(UUID.class, new UuidTypeHandler());
    }
}
