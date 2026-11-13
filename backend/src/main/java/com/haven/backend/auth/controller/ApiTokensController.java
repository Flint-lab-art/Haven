package com.haven.backend.auth.controller;

import com.haven.backend.auth.dto.CreateTokenRequest;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.service.ApiTokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * API Token 管理（docs/api.md 第五节）。
 * <p>
 * 仅限已通过动态码验证的浏览器会话；API Token 本身不能管理 Token。
 */
@RestController
@RequestMapping("/api/tokens")
@RequiredArgsConstructor
public class ApiTokensController {

    private final ApiTokenService apiTokenService;

    @GetMapping
    public Map<String, Object> list(HttpServletRequest request) {
        AuthInterceptor.requireSessionTotp(request);
        String userId = AuthInterceptor.getUserId(request);
        List<Map<String, Object>> items = apiTokenService.listTokens(userId);
        return Map.of("items", items, "total", items.size());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@Valid @RequestBody CreateTokenRequest req,
                                      HttpServletRequest request) {
        AuthInterceptor.requireSessionTotp(request);
        String userId = AuthInterceptor.getUserId(request);
        return apiTokenService.createToken(userId, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable String id, HttpServletRequest request) {
        AuthInterceptor.requireSessionTotp(request);
        String userId = AuthInterceptor.getUserId(request);
        apiTokenService.revokeToken(userId, id);
    }
}
