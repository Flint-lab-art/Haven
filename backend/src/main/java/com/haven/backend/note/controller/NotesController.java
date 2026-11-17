package com.haven.backend.note.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.note.dto.CreateNoteRequest;
import com.haven.backend.note.dto.NoteDtos.NoteDetail;
import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.NoteVersionDetail;
import com.haven.backend.note.dto.NoteDtos.NoteVersionPage;
import com.haven.backend.note.dto.NoteDtos.PublicNoteDetail;
import com.haven.backend.note.dto.NoteDtos.PublicNotePage;
import com.haven.backend.note.dto.NoteDtos.TrashNotePage;
import com.haven.backend.note.dto.UpdateNoteRequest;
import com.haven.backend.note.service.NotesService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class NotesController {

    private final NotesService notesService;

    // ---- 需要登录的笔记接口 ----

    @GetMapping("/api/notes")
    public NotePage list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String visibility,
            @RequestParam(required = false) UUID tagId,
            @RequestParam(required = false) UUID folderId,
            @RequestParam(required = false, defaultValue = "false") boolean includeTrash,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.listNotes(userId, limit, offset, visibility, tagId, folderId, includeTrash);
    }

    @GetMapping("/api/notes/trash")
    public TrashNotePage listTrash(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.listTrash(userId, limit, offset);
    }

    @GetMapping("/api/notes/{id}")
    public NoteDetail get(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.getNote(userId, id);
    }

    @PostMapping("/api/notes")
    @ResponseStatus(HttpStatus.CREATED)
    public NoteDetail create(@Valid @RequestBody CreateNoteRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.createNote(userId, req.title(), req.content(), req.tagIds(), req.folderId());
    }

    @PatchMapping("/api/notes/{id}")
    public NoteDetail update(
            @PathVariable UUID id, @Valid @RequestBody UpdateNoteRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        // clearFolder=true 表示显式移到根目录；否则 folderId 为 null 即「不修改」
        UUID folderId = Boolean.TRUE.equals(req.clearFolder()) ? null : req.folderId();
        boolean clearFolder = Boolean.TRUE.equals(req.clearFolder());
        return notesService.updateNote(
                userId, id, req.title(), req.content(), req.tagIds(), folderId, clearFolder, req.sortOrder());
    }

    @DeleteMapping("/api/notes/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        notesService.deleteNote(userId, id);
    }

    @DeleteMapping("/api/notes/trash")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void emptyTrash(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        notesService.emptyTrash(userId);
    }

    @PostMapping("/api/notes/{id}/restore")
    public NoteDetail restore(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.restoreNote(userId, id);
    }

    @DeleteMapping("/api/notes/{id}/purge")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void purge(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        notesService.purgeNote(userId, id);
    }

    @PostMapping("/api/notes/{id}/publish")
    public NoteDetail publish(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.publishNote(userId, id);
    }

    @PostMapping("/api/notes/{id}/unpublish")
    public NoteDetail unpublish(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.unpublishNote(userId, id);
    }

    @GetMapping("/api/notes/{id}/versions")
    public NoteVersionPage listVersions(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.listVersions(userId, id, limit, offset);
    }

    @GetMapping("/api/notes/{id}/versions/{versionId}")
    public NoteVersionDetail getVersion(
            @PathVariable UUID id, @PathVariable UUID versionId, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.getVersion(userId, id, versionId);
    }

    @PostMapping("/api/notes/{id}/versions/{versionId}/restore")
    public NoteDetail restoreVersion(@PathVariable UUID id, @PathVariable UUID versionId, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return notesService.restoreVersion(userId, id, versionId);
    }

    // ---- 公开笔记接口（匿名可访问） ----

    @GetMapping("/api/public/notes")
    public PublicNotePage listPublic(
            @RequestParam(defaultValue = "20") int limit, @RequestParam(defaultValue = "0") int offset) {
        return notesService.listPublicNotes(limit, offset);
    }

    @GetMapping("/api/public/notes/{id}")
    public PublicNoteDetail getPublic(@PathVariable UUID id) {
        return notesService.getPublicNote(id);
    }
}
