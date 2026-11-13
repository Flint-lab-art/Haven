package com.haven.backend.auth.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.service.SessionService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 会话管理（docs/api.md 第三节）：仅浏览器会话可用，API Token 返回 403。
 */
@RestController
@RequestMapping("/api/sessions")
@RequiredArgsConstructor
public class SessionsController {

    private final SessionService sessionService;

    @GetMapping
    public Map<String, Object> list(HttpServletRequest request) {
        AuthInterceptor.requireSession(request);
        String userId = AuthInterceptor.getUserId(request);
        List<Map<String, Object>> items = sessionService.listSessions(userId);
        return Map.of("items", items, "total", items.size());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable String id, HttpServletRequest request) {
        AuthInterceptor.requireSession(request);
        String userId = AuthInterceptor.getUserId(request);
        sessionService.revokeSession(userId, id);
    }
}
