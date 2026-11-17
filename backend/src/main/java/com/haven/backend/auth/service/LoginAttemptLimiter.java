package com.haven.backend.auth.service;

import com.haven.backend.exception.BizException;
import java.time.OffsetDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * 登录 / 动态码失败尝试限流。
 * <p>
 * 按「账号」或「待验证 TOTP 会话」在固定时间窗口内计数，超过上限后返回 429，
 * 防止密码与 6 位动态码被暴力枚举。
 * <p>
 * 当前实现是<b>单实例内存计数</b>：多实例部署需要替换为 Redis 等共享存储，
 * 否则每个实例独立计数会把有效上限放大为「实例数 × 上限」。
 */
@Component
public class LoginAttemptLimiter {

    /** 登录（密码）失败的计数键前缀。 */
    public static final String LOGIN_PREFIX = "login:user:";
    /** 第二步动态码失败的计数键前缀。 */
    public static final String TOTP_PREFIX = "login-totp:";

    /** 同一账号在窗口内允许的密码失败次数。 */
    @Value("${haven.auth.login-max-attempts:5}")
    private int loginMaxAttempts;

    /** 失败计数窗口（分钟）。 */
    @Value("${haven.auth.login-window-minutes:15}")
    private long windowMinutes;

    /** 同一个待验证 TOTP 会话允许的动态码失败次数。 */
    @Value("${haven.auth.totp-max-attempts:5}")
    private int totpMaxAttempts;

    private final Map<String, Window> windows = new ConcurrentHashMap<>();
    private final java.time.Clock clock;

    /** 显式构造器：类中存在 {@code @Value} 字段，不能依赖 Lombok 生成构造器。 */
    public LoginAttemptLimiter(java.time.Clock clock) {
        this.clock = clock;
    }

    /** 窗口内累计失败次数与重置时间。 */
    private record Window(int count, OffsetDateTime resetAt) {}

    /** 超出上限时拒绝继续尝试。 */
    public void requireLeft(String key) {
        Window w = windows.get(key);
        if (w != null && w.resetAt().isAfter(OffsetDateTime.now(clock)) && w.count() >= maxAttemptsFor(key)) {
            throw new BizException(429, "尝试次数过多，请稍后再试");
        }
    }

    /** 记录一次失败，返回窗口内累计次数。 */
    public int recordFailure(String key) {
        OffsetDateTime now = OffsetDateTime.now(clock);
        Window w = windows.compute(key, (k, old) -> {
            if (old == null || !old.resetAt().isAfter(now)) {
                return new Window(1, now.plusMinutes(windowMinutes));
            }
            return new Window(old.count() + 1, old.resetAt());
        });
        return w.count();
    }

    /** 成功后清除计数。 */
    public void clear(String key) {
        windows.remove(key);
    }

    /** 动态码失败上限，供调用方判断是否需要作废临时令牌。 */
    public int totpMaxAttempts() {
        return totpMaxAttempts;
    }

    private int maxAttemptsFor(String key) {
        return key.startsWith(TOTP_PREFIX) ? totpMaxAttempts : loginMaxAttempts;
    }
}
