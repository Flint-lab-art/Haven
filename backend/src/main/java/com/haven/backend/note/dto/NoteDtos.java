package com.haven.backend.note.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 笔记模块的响应契约。
 * <p>
 * 集中定义所有对外 DTO，字段名与前端 {@code frontend/src/api/notes.ts} 对齐
 * （全局 Jackson 使用 SNAKE_CASE，record 组件名写 camelCase 即可）。
 */
public final class NoteDtos {

    private NoteDtos() {}

    /** 标签简要信息。 */
    public record TagBrief(UUID id, String name) {}

    /** 笔记列表项（不含正文）。 */
    public record NoteSummary(
            UUID id,
            UUID folderId,
            Integer sortOrder,
            String title,
            String contentPreview,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt,
            List<TagBrief> tags) {}

    /** 笔记详情（含正文）。 */
    public record NoteDetail(
            UUID id,
            UUID folderId,
            Integer sortOrder,
            String title,
            String content,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt,
            List<TagBrief> tags) {}

    /** 笔记分页列表。 */
    public record NotePage(List<NoteSummary> items, long total) {}

    /** 回收站列表项（多带文件夹路径与删除时间）。 */
    public record TrashNoteSummary(
            UUID id, String title, String contentPreview, UUID folderId, String folderPath, OffsetDateTime deletedAt) {}

    /** 回收站分页列表。 */
    public record TrashNotePage(List<TrashNoteSummary> items, long total) {}

    /** 版本列表项。 */
    public record NoteVersionSummary(
            UUID id, String title, String contentPreview, OffsetDateTime createdAt, long contentSize) {}

    /** 版本详情。 */
    public record NoteVersionDetail(
            UUID id,
            String title,
            String content,
            UUID folderId,
            List<UUID> tagIds,
            OffsetDateTime createdAt,
            long contentSize) {}

    /** 版本分页列表。 */
    public record NoteVersionPage(List<NoteVersionSummary> items, long total) {}

    /** 标签及其笔记数。 */
    public record TagSummary(UUID id, String name, long noteCount, OffsetDateTime createdAt) {}

    /** 标签列表。 */
    public record TagList(List<TagSummary> items, long total) {}

    /** 新建标签的返回。 */
    public record TagCreated(UUID id, String name, OffsetDateTime createdAt) {}

    /** 搜索结果：命中的笔记与命中的标签。 */
    public record SearchResult(NotePage notes, List<TagSummary> tags, long tagTotal) {}

    /** 文件夹简要信息（包含路径）。 */
    public record FolderBrief(UUID id, String name, String path) {}

    /** 上传结果。 */
    public record UploadResult(String url, String name, long size, String mime) {}

    /** 图标列表项。 */
    public record IconItem(String url, long size, String createdAt) {}

    /** 图标分页列表。 */
    public record IconPage(List<IconItem> items, long total) {}
}
