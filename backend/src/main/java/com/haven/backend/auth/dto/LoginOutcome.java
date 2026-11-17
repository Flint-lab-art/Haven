package com.haven.backend.auth.dto;

import com.haven.backend.auth.dto.AuthDtos.LoginResponse;

/**
 * 登录结果。
 *
 * @param body               返回给前端的登录响应
 * @param trustedDeviceToken 本次新创建的授信设备明文令牌（需要写入 Cookie），没有则为 null
 */
public record LoginOutcome(LoginResponse body, String trustedDeviceToken) {}
