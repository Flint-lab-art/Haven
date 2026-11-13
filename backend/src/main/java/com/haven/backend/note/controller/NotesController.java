package com.haven.backend.note.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.note.service.NotesService;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class NotesController {

    private final NotesService notesService;

    // ---- 需要登录的笔记接口 ----

    @GetMapping("/api/notes")
    public Map<String, Object> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String visibility,
            @RequestParam(required = false) String tag_id,
            @RequestParam(required = false) String folder_id,
            @RequestParam(required = false, defaultValue = "false") boolean include_trash,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        UUID tagId = tag_id != null ? UUID.fromString(tag_id) : null;
        UUID folderId = folder_id != null ? UUID.fromString(folder_id) : null;
        return notesService.listNotes(userId, limit, offset, visibility, tagId, folderId, include_trash);
    }

    @GetMapping("/api/notes/trash")
    public Map<String, Object> listTrash(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.listTrash(userId, limit, offset);
    }

    @GetMapping("/api/notes/{id}")
    public Map<String, Object> get(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.getNote(userId, UUID.fromString(id));
    }

    @PostMapping("/api/notes")
    @ResponseStatus(HttpStatus.CREATED)
    @SuppressWarnings("unchecked")
    public Map<String, Object> create(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        String title = (String) body.get("title");
        String content = (String) body.get("content");
        List<UUID> tagIds = body.get("tag_ids") != null
                ? ((List<String>) body.get("tag_ids")).stream().map(UUID::fromString).toList()
                : null;
        UUID folderId = body.get("folder_id") != null ? UUID.fromString(body.get("folder_id").toString()) : null;
        return notesService.createNote(userId, title, content, tagIds, folderId);
    }

    @PatchMapping("/api/notes/{id}")
    @SuppressWarnings("unchecked")
    public Map<String, Object> update(@PathVariable String id, @RequestBody Map<String, Object> body,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        UUID noteId = UUID.fromString(id);
        String title = body.containsKey("title") ? (String) body.get("title") : null;
        String content = body.containsKey("content") ? (String) body.get("content") : null;
        List<UUID> tagIds = body.containsKey("tag_ids")
                ? ((List<String>) body.get("tag_ids")).stream().map(UUID::fromString).toList()
                : null;
        UUID folderId = body.containsKey("folder_id") && body.get("folder_id") != null
                ? UUID.fromString(body.get("folder_id").toString())
                : null;
        Integer sortOrder = body.containsKey("sort_order") ? ((Number) body.get("sort_order")).intValue() : null;
        return notesService.updateNote(userId, noteId, title, content, tagIds, folderId, sortOrder);
    }

    @DeleteMapping("/api/notes/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        notesService.deleteNote(userId, UUID.fromString(id));
    }

    @DeleteMapping("/api/notes/trash")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void emptyTrash(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        notesService.emptyTrash(userId);
    }

    @PostMapping("/api/notes/{id}/restore")
    public Map<String, Object> restore(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.restoreNote(userId, UUID.fromString(id));
    }

    @DeleteMapping("/api/notes/{id}/purge")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void purge(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        notesService.purgeNote(userId, UUID.fromString(id));
    }

    @PostMapping("/api/notes/{id}/publish")
    public Map<String, Object> publish(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.publishNote(userId, UUID.fromString(id));
    }

    @PostMapping("/api/notes/{id}/unpublish")
    public Map<String, Object> unpublish(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.unpublishNote(userId, UUID.fromString(id));
    }

    @GetMapping("/api/notes/{id}/versions")
    public Map<String, Object> listVersions(@PathVariable String id,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.listVersions(userId, UUID.fromString(id), limit, offset);
    }

    @GetMapping("/api/notes/{id}/versions/{versionId}")
    public Map<String, Object> getVersion(@PathVariable String id, @PathVariable String versionId,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.getVersion(userId, UUID.fromString(id), UUID.fromString(versionId));
    }

    @PostMapping("/api/notes/{id}/versions/{versionId}/restore")
    public Map<String, Object> restoreVersion(@PathVariable String id, @PathVariable String versionId,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.restoreVersion(userId, UUID.fromString(id), UUID.fromString(versionId));
    }

    // ---- 公开笔记接口（匿名可访问） ----

    @GetMapping("/api/public/notes")
    public Map<String, Object> listPublic(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        return notesService.listPublicNotes(limit, offset);
    }

    @GetMapping("/api/public/notes/{id}")
    public Map<String, Object> getPublic(@PathVariable String id) {
        return notesService.getPublicNote(UUID.fromString(id));
    }
}
