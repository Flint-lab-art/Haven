package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 登录请求（POST /api/auth/login）。
 */
@Data
public class LoginRequest {

    @NotBlank(message = "用户名不能为空")
    private String username;

    @NotBlank(message = "密码不能为空")
    private String password;

    /** 是否勾选「信任这台设备，30 天内免动态码」。 */
    private Boolean trustDevice;
}
