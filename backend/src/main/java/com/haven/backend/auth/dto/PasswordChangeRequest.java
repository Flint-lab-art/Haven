package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 修改密码请求（POST /api/auth/password）。
 */
public record PasswordChangeRequest(
        @NotBlank(message = "旧密码不能为空") String oldPassword,

        @NotBlank(message = "新密码不能为空")
        @Size(min = 12, message = "新密码至少 12 位")
        @Size(max = 72, message = "新密码不能超过 72 个字符")
        String newPassword,
        /** 启用 TOTP 时必须提供。 */
        @Pattern(regexp = "^\\d{6}$", message = "动态码必须是 6 位数字")
        String totpCode) {}
