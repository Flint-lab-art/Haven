package com.haven.backend.auth.controller;

import com.haven.backend.auth.dto.AuthDtos.SessionList;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.interceptor.RequireAccess;
import com.haven.backend.auth.interceptor.RequiredAccess;
import com.haven.backend.auth.service.SessionService;
import jakarta.servlet.http.HttpServletRequest;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * 会话管理（docs/api.md 第三节）：仅浏览器会话可用，API Token 返回 403。
 */
@RequireAccess(RequiredAccess.SESSION)
@RestController
@RequestMapping("/api/sessions")
@RequiredArgsConstructor
public class SessionsController {

    private final SessionService sessionService;

    @GetMapping
    public SessionList list(HttpServletRequest request) {
        String userId = AuthInterceptor.getUserId(request);
        return sessionService.listSessions(userId);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.getUserId(request);
        sessionService.revokeSession(userId, id);
    }
}
