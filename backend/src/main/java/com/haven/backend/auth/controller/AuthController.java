package com.haven.backend.auth.controller;

import com.haven.backend.auth.dto.AuthDtos.LoginResponse;
import com.haven.backend.auth.dto.AuthDtos.MeResponse;
import com.haven.backend.auth.dto.AuthDtos.TotpSetupResponse;
import com.haven.backend.auth.dto.AuthDtos.TotpStatusResponse;
import com.haven.backend.auth.dto.LoginOutcome;
import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.dto.LoginTotpRequest;
import com.haven.backend.auth.dto.PasswordChangeRequest;
import com.haven.backend.auth.dto.TotpDisableRequest;
import com.haven.backend.auth.dto.TotpVerifyRequest;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.interceptor.RequireAccess;
import com.haven.backend.auth.interceptor.RequiredAccess;
import com.haven.backend.auth.service.AuthService;
import com.haven.backend.auth.service.TrustedDeviceService;
import com.haven.backend.auth.service.impl.AuthSessionOpener;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import java.time.Duration;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证相关接口。
 * <p>
 * 直接返回领域对象，不包统一信封；错误由全局异常处理器输出 {@code {error,message}}。
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    /** 登录入口：校验在事务内、建立会话在事务外。 */
    private final AuthSessionOpener authSessionOpener;

    // -----------------------------------------------------------------------
    // 登录 / 登出
    // -----------------------------------------------------------------------

    @PostMapping("/auth/login")
    public LoginResponse login(
            @Valid @RequestBody LoginRequest req, HttpServletRequest request, HttpServletResponse response) {
        String trustedDeviceToken = readCookie(request, TrustedDeviceService.COOKIE_NAME);
        LoginOutcome outcome = authSessionOpener.login(
                req, request.getRemoteAddr(), request.getHeader("User-Agent"), trustedDeviceToken);
        writeTrustedDeviceCookie(request, response, outcome.trustedDeviceToken());
        return outcome.body();
    }

    @PostMapping("/auth/login/totp")
    public LoginResponse loginTotp(
            @Valid @RequestBody LoginTotpRequest req, HttpServletRequest request, HttpServletResponse response) {
        LoginOutcome outcome =
                authSessionOpener.loginTotp(req, request.getRemoteAddr(), request.getHeader("User-Agent"));
        writeTrustedDeviceCookie(request, response, outcome.trustedDeviceToken());
        return outcome.body();
    }

    @PostMapping("/auth/logout")
    public void logout(HttpServletRequest request, HttpServletResponse response) {
        // 登出时一并清除授信设备 Cookie，避免「退出登录」后仍免动态码
        clearTrustedDeviceCookie(request, response);
        if (!AuthInterceptor.isSession(request)) {
            // API Token 没有会话可注销；Token 需走 DELETE /api/tokens/{id}
            return;
        }
        authService.logout(
                AuthInterceptor.getUserId(request), request.getRemoteAddr(), request.getHeader("User-Agent"));
    }

    // -----------------------------------------------------------------------
    // 当前身份
    // -----------------------------------------------------------------------

    @GetMapping("/me")
    @RequireAccess(RequiredAccess.READ)
    public MeResponse me(HttpServletRequest request) {
        // 该路径在 OPTIONAL_AUTH_PATHS 中：无凭证时按匿名返回，凭证有效时识别身份
        return authService.me(AuthInterceptor.getUserId(request), AuthInterceptor.getAuthType(request));
    }

    // -----------------------------------------------------------------------
    // TOTP 管理
    // -----------------------------------------------------------------------

    @PostMapping("/auth/totp/setup")
    @RequireAccess(RequiredAccess.SESSION)
    public TotpSetupResponse setupTotp(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return authService.setupTotp(userId);
    }

    @PostMapping("/auth/totp/verify")
    @RequireAccess(RequiredAccess.SESSION)
    public TotpStatusResponse verifyTotp(@Valid @RequestBody TotpVerifyRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        authService.verifyTotp(userId, req);
        return new TotpStatusResponse(true);
    }

    @PostMapping("/auth/totp/disable")
    @RequireAccess(RequiredAccess.SESSION)
    public TotpStatusResponse disableTotp(@Valid @RequestBody TotpDisableRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        authService.disableTotp(userId, req);
        return new TotpStatusResponse(false);
    }

    // -----------------------------------------------------------------------
    // 修改密码
    // -----------------------------------------------------------------------

    /** 改密会同时撤销授信设备与 API Token，属于敏感操作；要求会话且已完成动态码。 */
    @PostMapping("/auth/password")
    @RequireAccess(RequiredAccess.SESSION_TOTP)
    public void changePassword(@Valid @RequestBody PasswordChangeRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        authSessionOpener.changePassword(userId, req, request.getRemoteAddr(), request.getHeader("User-Agent"));
    }

    // -----------------------------------------------------------------------
    // 授信设备 Cookie
    // -----------------------------------------------------------------------

    private String readCookie(HttpServletRequest request, String name) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        for (Cookie cookie : cookies) {
            if (name.equals(cookie.getName())) {
                return cookie.getValue();
            }
        }
        return null;
    }

    private void writeTrustedDeviceCookie(HttpServletRequest request, HttpServletResponse response, String token) {
        if (token == null) {
            return;
        }
        boolean secure = request.isSecure() || "https".equalsIgnoreCase(request.getHeader("X-Forwarded-Proto"));
        ResponseCookie cookie = ResponseCookie.from(TrustedDeviceService.COOKIE_NAME, token)
                .httpOnly(true)
                .secure(secure)
                .sameSite("Lax")
                .path("/")
                .maxAge(Duration.ofDays(TrustedDeviceService.TRUST_DAYS))
                .build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
    }

    /** 让浏览器立即丢弃授信设备 Cookie。 */
    private void clearTrustedDeviceCookie(HttpServletRequest request, HttpServletResponse response) {
        boolean secure = request.isSecure() || "https".equalsIgnoreCase(request.getHeader("X-Forwarded-Proto"));
        ResponseCookie cookie = ResponseCookie.from(TrustedDeviceService.COOKIE_NAME, "")
                .httpOnly(true)
                .secure(secure)
                .sameSite("Lax")
                .path("/")
                .maxAge(Duration.ZERO)
                .build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
    }
}
