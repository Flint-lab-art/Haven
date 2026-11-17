package com.haven.backend.note.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * 创建文件夹请求（POST /api/folders）。
 */
public record CreateFolderRequest(
        @NotBlank(message = "文件夹名称不能为空") @Size(max = 32, message = "文件夹名称不能超过 32 个字符")
        String name,

        UUID parentId,
        @Size(max = 64, message = "图标名过长") String icon) {}
