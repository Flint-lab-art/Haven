package com.haven.backend.service.impl;

import at.favre.lib.crypto.bcrypt.BCrypt;
import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.dto.*;
import com.haven.backend.entity.PendingTotp;
import com.haven.backend.entity.Users;
import com.haven.backend.exception.BizException;
import com.haven.backend.mapper.PendingTotpMapper;
import com.haven.backend.mapper.UsersMapper;
import com.haven.backend.service.AuthService;
import com.haven.backend.util.ApiTokenUtil;
import com.haven.backend.util.TotpUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * 认证服务实现。
 * <p>
 * 会话管理委托 Sa-Token；TOTP 使用自实现工具类；
 * 密码哈希使用 BCrypt（cost=12，与 Go 端一致）。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UsersMapper usersMapper;
    private final PendingTotpMapper pendingTotpMapper;

    @Value("${haven.totp.issuer:Haven}")
    private String totpIssuer;

    /** 待验证 TOTP 有效期：5 分钟。 */
    private static final long PENDING_TOTP_MINUTES = 5;
    /** BCrypt cost。 */
    private static final int BCRYPT_COST = 12;

    // -----------------------------------------------------------------------
    // 登录 / 登出
    // -----------------------------------------------------------------------

    @Override
    public Map<String, Object> login(LoginRequest req, String ip, String ua) {
        Users user = findUserByUsername(req.getUsername());
        if (user == null) {
            throw BizException.unauthorized("用户名或密码错误");
        }
        if (!BCrypt.verifyer().verify(req.getPassword().toCharArray(), user.getPasswordHash()).verified) {
            throw BizException.unauthorized("用户名或密码错误");
        }

        Map<String, Object> result = new HashMap<>();
        result.put("user", userBrief(user));

        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            // 启用 TOTP → 生成临时令牌，等第二步校验
            String rawToken = UUID.randomUUID().toString().replace("-", "") + ":" + user.getId().toString();
            String tokenHash = ApiTokenUtil.hash(rawToken);

            PendingTotp pending = new PendingTotp();
            pending.setId(UUID.randomUUID());
            pending.setUserId(user.getId());
            pending.setToken(tokenHash);
            pending.setIp(ip);
            pending.setUserAgent(ua);
            pending.setExpiresAt(OffsetDateTime.now().plusMinutes(PENDING_TOTP_MINUTES));
            pending.setCreatedAt(OffsetDateTime.now());
            pendingTotpMapper.insert(pending);

            // 顺手清理该用户已过期的待验证记录
            pendingTotpMapper.delete(new LambdaQueryWrapper<PendingTotp>()
                    .eq(PendingTotp::getUserId, user.getId())
                    .lt(PendingTotp::getExpiresAt, OffsetDateTime.now()));

            result.put("totp_required", true);
            result.put("temp_token", rawToken);
        } else {
            // 未启用 TOTP → 直接建立 Sa-Token 会话
            StpUtil.login(user.getId().toString());
            result.put("totp_required", false);
        }
        return result;
    }

    @Override
    public Map<String, Object> loginTotp(LoginTotpRequest req, String ip, String ua) {
        String tokenHash = ApiTokenUtil.hash(req.getTempToken());

        PendingTotp pending = pendingTotpMapper.selectOne(
                new LambdaQueryWrapper<PendingTotp>()
                        .eq(PendingTotp::getToken, tokenHash)
                        .gt(PendingTotp::getExpiresAt, OffsetDateTime.now()));
        if (pending == null) {
            throw BizException.unauthorized("登录已超时，请重新登录");
        }

        Users user = usersMapper.selectById(pending.getUserId());
        if (user == null || !Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.unauthorized("动态码错误");
        }
        if (!TotpUtil.verify(user.getTotpSecret(), req.getCode())) {
            throw BizException.unauthorized("动态码错误");
        }

        // 校验通过：删除待验证记录，建立 Sa-Token 会话
        pendingTotpMapper.deleteById(pending.getId());
        StpUtil.login(user.getId().toString());

        Map<String, Object> result = new HashMap<>();
        result.put("user", userBrief(user));
        result.put("totp_required", false);
        return result;
    }

    @Override
    public void logout() {
        StpUtil.logout();
    }

    // -----------------------------------------------------------------------
    // 当前身份
    // -----------------------------------------------------------------------

    @Override
    public Map<String, Object> me(String userId) {
        Map<String, Object> result = new HashMap<>();
        if (userId == null || userId.isEmpty()) {
            result.put("anonymous", true);
            return result;
        }
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) {
            result.put("anonymous", true);
            return result;
        }
        result.put("anonymous", false);
        result.put("auth_type", "session");
        result.put("user", Map.of(
                "id", user.getId().toString(),
                "username", user.getUsername(),
                "totp_enabled", Boolean.TRUE.equals(user.getTotpEnabled())
        ));
        return result;
    }

    // -----------------------------------------------------------------------
    // TOTP 管理
    // -----------------------------------------------------------------------

    @Override
    public Map<String, String> setupTotp(String userId) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) throw BizException.notFound("用户不存在");
        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.conflict("已启用 TOTP");
        }
        String secret = TotpUtil.generateSecret();
        String uri = TotpUtil.buildUri(secret, user.getUsername(), totpIssuer);
        return Map.of("secret", secret, "otpauth_uri", uri);
    }

    @Override
    @Transactional
    public void verifyTotp(String userId, TotpVerifyRequest req) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) throw BizException.notFound("用户不存在");
        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.conflict("已启用 TOTP");
        }
        if (!TotpUtil.verify(req.getSecret(), req.getCode())) {
            throw BizException.validation("动态码错误");
        }
        user.setTotpSecret(req.getSecret());
        user.setTotpEnabled(true);
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.updateById(user);
    }

    @Override
    @Transactional
    public void disableTotp(String userId, TotpDisableRequest req) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) throw BizException.notFound("用户不存在");
        if (!Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw BizException.validation("尚未启用 TOTP");
        }
        if (!TotpUtil.verify(user.getTotpSecret(), req.getCode())) {
            throw BizException.unauthorized("动态码错误");
        }
        user.setTotpSecret(null);
        user.setTotpEnabled(false);
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.updateById(user);
    }

    // -----------------------------------------------------------------------
    // 修改密码
    // -----------------------------------------------------------------------

    @Override
    @Transactional
    public void changePassword(String userId, PasswordChangeRequest req, String ip, String ua) {
        Users user = usersMapper.selectById(UUID.fromString(userId));
        if (user == null) throw BizException.notFound("用户不存在");

        // 校验旧密码
        if (!BCrypt.verifyer().verify(req.getOldPassword().toCharArray(), user.getPasswordHash()).verified) {
            throw BizException.unauthorized("用户名或密码错误");
        }

        // 启用 TOTP 时还需校验动态码
        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            if (req.getTotpCode() == null || !TotpUtil.verify(user.getTotpSecret(), req.getTotpCode())) {
                throw BizException.unauthorized("动态码错误");
            }
        }

        // 新旧密码不能相同
        if (req.getOldPassword().equals(req.getNewPassword())) {
            throw BizException.validation("新密码不能与旧密码相同");
        }

        // 更新密码
        String newHash = BCrypt.withDefaults().hashToString(BCRYPT_COST, req.getNewPassword().toCharArray());
        user.setPasswordHash(newHash);
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.updateById(user);

        // 撤销当前用户的全部 Sa-Token 会话（强制重新登录）
        StpUtil.logout(userId);
        StpUtil.kickout(userId);
    }

    // -----------------------------------------------------------------------
    // 内部方法
    // -----------------------------------------------------------------------

    private Users findUserByUsername(String username) {
        return usersMapper.selectOne(
                new LambdaQueryWrapper<Users>()
                        .apply("lower(username) = lower({0})", username.trim()));
    }

    private Map<String, String> userBrief(Users user) {
        return Map.of("id", user.getId().toString(), "username", user.getUsername());
    }
}
