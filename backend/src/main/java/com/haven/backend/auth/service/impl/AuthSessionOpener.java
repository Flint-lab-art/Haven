package com.haven.backend.auth.service.impl;

import cn.dev33.satoken.stp.StpUtil;
import cn.dev33.satoken.stp.parameter.SaLoginParameter;
import com.haven.backend.audit.AuditEventType;
import com.haven.backend.audit.AuditRecorder;
import com.haven.backend.audit.AuditTargetType;
import com.haven.backend.auth.dto.LoginOutcome;
import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.dto.LoginTotpRequest;
import com.haven.backend.auth.dto.PasswordChangeRequest;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.util.ApiTokenUtil;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * HTTP 登录入口：把「凭据校验（事务内）」与「建立会话（事务外）」分开执行。
 * <p>
 * {@link AuthServiceImpl} 负责数据库读写；Sa-Token 会话、授信设备创建这类外部副作用放在这里，
 * 避免在事务中执行非数据库操作，也避免事务回滚后会话已经建立。
 */
@Service
@RequiredArgsConstructor
public class AuthSessionOpener {

    /** 待验证 TOTP 有效期：5 分钟。 */
    private static final long PENDING_TOTP_MINUTES = 5;

    private final AuthServiceImpl authService;
    private final Clock clock;
    private final AuditRecorder auditRecorder;

    /** 登录第一步：校验密码，按需写入待验证 TOTP 记录并建立会话。 */
    public LoginOutcome login(LoginRequest req, String ip, String ua, String trustedDeviceToken) {
        AuthServiceImpl.LoginPrecheck precheck = authService.loginPrecheck(req, ip, ua, trustedDeviceToken);
        if (precheck.totpRequired()) {
            String rawToken = UUID.randomUUID().toString().replace("-", "") + ":" + precheck.userId();
            authService.savePendingTotp(
                    precheck.userId(),
                    ApiTokenUtil.hash(rawToken),
                    ip,
                    ua,
                    precheck.trustDevice(),
                    OffsetDateTime.now(clock).plusMinutes(PENDING_TOTP_MINUTES));
            return new LoginOutcome(precheck.body().withTempToken(rawToken), null);
        }

        openSession(precheck.userId(), ua, true);
        auditRecorder.record(
                UUID.fromString(precheck.userId()),
                precheck.body().user().username(),
                AuditEventType.LOGIN_SUCCESS,
                AuditTargetType.USER,
                UUID.fromString(precheck.userId()),
                ip,
                ua);
        return new LoginOutcome(precheck.body(), null);
    }

    /** 登录第二步：校验动态码，作废临时记录并建立会话。 */
    public LoginOutcome loginTotp(LoginTotpRequest req, String ip, String ua) {
        AuthServiceImpl.TotpPrecheck precheck = authService.totpPrecheck(req);
        authService.consumePendingTotp(precheck.pendingId());

        String effectiveUa = ua != null && !ua.isBlank() ? ua : precheck.userAgent();
        openSession(precheck.userId(), effectiveUa, true);

        String rawDeviceToken =
                precheck.trustDevice() ? authService.createTrustedDevice(precheck.userId(), effectiveUa) : null;
        auditRecorder.record(
                UUID.fromString(precheck.userId()),
                precheck.body().user().username(),
                AuditEventType.LOGIN_SUCCESS,
                AuditTargetType.USER,
                UUID.fromString(precheck.userId()),
                ip,
                effectiveUa);
        return new LoginOutcome(precheck.body(), rawDeviceToken);
    }

    /**
     * 修改密码：数据库写入走事务，事务提交后再撤销该用户的全部 Sa-Token 会话。
     * <p>
     * 先提交再踢会话，避免事务回滚却已经把用户踢下线；即使踢会话失败，密码与 Token 也已失效。
     */
    public void changePassword(String userId, PasswordChangeRequest req, String ip, String ua) {
        authService.changePassword(userId, req, ip, ua);
        StpUtil.logout(userId);
        StpUtil.kickout(userId);
    }

    private void openSession(String userId, String userAgent, boolean totpVerified) {
        SaLoginParameter parameter = new SaLoginParameter()
                .setTerminalExtra(AuthInterceptor.EXTRA_USER_AGENT, userAgent != null ? userAgent : "")
                .setTerminalExtra(AuthInterceptor.EXTRA_TOTP_VERIFIED, totpVerified);
        StpUtil.login(userId, parameter);
    }
}
