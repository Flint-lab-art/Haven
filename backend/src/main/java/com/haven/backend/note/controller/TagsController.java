package com.haven.backend.note.controller;


import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.note.entity.Tags;
import com.haven.backend.note.service.TagsService;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/tags")
@RequiredArgsConstructor
public class TagsController {

    private final TagsService tagsService;

    @GetMapping
    public Map<String, Object> list(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        List<Map<String, Object>> tags = tagsService.listTags(userId);
        return Map.of("items", tags, "total", tags.size());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@RequestBody Map<String, String> body, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        String name = body.get("name");
        Tags tag = tagsService.createTag(userId, name);
        return Map.of("id", tag.getId().toString(), "name", tag.getName(), "created_at", tag.getCreatedAt());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        tagsService.deleteTag(userId, UUID.fromString(id));
    }

    @GetMapping("/{id}/notes")
    public Map<String, Object> listNotes(@PathVariable String id,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return tagsService.listTagNotes(userId, UUID.fromString(id), limit, offset);
    }
}
