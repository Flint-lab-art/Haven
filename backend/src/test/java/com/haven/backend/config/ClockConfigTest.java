package com.haven.backend.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 业务时钟：默认取 JVM 时区，配置了 haven.time-zone 时按配置时区。
 */
class ClockConfigTest {

    private final ClockConfig config = new ClockConfig();

    @Test
    @DisplayName("未配置时区时使用 JVM 默认时区")
    void defaultsToSystemZone() {
        Clock clock = config.clock("");

        assertEquals(ZoneId.systemDefault(), clock.getZone());
    }

    @Test
    @DisplayName("配置了合法时区时使用该时区")
    void usesConfiguredZone() {
        Clock clock = config.clock("Asia/Shanghai");

        assertEquals(ZoneId.of("Asia/Shanghai"), clock.getZone());
        assertTrue(Math.abs(clock.instant().toEpochMilli() - Instant.now().toEpochMilli()) < 5_000);
    }
}
