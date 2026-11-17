package com.haven.backend.auth.service;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.mapper.PendingTotpMapper;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.auth.service.impl.AuthServiceImpl;
import com.haven.backend.exception.BizException;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * 登录失败限流：连续失败达到上限后返回 429，成功登录会重置计数。
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class LoginAttemptLimiterTest {
    /** 固定时钟：窗口判定不依赖真实时间。 */
    private static final Clock FIXED_CLOCK = Clock.fixed(Instant.parse("2026-01-02T03:04:05Z"), ZoneOffset.UTC);

    @Mock
    private UsersMapper usersMapper;

    @Mock
    private PendingTotpMapper pendingTotpMapper;

    @Mock
    private TrustedDeviceService trustedDeviceService;

    @Mock
    private ApiTokenService apiTokenService;

    @Mock
    private com.haven.backend.audit.AuditRecorder auditRecorder;

    private LoginAttemptLimiter limiter;
    private AuthServiceImpl authService;

    @BeforeEach
    void setUp() {
        limiter = new LoginAttemptLimiter(FIXED_CLOCK);
        ReflectionTestUtils.setField(limiter, "loginMaxAttempts", 3);
        ReflectionTestUtils.setField(limiter, "totpMaxAttempts", 3);
        ReflectionTestUtils.setField(limiter, "windowMinutes", 15L);
        authService = new AuthServiceImpl(
                usersMapper,
                pendingTotpMapper,
                trustedDeviceService,
                apiTokenService,
                limiter,
                FIXED_CLOCK,
                auditRecorder);
        ReflectionTestUtils.setField(authService, "totpIssuer", "Haven");
        when(usersMapper.selectOne(any())).thenReturn(null);
    }

    @Test
    @DisplayName("连续失败达到上限后返回 429")
    void tooManyFailuresReturns429() {
        LoginRequest req = loginRequest("alice", "wrong");

        for (int i = 0; i < 3; i++) {
            BizException ex = assertThrows(BizException.class, () -> authService.login(req, "1.1.1.1", "ua", null));
            assertEquals(401, ex.getCode());
        }

        BizException blocked = assertThrows(BizException.class, () -> authService.login(req, "1.1.1.1", "ua", null));
        assertEquals(429, blocked.getCode());
    }

    @Test
    @DisplayName("成功登录后计数被清空")
    void successfulLoginClearsCounter() {
        limiter.recordFailure(LoginAttemptLimiter.LOGIN_PREFIX + "bob");
        limiter.recordFailure(LoginAttemptLimiter.LOGIN_PREFIX + "bob");

        limiter.clear(LoginAttemptLimiter.LOGIN_PREFIX + "bob");

        assertDoesNotThrow(() -> limiter.requireLeft(LoginAttemptLimiter.LOGIN_PREFIX + "bob"));
        assertEquals(1, limiter.recordFailure(LoginAttemptLimiter.LOGIN_PREFIX + "bob"));
    }

    @Test
    @DisplayName("限流按账号隔离")
    void limitIsPerAccount() {
        LoginRequest alice = loginRequest("alice", "wrong");
        LoginRequest carol = loginRequest("carol", "wrong");
        for (int i = 0; i < 3; i++) {
            assertThrows(BizException.class, () -> authService.login(alice, "1.1.1.1", "ua", null));
        }
        // 另一个账号不受影响，仍然只是登录失败而不是被限流
        BizException ex = assertThrows(BizException.class, () -> authService.login(carol, "2.2.2.2", "ua", null));
        assertEquals(401, ex.getCode());
    }

    private LoginRequest loginRequest(String username, String password) {
        return new LoginRequest(username, password, false);
    }
}
