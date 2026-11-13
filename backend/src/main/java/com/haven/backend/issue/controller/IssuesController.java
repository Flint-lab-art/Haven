package com.haven.backend.issue.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.issue.service.IssuesService;
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
        String userId = AuthInterceptor.requireUserId(request);
        return issuesService.listIssues(userId, status, limit, offset);
    }

    @GetMapping("/{id}")
    public Map<String, Object> get(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return issuesService.getIssue(userId, UUID.fromString(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        String title = (String) body.get("title");
        String description = (String) body.get("description");
        String type = (String) body.get("type");
        String status = (String) body.get("status");
        String priority = (String) body.get("priority");
        return issuesService.createIssue(userId, title, description, type, status, priority);
    }

    @PatchMapping("/{id}")
    public Map<String, Object> update(@PathVariable String id, @RequestBody Map<String, Object> body,
                                      HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        UUID issueId = UUID.fromString(id);
        String title = body.containsKey("title") ? (String) body.get("title") : null;
        String description = body.containsKey("description") ? (String) body.get("description") : null;
        String type = body.containsKey("type") ? (String) body.get("type") : null;
        String status = body.containsKey("status") ? (String) body.get("status") : null;
        String priority = body.containsKey("priority") ? (String) body.get("priority") : null;

        return issuesService.updateIssue(userId, issueId, title, description, type, status, priority);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        issuesService.deleteIssue(userId, UUID.fromString(id));
    }
}
