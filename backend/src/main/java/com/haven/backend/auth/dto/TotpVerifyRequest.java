package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * TOTP 绑定验证请求（POST /api/auth/totp/verify）。
 */
public record TotpVerifyRequest(
        @NotBlank(message = "secret 不能为空") @Pattern(regexp = "^[A-Za-z2-7]+=*$", message = "secret 不是合法的 Base32 字符串")
        String secret,

        @NotBlank(message = "动态码不能为空") @Pattern(regexp = "^\\d{6}$", message = "动态码必须是 6 位数字")
        String code) {}
