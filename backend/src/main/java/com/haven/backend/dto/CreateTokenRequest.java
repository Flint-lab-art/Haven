package com.haven.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

import java.time.OffsetDateTime;

/**
 * 创建 API Token 请求（POST /api/tokens）。
 */
@Data
public class CreateTokenRequest {

    @NotBlank(message = "名称不能为空")
    private String name;

    @NotBlank
    @Pattern(regexp = "read|read_write", message = "scope 只能是 read 或 read_write")
    private String scope;

    /** 过期时间，null 表示永不过期。 */
    private OffsetDateTime expiresAt;
}
