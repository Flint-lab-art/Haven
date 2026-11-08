package com.haven.backend.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.dto.*;
import com.haven.backend.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 认证相关接口。
 * <p>
 * 响应格式对齐 Go 端 API 契约（docs/api.md 第二节 + 第十二节），
 * 直接返回领域对象，不包 ApiResponse 信封。
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    // -----------------------------------------------------------------------
    // 登录 / 登出
    // -----------------------------------------------------------------------

    @PostMapping("/auth/login")
    public Map<String, Object> login(
            @Valid @RequestBody LoginRequest req,
            HttpServletRequest request) {
        return authService.login(req,
                request.getRemoteAddr(), request.getHeader("User-Agent"));
    }

    @PostMapping("/auth/login/totp")
    public Map<String, Object> loginTotp(
            @Valid @RequestBody LoginTotpRequest req,
            HttpServletRequest request) {
        return authService.loginTotp(req,
                request.getRemoteAddr(), request.getHeader("User-Agent"));
    }

    @PostMapping("/auth/logout")
    public void logout() {
        authService.logout();
    }

    // -----------------------------------------------------------------------
    // 当前身份
    // -----------------------------------------------------------------------

    @GetMapping("/me")
    public Map<String, Object> me() {
        String userId = null;
        try {
            userId = StpUtil.getLoginIdAsString();
        } catch (Exception ignored) {
        }
        return authService.me(userId);
    }

    // -----------------------------------------------------------------------
    // TOTP 管理
    // -----------------------------------------------------------------------

    @PostMapping("/auth/totp/setup")
    public Map<String, String> setupTotp() {
        String userId = StpUtil.getLoginIdAsString();
        return authService.setupTotp(userId);
    }

    @PostMapping("/auth/totp/verify")
    public Map<String, Object> verifyTotp(@Valid @RequestBody TotpVerifyRequest req) {
        String userId = StpUtil.getLoginIdAsString();
        authService.verifyTotp(userId, req);
        return Map.of("totp_enabled", true);
    }

    @PostMapping("/auth/totp/disable")
    public Map<String, Object> disableTotp(@Valid @RequestBody TotpDisableRequest req) {
        String userId = StpUtil.getLoginIdAsString();
        authService.disableTotp(userId, req);
        return Map.of("totp_enabled", false);
    }

    // -----------------------------------------------------------------------
    // 修改密码
    // -----------------------------------------------------------------------

    @PostMapping("/auth/password")
    public void changePassword(
            @Valid @RequestBody PasswordChangeRequest req,
            HttpServletRequest request) {
        String userId = StpUtil.getLoginIdAsString();
        authService.changePassword(userId, req,
                request.getRemoteAddr(), request.getHeader("User-Agent"));
    }
}
