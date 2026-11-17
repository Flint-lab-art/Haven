package com.haven.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.OffsetDateTime;

/**
 * 创建 API Token 请求（POST /api/tokens）。
 */
public record CreateTokenRequest(
        @NotBlank(message = "名称不能为空") @Size(max = 64, message = "名称不能超过 64 个字符")
        String name,

        @NotBlank @Pattern(regexp = "read|read_write", message = "scope 只能是 read 或 read_write")
        String scope,
        /** 过期时间，null 表示永不过期。 */
        OffsetDateTime expiresAt) {}
