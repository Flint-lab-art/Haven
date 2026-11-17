package com.haven.backend.auth.controller;

import com.haven.backend.auth.dto.AuthDtos.ApiTokenCreated;
import com.haven.backend.auth.dto.AuthDtos.ApiTokenList;
import com.haven.backend.auth.dto.CreateTokenRequest;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.interceptor.RequireAccess;
import com.haven.backend.auth.interceptor.RequiredAccess;
import com.haven.backend.auth.service.ApiTokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * API Token 管理（docs/api.md 第五节）。
 * <p>
 * 仅限已通过动态码验证的浏览器会话；API Token 本身不能管理 Token。
 */
@RequireAccess(RequiredAccess.SESSION_TOTP)
@RestController
@RequestMapping("/api/tokens")
@RequiredArgsConstructor
public class ApiTokensController {

    private final ApiTokenService apiTokenService;

    @GetMapping
    public ApiTokenList list(HttpServletRequest request) {
        String userId = AuthInterceptor.getUserId(request);
        return apiTokenService.listTokens(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiTokenCreated create(@Valid @RequestBody CreateTokenRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.getUserId(request);
        return apiTokenService.createToken(userId, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.getUserId(request);
        apiTokenService.revokeToken(userId, id);
    }
}
