package com.haven.backend.note.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.note.dto.CreateTagRequest;
import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.TagCreated;
import com.haven.backend.note.dto.NoteDtos.TagList;
import com.haven.backend.note.dto.NoteDtos.TagSummary;
import com.haven.backend.note.entity.Tags;
import com.haven.backend.note.service.TagsService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/tags")
@RequiredArgsConstructor
public class TagsController {

    private final TagsService tagsService;

    @GetMapping
    public TagList list(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        List<TagSummary> tags = tagsService.listTags(userId);
        return new TagList(tags, tags.size());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TagCreated create(@Valid @RequestBody CreateTagRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        Tags tag = tagsService.createTag(userId, req.name());
        return new TagCreated(tag.getId(), tag.getName(), tag.getCreatedAt());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        tagsService.deleteTag(userId, id);
    }

    @GetMapping("/{id}/notes")
    public NotePage listNotes(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return tagsService.listTagNotes(userId, id, limit, offset);
    }
}
