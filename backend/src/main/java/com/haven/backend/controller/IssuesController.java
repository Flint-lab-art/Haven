package com.haven.backend.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.interceptor.AuthInterceptor;
import com.haven.backend.service.IssuesService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/issues")
@RequiredArgsConstructor
public class IssuesController {

    private final IssuesService issuesService;

    @GetMapping
    public Map<String, Object> list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        return issuesService.listIssues(userId, status, limit, offset);
    }

    @GetMapping("/{id}")
    public Map<String, Object> get(@PathVariable String id, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        return issuesService.getIssue(userId, UUID.fromString(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        String title = (String) body.get("title");
        String description = (String) body.get("description");
        String type = (String) body.get("type");
        String status = (String) body.get("status");
        String priority = (String) body.get("priority");
        UUID parentId = body.get("parent_id") != null ? UUID.fromString(body.get("parent_id").toString()) : null;
        return issuesService.createIssue(userId, title, description, type, status, priority, parentId);
    }

    @PatchMapping("/{id}")
    public Map<String, Object> update(@PathVariable String id, @RequestBody Map<String, Object> body,
                                      HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        UUID issueId = UUID.fromString(id);
        String title = body.containsKey("title") ? (String) body.get("title") : null;
        String description = body.containsKey("description") ? (String) body.get("description") : null;
        String type = body.containsKey("type") ? (String) body.get("type") : null;
        String status = body.containsKey("status") ? (String) body.get("status") : null;
        String priority = body.containsKey("priority") ? (String) body.get("priority") : null;
        UUID parentId = null;
        if (body.containsKey("parent_id")) {
            parentId = body.get("parent_id") != null ? UUID.fromString(body.get("parent_id").toString()) : null;
        }
        return issuesService.updateIssue(userId, issueId, title, description, type, status, priority, parentId);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        issuesService.deleteIssue(userId, UUID.fromString(id));
    }
}
