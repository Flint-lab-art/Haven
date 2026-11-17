package com.haven.backend.auth.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.mapper.PendingTotpMapper;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.auth.service.ApiTokenService;
import com.haven.backend.auth.service.LoginAttemptLimiter;
import com.haven.backend.auth.service.TrustedDeviceService;
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
 * 登录预检：凭证校验与待验证记录落库分离，登录入口不再在事务里建立会话。
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AuthServiceImplTest {
    /** 固定时钟：登录有效期等断言不依赖真实时间。 */
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

    @Mock
    private LoginAttemptLimiter attemptLimiter;

    private AuthServiceImpl authService;

    @BeforeEach
    void setUp() {
        authService = new AuthServiceImpl(
                usersMapper,
                pendingTotpMapper,
                trustedDeviceService,
                apiTokenService,
                attemptLimiter,
                FIXED_CLOCK,
                auditRecorder);
        ReflectionTestUtils.setField(authService, "totpIssuer", "Haven");
        when(attemptLimiter.totpMaxAttempts()).thenReturn(5);
    }

    @Test
    @DisplayName("未启用 TOTP 的账号登录后不需要第二步")
    void loginWithoutTotpDoesNotRequireSecondStep() {
        Users user = user(false);
        when(usersMapper.selectOne(any())).thenReturn(user);

        AuthServiceImpl.LoginPrecheck precheck =
                authService.loginPrecheck(loginRequest(user.getUsername(), "password"), "1.1.1.1", "ua", null);

        assertEquals(false, precheck.totpRequired());
        assertEquals(user.getId().toString(), precheck.userId());
        verify(pendingTotpMapper, never()).insert(any(com.haven.backend.auth.entity.PendingTotp.class));
    }

    @Test
    @DisplayName("启用 TOTP 且设备未授信时要求第二步")
    void loginWithTotpRequiresSecondStep() {
        Users user = user(true);
        when(usersMapper.selectOne(any())).thenReturn(user);
        when(trustedDeviceService.isTrusted(any(), any())).thenReturn(false);

        AuthServiceImpl.LoginPrecheck precheck =
                authService.loginPrecheck(loginRequest(user.getUsername(), "password"), "1.1.1.1", "ua", null);

        assertEquals(true, precheck.totpRequired());
    }

    @Test
    @DisplayName("密码错误抛 401 并记录一次失败")
    void wrongPasswordIsUnauthorized() {
        Users user = user(false);
        when(usersMapper.selectOne(any())).thenReturn(user);

        BizException ex = assertThrows(
                BizException.class,
                () -> authService.loginPrecheck(loginRequest(user.getUsername(), "wrong"), "1.1.1.1", "ua", null));

        assertEquals(401, ex.getCode());
        verify(attemptLimiter).recordFailure(any());
    }

    @Test
    @DisplayName("登录成功后返回的 body 不含临时令牌（由入口层补充）")
    void precheckBodyHasNoTempToken() {
        Users user = user(true);
        when(usersMapper.selectOne(any())).thenReturn(user);
        when(trustedDeviceService.isTrusted(any(), any())).thenReturn(false);

        AuthServiceImpl.LoginPrecheck precheck =
                authService.loginPrecheck(loginRequest(user.getUsername(), "password"), "1.1.1.1", "ua", null);

        assertNull(precheck.body().tempToken());
        assertEquals(true, precheck.body().totpRequired());
    }

    private Users user(boolean totpEnabled) {
        Users user = new Users();
        user.setId(java.util.UUID.randomUUID());
        user.setUsername("alice");
        user.setPasswordHash(fixtureHash());
        user.setTotpEnabled(totpEnabled);
        return user;
    }

    /** 生成一个固定的 BCrypt 哈希，避免测试里重复计算。 */
    private String fixtureHash() {
        return at.favre.lib.crypto.bcrypt.BCrypt.withDefaults().hashToString(4, "password".toCharArray());
    }

    private LoginRequest loginRequest(String username, String password) {
        return new LoginRequest(username, password, false);
    }
}
