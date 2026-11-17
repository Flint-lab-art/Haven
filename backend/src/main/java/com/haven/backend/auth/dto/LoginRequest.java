package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 登录请求（POST /api/auth/login）。
 * <p>
 * 用 record 而不是 {@code @Data} class：Jackson 的 SNAKE_CASE 命名策略对 record
 * 与 JavaBean 的<b>反序列化</b>行为相反（record 认 camelCase，bean 认 snake_case），
 * 统一成 record 才能让前端只发一种写法。
 */
public record LoginRequest(
        @NotBlank(message = "用户名不能为空") @Size(max = 64, message = "用户名过长")
        String username,

        @NotBlank(message = "密码不能为空") String password,
        /** 是否勾选「信任这台设备，30 天内免动态码」。 */
        Boolean trustDevice) {}
