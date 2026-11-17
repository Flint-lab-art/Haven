package com.haven.backend.note.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 文件夹模块的响应契约，避免把实体直接序列化给前端。
 */
public final class FolderDtos {

    private FolderDtos() {}

    /** 文件夹（没有子节点时不带 children）。 */
    public record FolderResponse(
            UUID id,
            UUID parentId,
            String name,
            Integer sortOrder,
            String icon,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt,
            boolean isInbox,
            List<FolderResponse> children) {}

    /** 文件夹列表。 */
    public record FolderList(List<FolderResponse> items, long total) {}
}
