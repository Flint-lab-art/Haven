package com.haven.backend.note.service;

import com.haven.backend.note.dto.NoteDtos.NoteDetail;
import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.NoteVersionDetail;
import com.haven.backend.note.dto.NoteDtos.NoteVersionPage;
import com.haven.backend.note.dto.NoteDtos.TrashNotePage;
import java.util.List;
import java.util.UUID;

/**
 * 笔记服务。
 * <p>
 * 所有返回值都是有名字的 DTO（见 {@code NoteDtos}），不再使用 {@code Map<String,Object>}。
 */
public interface NotesService {

    NotePage listNotes(String userId, Integer limit, Integer offset, UUID tagId, UUID folderId, Boolean includeTrash);

    NoteDetail getNote(String userId, UUID noteId);

    NoteDetail createNote(String userId, String title, String content, List<UUID> tagIds, UUID folderId);

    /**
     * 更新笔记。
     *
     * @param folderId 目标文件夹；为 {@code null} 且 {@code clearFolder=false} 时表示不修改
     * @param clearFolder 为 true 时把笔记移到根目录（忽略 {@code folderId}）
     */
    NoteDetail updateNote(
            String userId,
            UUID noteId,
            String title,
            String content,
            List<UUID> tagIds,
            UUID folderId,
            boolean clearFolder,
            Integer sortOrder);

    void deleteNote(String userId, UUID noteId);

    TrashNotePage listTrash(String userId, int limit, int offset);

    NoteDetail restoreNote(String userId, UUID noteId);

    void purgeNote(String userId, UUID noteId);

    void emptyTrash(String userId);

    NoteVersionPage listVersions(String userId, UUID noteId, int limit, int offset);

    NoteVersionDetail getVersion(String userId, UUID noteId, UUID versionId);

    NoteDetail restoreVersion(String userId, UUID noteId, UUID versionId);
}
