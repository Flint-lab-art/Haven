package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * TOTP 关闭请求（POST /api/auth/totp/disable）。
 */
@Data
public class TotpDisableRequest {

    @NotBlank(message = "动态码不能为空")
    private String code;
}
