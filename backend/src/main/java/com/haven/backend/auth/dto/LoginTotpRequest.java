package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * TOTP 第二步登录请求（POST /api/auth/login/totp）。
 */
@Data
public class LoginTotpRequest {

    @NotBlank(message = "临时令牌不能为空")
    private String tempToken;

    @NotBlank(message = "动态码不能为空")
    private String code;
}
