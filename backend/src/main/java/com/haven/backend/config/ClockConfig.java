package com.haven.backend.config;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 统一时间源。
 * <p>
 * 业务代码注入 {@link Clock} 而不是直接调 {@code OffsetDateTime.now()}：
 * 测试可以替换成固定时钟，部署时可以通过 {@code haven.time-zone} 指定业务时区。
 */
@Configuration
public class ClockConfig {

    /**
     * 业务时钟。
     *
     * @param zoneId IANA 时区名（如 {@code Asia/Shanghai}），默认取 JVM 时区
     */
    @Bean
    @ConditionalOnMissingBean(Clock.class)
    public Clock clock(@Value("${haven.time-zone:}") String zoneId) {
        ZoneId zone = zoneId == null || zoneId.isBlank() ? ZoneId.systemDefault() : ZoneId.of(zoneId);
        return Clock.system(zone);
    }
}
