package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * TOTP 绑定验证请求（POST /api/auth/totp/verify）。
 */
@Data
public class TotpVerifyRequest {

    @NotBlank(message = "secret 不能为空")
    private String secret;

    @NotBlank(message = "动态码不能为空")
    private String code;
}
