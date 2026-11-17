package com.haven.backend.note.dto;

import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * 更新笔记请求（PATCH /api/notes/{id}）。
 * <p>
 * 字段为 {@code null} 表示「不修改」；{@code folderId} 需要清空时用 {@code clearFolder=true} 显式表达，
 * 不再依赖「字段是否出现在 JSON 里」来区分语义。
 */
public record UpdateNoteRequest(
        @Size(max = 200, message = "标题不能超过 200 个字符") String title,
        String content,
        List<UUID> tagIds,
        UUID folderId,
        Boolean clearFolder,
        Integer sortOrder) {}
