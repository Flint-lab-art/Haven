package com.haven.backend.auth.service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 授信设备服务：登录时创建，设置页查看 / 撤销。
 */
public interface TrustedDeviceService {

    /** 浏览器 Cookie 名。 */
    String COOKIE_NAME = "haven_trusted_device";

    /** 授信有效期（天）。 */
    int TRUST_DAYS = 30;

    /**
     * 校验设备令牌是否有效。有效时刷新 last_used_at。
     */
    boolean isTrusted(String userId, String rawToken);

    /**
     * 为当前登录创建授信设备，返回只出现一次的明文令牌。
     */
    String create(String userId, String userAgent);

    /** 列出用户未过期的授信设备（含明文以外的全部字段）。 */
    List<Map<String, Object>> listDevices(String userId);

    /** 撤销（删除）指定授信设备。 */
    void revoke(String userId, UUID deviceId);

    /** 撤销用户的全部授信设备（改密码 / 关闭 TOTP 时调用）。 */
    void revokeAll(String userId);
}
