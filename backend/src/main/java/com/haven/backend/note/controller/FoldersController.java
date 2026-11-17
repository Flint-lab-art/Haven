package com.haven.backend.note.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.note.dto.CreateFolderRequest;
import com.haven.backend.note.dto.FolderDtos.FolderList;
import com.haven.backend.note.dto.FolderDtos.FolderResponse;
import com.haven.backend.note.dto.UpdateFolderRequest;
import com.haven.backend.note.entity.Folders;
import com.haven.backend.note.service.FolderUpdate;
import com.haven.backend.note.service.FoldersService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/folders")
@RequiredArgsConstructor
public class FoldersController {

    private final FoldersService foldersService;

    @GetMapping
    public FolderList list(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        List<FolderResponse> items = foldersService.listFolders(userId).stream()
                .map(FoldersController::toResponse)
                .toList();
        return new FolderList(items, items.size());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FolderResponse create(@Valid @RequestBody CreateFolderRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return toResponse(foldersService.createFolder(userId, req.name(), req.parentId(), req.icon()));
    }

    @PatchMapping("/{id}")
    public FolderResponse update(
            @PathVariable UUID id, @Valid @RequestBody UpdateFolderRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        FolderUpdate update = new FolderUpdate(
                req.parentId(), Boolean.TRUE.equals(req.clearParent()), req.name(), req.icon(), req.sortOrder());
        return toResponse(foldersService.updateFolder(userId, id, update));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        foldersService.deleteFolder(userId, id);
    }

    private static FolderResponse toResponse(Folders f) {
        return new FolderResponse(
                f.getId(),
                f.getParentId(),
                f.getName(),
                f.getSortOrder(),
                f.getIcon(),
                f.getCreatedAt(),
                f.getUpdatedAt(),
                Boolean.TRUE.equals(f.getIsInbox()),
                List.of());
    }
}
