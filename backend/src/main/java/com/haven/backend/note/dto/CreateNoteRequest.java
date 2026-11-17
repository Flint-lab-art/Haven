package com.haven.backend.note.dto;

import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * 创建笔记请求（POST /api/notes）。
 */
public record CreateNoteRequest(
        @Size(max = 200, message = "标题不能超过 200 个字符") String title, String content, List<UUID> tagIds, UUID folderId) {}
