package com.haven.backend.note.service;

import java.util.Map;
import java.util.UUID;

public interface NotesService {
    Map<String, Object> listNotes(String userId, Integer limit, Integer offset, String visibility, UUID tagId,
            UUID folderId, Boolean includeTrash);

    Map<String, Object> getNote(String userId, UUID noteId);

    Map<String, Object> createNote(String userId, String title, String content, java.util.List<UUID> tagIds,
            UUID folderId);

    Map<String, Object> updateNote(String userId, UUID noteId, String title, String content,
            java.util.List<UUID> tagIds, UUID folderId, Integer sortOrder);

    void deleteNote(String userId, UUID noteId);

    Map<String, Object> listTrash(String userId, int limit, int offset);

    Map<String, Object> restoreNote(String userId, UUID noteId);

    void purgeNote(String userId, UUID noteId);

    void emptyTrash(String userId);

    Map<String, Object> publishNote(String userId, UUID noteId);

    Map<String, Object> unpublishNote(String userId, UUID noteId);

    Map<String, Object> listVersions(String userId, UUID noteId, int limit, int offset);

    Map<String, Object> getVersion(String userId, UUID noteId, UUID versionId);

    Map<String, Object> restoreVersion(String userId, UUID noteId, UUID versionId);

    Map<String, Object> listPublicNotes(int limit, int offset);

    Map<String, Object> getPublicNote(UUID noteId);
}
