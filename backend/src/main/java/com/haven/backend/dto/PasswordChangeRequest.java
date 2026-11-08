package com.haven.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 修改密码请求（POST /api/auth/password）。
 */
@Data
public class PasswordChangeRequest {

    @NotBlank(message = "旧密码不能为空")
    private String oldPassword;

    @NotBlank(message = "新密码不能为空")
    @Size(min = 12, message = "新密码至少 12 位")
    private String newPassword;

    /** 启用 TOTP 时必须提供。 */
    private String totpCode;
}
