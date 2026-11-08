package com.haven.backend.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.entity.Tags;
import com.haven.backend.interceptor.AuthInterceptor;
import com.haven.backend.service.TagsService;
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
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        List<Map<String, Object>> tags = tagsService.listTags(userId);
        return Map.of("items", tags, "total", tags.size());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@RequestBody Map<String, String> body, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        String name = body.get("name");
        Tags tag = tagsService.createTag(userId, name);
        return Map.of("id", tag.getId().toString(), "name", tag.getName(), "created_at", tag.getCreatedAt());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        tagsService.deleteTag(userId, UUID.fromString(id));
    }

    @GetMapping("/{id}/notes")
    public Map<String, Object> listNotes(@PathVariable String id,
                                         @RequestParam(defaultValue = "20") int limit,
                                         @RequestParam(defaultValue = "0") int offset,
                                         HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        return tagsService.listTagNotes(userId, UUID.fromString(id), limit, offset);
    }
}
