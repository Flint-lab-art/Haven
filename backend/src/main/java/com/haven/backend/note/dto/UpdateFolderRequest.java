package com.haven.backend.note.dto;

import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * 更新文件夹请求（PATCH /api/folders/{id}）。
 * <p>
 * 字段为 {@code null} 表示不修改；{@code clearParent=true} 表示移到根目录。
 */
public record UpdateFolderRequest(
        @Size(max = 32, message = "文件夹名称不能超过 32 个字符") String name,
        UUID parentId,
        Boolean clearParent,
        @Size(max = 64, message = "图标名过长") String icon,
        Integer sortOrder) {}
