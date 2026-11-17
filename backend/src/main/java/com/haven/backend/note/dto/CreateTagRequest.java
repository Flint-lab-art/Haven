package com.haven.backend.note.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 创建标签请求（POST /api/tags）。
 */
public record CreateTagRequest(
        @NotBlank(message = "标签名不能为空") @Size(max = 64, message = "标签名不能超过 64 个字符")
        String name) {}
