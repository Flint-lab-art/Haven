package com.haven.backend.issue.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.issue.dto.CreateIssueRequest;
import com.haven.backend.issue.dto.IssueDtos.IssueDetail;
import com.haven.backend.issue.dto.IssueDtos.IssuePage;
import com.haven.backend.issue.dto.IssueDtos.IssueResponse;
import com.haven.backend.issue.dto.UpdateIssueRequest;
import com.haven.backend.issue.service.IssuesService;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/issues")
@RequiredArgsConstructor
public class IssuesController {

    private final IssuesService issuesService;

    @GetMapping
    public IssuePage list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return issuesService.listIssues(userId, status, limit, offset);
    }

    @GetMapping("/{id}")
    public IssueDetail get(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return issuesService.getIssue(userId, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public IssueResponse create(@Valid @RequestBody CreateIssueRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return issuesService.createIssue(userId, req);
    }

    @PatchMapping("/{id}")
    public IssueResponse update(
            @PathVariable UUID id, @Valid @RequestBody UpdateIssueRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return issuesService.updateIssue(userId, id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        issuesService.deleteIssue(userId, id);
    }
}
