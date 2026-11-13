package com.haven.backend.auth.service;

import com.haven.backend.auth.dto.*;

import java.util.Map;

/**
 * 认证服务接口：登录、登出、TOTP 管理、密码修改。
 */
public interface AuthService {

    /** 第一步登录：校验账密，按是否启用 TOTP 走不同分支。 */
    LoginOutcome login(LoginRequest req, String ip, String ua, String trustedDeviceToken);

    /** 第二步登录：校验临时令牌 + TOTP 动态码。 */
    LoginOutcome loginTotp(LoginTotpRequest req, String ip, String ua);

    /** 获取当前身份信息（GET /api/me）。 */
    Map<String, Object> me(String userId);

    /** 登出（撤销当前会话）。 */
    void logout();

    /** 生成 TOTP secret 与 otpauth URI（不落库）。 */
    Map<String, String> setupTotp(String userId);

    /** 校验动态码并绑定 TOTP。 */
    void verifyTotp(String userId, TotpVerifyRequest req);

    /** 校验动态码并关闭 TOTP。 */
    void disableTotp(String userId, TotpDisableRequest req);

    /** 修改密码（启用 TOTP 时需同时校验动态码）。 */
    void changePassword(String userId, PasswordChangeRequest req, String ip, String ua);
}
