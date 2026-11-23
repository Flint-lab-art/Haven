package com.haven.backend.auth.controller;

import com.haven.backend.auth.dto.LoginLogDtos.LoginLogPage;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.interceptor.RequireAccess;
import com.haven.backend.auth.interceptor.RequiredAccess;
import com.haven.backend.auth.service.LoginLogService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 登录日志查询。 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class LoginLogController {

    private final LoginLogService loginLogService;

    /**
     * GET /api/auth/login-logs
     * <p>
     * 只允许浏览器会话读取，API Token 无法查看登录历史。
     */
    @GetMapping("/login-logs")
    @RequireAccess(RequiredAccess.SESSION)
    public LoginLogPage list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return loginLogService.list(userId, limit, offset);
    }
}
