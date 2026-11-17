package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * TOTP 关闭请求（POST /api/auth/totp/disable）。
 */
public record TotpDisableRequest(
        @NotBlank(message = "动态码不能为空") @Pattern(regexp = "^\\d{6}$", message = "动态码必须是 6 位数字")
        String code) {}
