package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * TOTP 第二步登录请求（POST /api/auth/login/totp）。
 */
public record LoginTotpRequest(
        @NotBlank(message = "临时令牌不能为空") String tempToken,

        @NotBlank(message = "动态码不能为空") @Pattern(regexp = "^\\d{6}$", message = "动态码必须是 6 位数字")
        String code) {}
