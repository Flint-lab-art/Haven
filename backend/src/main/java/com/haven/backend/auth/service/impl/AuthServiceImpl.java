package com.haven.backend.auth.service.impl;

import at.favre.lib.crypto.bcrypt.BCrypt;
import cn.dev33.satoken.stp.StpUtil;
import cn.dev33.satoken.stp.parameter.SaLoginParameter;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.audit.AuditEventType;
import com.haven.backend.audit.AuditRecorder;
import com.haven.backend.audit.AuditTargetType;
import com.haven.backend.auth.dto.AuthDtos.LoginResponse;
import com.haven.backend.auth.dto.AuthDtos.MeResponse;
import com.haven.backend.auth.dto.AuthDtos.MeUser;
import com.haven.backend.auth.dto.AuthDtos.TotpSetupResponse;
import com.haven.backend.auth.dto.AuthDtos.UserBrief;
import com.haven.backend.auth.dto.LoginOutcome;
import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.dto.LoginTotpRequest;
import com.haven.backend.auth.dto.PasswordChangeRequest;
import com.haven.backend.auth.dto.TotpDisableRequest;
import com.haven.backend.auth.dto.TotpVerifyRequest;
import com.haven.backend.auth.entity.PendingTotp;
import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.mapper.PendingTotpMapper;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.auth.service.ApiTokenService;
import com.haven.backend.auth.service.AuthService;
import com.haven.backend.auth.service.LoginAttemptLimiter;
import com.haven.backend.auth.service.TrustedDeviceService;
import com.haven.backend.auth.util.ApiTokenUtil;
import com.haven.backend.auth.util.TotpUtil;
import com.haven.backend.exception.BizException;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.Locale;
import java.util.UUID;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 认证服务实现。
 * <p>
 * 会话管理委托 Sa-Token；TOTP 使用自实现工具类；
 * 密码哈希使用 BCrypt（cost=12，与 Go 端一致）。
 */
@Slf4j
@Service
public class AuthServiceImpl implements AuthService {

    private final UsersMapper usersMapper;
    private final PendingTotpMapper pendingTotpMapper;
    private final TrustedDeviceService trustedDeviceService;
    private final ApiTokenService apiTokenService;
    private final LoginAttemptLimiter attemptLimiter;
    private final Clock clock;
    private final AuditRecorder auditRecorder;

    /** 显式构造器：类中存在 {@code @Value} 字段，不能再依赖 Lombok 生成构造器。 */
    public AuthServiceImpl(
            UsersMapper usersMapper,
            PendingTotpMapper pendingTotpMapper,
            TrustedDeviceService trustedDeviceService,
            ApiTokenService apiTokenService,
            LoginAttemptLimiter attemptLimiter,
            Clock clock,
            AuditRecorder auditRecorder) {
        this.usersMapper = usersMapper;
        this.pendingTotpMapper = pendingTotpMapper;
        this.trustedDeviceService = trustedDeviceService;
        this.apiTokenService = apiTokenService;
        this.attemptLimiter = attemptLimiter;
        this.clock = clock;
        this.auditRecorder = auditRecorder;
    }

    @Value("${haven.totp.issuer:Haven}")
    private String totpIssuer;

    /** 待验证 TOTP 有效期：5 分钟。 */
    private static final long PENDING_TOTP_MINUTES = 5;
    /** BCrypt cost。 */
    private static final int BCRYPT_COST = 12;

    // -----------------------------------------------------------------------
    // 登录 / 登出
    // -----------------------------------------------------------------------

    /**
     * 只做密码校验与待验证记录落库，不建立会话。
     * <p>
     * HTTP 入口走 {@link AuthSessionOpener}，它在事务外建立 Sa-Token 会话。
     */
    @Override
    public LoginOutcome login(LoginRequest req, String ip, String ua, String trustedDeviceToken) {
        LoginPrecheck precheck = loginPrecheck(req, ip, ua, trustedDeviceToken);
        if (precheck.totpRequired()) {
            String rawToken = UUID.randomUUID().toString().replace("-", "") + ":" + precheck.userId();
            savePendingTotp(
                    precheck.userId(),
                    ApiTokenUtil.hash(rawToken),
                    ip,
                    ua,
                    precheck.trustDevice(),
                    OffsetDateTime.now(clock).plusMinutes(PENDING_TOTP_MINUTES));
            return new LoginOutcome(precheck.body().withTempToken(rawToken), null);
        }
        return new LoginOutcome(precheck.body(), null);
    }

    /** 登录第一步的校验结果（不含任何会话副作用）。 */
    record LoginPrecheck(String userId, LoginResponse body, boolean totpRequired, boolean trustDevice) {}

    /** 登录第二步的校验结果。 */
    record TotpPrecheck(UUID pendingId, String userId, LoginResponse body, boolean trustDevice, String userAgent) {}

    /** 校验用户名密码；需要第二步时返回 totpRequired=true，由调用方写入待验证记录。 */
    @Transactional(readOnly = true)
    public LoginPrecheck loginPrecheck(LoginRequest req, String ip, String ua, String trustedDeviceToken) {
        String attemptKey =
                LoginAttemptLimiter.LOGIN_PREFIX + req.username().trim().toLowerCase(Locale.ROOT);
        attemptLimiter.requireLeft(attemptKey);

        Users user = findUserByUsername(req.username());
        if (user == null || !BCrypt.verifyer().verify(req.password().toCharArray(), user.getPasswordHash()).verified) {
            attemptLimiter.recordFailure(attemptKey);
            auditRecorder.record(
                    user != null ? user.getId() : null,
                    req.username(),
                    AuditEventType.LOGIN_FAILURE,
                    null,
                    null,
                    ip,
                    ua);
            throw BizException.unauthorized("用户名或密码错误");
        }
        attemptLimiter.clear(attemptKey);

        String userId = user.getId().toString();
        boolean totpEnabled = Boolean.TRUE.equals(user.getTotpEnabled());
        boolean trustedDevice = totpEnabled && trustedDeviceService.isTrusted(userId, trustedDeviceToken);
        boolean totpRequired = totpEnabled && !trustedDevice;

        LoginResponse body = new LoginResponse(userBrief(user), totpRequired, null);
        return new LoginPrecheck(userId, body, totpRequired, Boolean.TRUE.equals(req.trustDevice()));
    }

    /** 写入待验证 TOTP 记录，并清理该用户已过期的旧记录。 */
    @Transactional
    public void savePendingTotp(
            String userId, String tokenHash, String ip, String ua, boolean trustDevice, OffsetDateTime expiresAt) {
        PendingTotp pending = new PendingTotp();
        pending.setId(UUID.randomUUID());
        pending.setUserId(UUID.fromString(userId));
        pending.setToken(tokenHash);
        pending.setIp(ip);
        pending.setUserAgent(ua);
        pending.setTrustDevice(trustDevice);
        pending.setExpiresAt(expiresAt);
        pending.setCreatedAt(OffsetDateTime.now(clock));
        pendingTotpMapper.insert(pending);

        pendingTotpMapper.delete(new LambdaQueryWrapper<PendingTotp>()
                .eq(PendingTotp::getUserId, pending.getUserId())
                .lt(PendingTotp::getExpiresAt, OffsetDateTime.now(clock)));
    }

    /**
     * 只校验动态码，不建立会话（HTTP 入口见 {@link AuthSessionOpener}）。
     */
    @Override
    public LoginOutcome loginTotp(LoginTotpRequest req, String ip, String ua) {
        TotpPrecheck precheck = totpPrecheck(req);
        consumePendingTotp(precheck.pendingId());
        return new LoginOutcome(precheck.body(), null);
    }

    /** 第二步校验动态码；失败会计数，达到上限时作废临时令牌。 */
    public TotpPrecheck totpPrecheck(LoginTotpRequest req) {
        String tokenHash = ApiTokenUtil.hash(req.tempToken());
        PendingTotp pending = pendingTotpMapper.selectOne(new LambdaQueryWrapper<PendingTotp>()
                .eq(PendingTotp::getToken, tokenHash)
                .gt(PendingTotp::getExpiresAt, OffsetDateTime.now(clock)));
        if (pending == null) {
            throw BizException.unauthorized("登录已超时，请重新登录");
        }

        Users user = usersMapper.selectById(pending.getUserId());
        if (user == null || !Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.unauthorized("动态码错误");
        }
        String attemptKey = LoginAttemptLimiter.TOTP_PREFIX + user.getId();
        attemptLimiter.requireLeft(attemptKey);
        if (!TotpUtil.verify(user.getTotpSecret(), req.code(), clock)) {
            if (attemptLimiter.recordFailure(attemptKey) >= attemptLimiter.totpMaxAttempts()) {
                pendingTotpMapper.deleteById(pending.getId());
            }
            throw BizException.unauthorized("动态码错误");
        }
        attemptLimiter.clear(attemptKey);

        LoginResponse body = new LoginResponse(userBrief(user), false, null);
        return new TotpPrecheck(
                pending.getId(),
                user.getId().toString(),
                body,
                Boolean.TRUE.equals(pending.getTrustDevice()),
                pending.getUserAgent());
    }

    /** 删除已消费的临时令牌。 */
    @Transactional
    public void consumePendingTotp(UUID pendingId) {
        pendingTotpMapper.deleteById(pendingId);
    }

    /** 为本次登录创建授信设备，返回明文 Cookie 令牌。 */
    public String createTrustedDevice(String userId, String userAgent) {
        return trustedDeviceService.create(userId, userAgent);
    }

    @Override
    public void logout() {
        StpUtil.logout();
    }

    // -----------------------------------------------------------------------
    // 当前身份
    // -----------------------------------------------------------------------

    @Override
    @Transactional(readOnly = true)
    public MeResponse me(String userId, String authType) {
        Users user = userId == null || userId.isBlank() ? null : usersMapper.selectById(UUID.fromString(userId));
        if (user == null) {
            return new MeResponse(true, authType, null);
        }
        return new MeResponse(
                false,
                authType,
                new MeUser(user.getId(), user.getUsername(), Boolean.TRUE.equals(user.getTotpEnabled())));
    }

    // -----------------------------------------------------------------------
    // TOTP 管理
    // -----------------------------------------------------------------------

    @Override
    public TotpSetupResponse setupTotp(String userId) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) {
            throw BizException.notFound("用户不存在");
        }
        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.conflict("已启用 TOTP");
        }
        String secret = TotpUtil.generateSecret();
        String uri = TotpUtil.buildUri(secret, user.getUsername(), totpIssuer);
        return new TotpSetupResponse(secret, uri);
    }

    @Override
    @Transactional
    public void verifyTotp(String userId, TotpVerifyRequest req) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) {
            throw BizException.notFound("用户不存在");
        }
        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.conflict("已启用 TOTP");
        }
        if (!TotpUtil.verify(req.secret(), req.code(), clock)) {
            throw BizException.validation("动态码错误");
        }
        user.setTotpSecret(req.secret());
        user.setTotpEnabled(true);
        user.setUpdatedAt(OffsetDateTime.now(clock));
        usersMapper.updateById(user);
        auditRecorder.record(
                user.getId(),
                user.getUsername(),
                AuditEventType.TOTP_BOUND,
                AuditTargetType.USER,
                user.getId(),
                null,
                null);
    }

    @Override
    @Transactional
    public void disableTotp(String userId, TotpDisableRequest req) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) {
            throw BizException.notFound("用户不存在");
        }
        if (!Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.validation("尚未启用 TOTP");
        }
        if (!TotpUtil.verify(user.getTotpSecret(), req.code(), clock)) {
            throw BizException.unauthorized("动态码错误");
        }
        user.setTotpSecret(null);
        user.setTotpEnabled(false);
        user.setUpdatedAt(OffsetDateTime.now(clock));
        usersMapper.updateById(user);

        // TOTP 关闭后，基于 TOTP 的授信设备全部失效
        trustedDeviceService.revokeAll(userId);
        auditRecorder.record(
                UUID.fromString(userId),
                user.getUsername(),
                AuditEventType.TOTP_DISABLED,
                AuditTargetType.USER,
                UUID.fromString(userId),
                null,
                null);
    }

    // -----------------------------------------------------------------------
    // 修改密码
    // -----------------------------------------------------------------------

    /**
     * 修改密码。
     * <p>
     * 只做数据库写入（密码、授信设备、API Token）；撤销 Sa-Token 会话属于外部副作用，
     * 由 {@link AuthSessionOpener#changePassword} 在事务提交后执行，避免回滚后会话已被踢下线。
     */
    @Override
    @Transactional
    public void changePassword(String userId, PasswordChangeRequest req, String ip, String ua) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) {
            throw BizException.notFound("用户不存在");
        }

        // 校验旧密码
        if (!BCrypt.verifyer().verify(req.oldPassword().toCharArray(), user.getPasswordHash()).verified) {
            throw BizException.unauthorized("用户名或密码错误");
        }

        // 启用 TOTP 时还需校验动态码
        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            if (req.totpCode() == null || !TotpUtil.verify(user.getTotpSecret(), req.totpCode(), clock)) {
                throw BizException.unauthorized("动态码错误");
            }
        }

        // 新旧密码不能相同
        if (req.oldPassword().equals(req.newPassword())) {
            throw BizException.validation("新密码不能与旧密码相同");
        }

        // 更新密码
        String newHash = BCrypt.withDefaults()
                .hashToString(BCRYPT_COST, req.newPassword().toCharArray());
        user.setPasswordHash(newHash);
        user.setUpdatedAt(OffsetDateTime.now(clock));
        usersMapper.updateById(user);

        // 密码变更后，所有授信设备失效
        trustedDeviceService.revokeAll(userId);

        // API Token 与密码是两条独立凭据，改密必须一并失效，否则旧 Token 仍可访问
        apiTokenService.revokeAllForUser(userId);
        auditRecorder.record(
                UUID.fromString(userId),
                user.getUsername(),
                AuditEventType.PASSWORD_CHANGED,
                AuditTargetType.USER,
                UUID.fromString(userId),
                ip,
                ua);
        // 会话作废由 AuthSessionOpener 在事务提交后处理（见类注释）
    }

    // -----------------------------------------------------------------------
    // 内部方法
    // -----------------------------------------------------------------------

    private Users findUserByUsername(String username) {
        return usersMapper.selectOne(
                new LambdaQueryWrapper<Users>().apply("lower(username) = lower({0})", username.trim()));
    }

    private static UserBrief userBrief(Users user) {
        return new UserBrief(user.getId(), user.getUsername());
    }

    /** 登录时把 UA 与「是否已通过动态码」写进 Sa-Token 终端扩展数据。 */
    private SaLoginParameter loginParameter(String ua, boolean totpVerified) {
        return new SaLoginParameter()
                .setTerminalExtra(AuthInterceptor.EXTRA_USER_AGENT, ua != null ? ua : "")
                .setTerminalExtra(AuthInterceptor.EXTRA_TOTP_VERIFIED, totpVerified);
    }
}
