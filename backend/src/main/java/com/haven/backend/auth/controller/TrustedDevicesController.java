package com.haven.backend.auth.controller;

import com.haven.backend.exception.BizException;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.service.TrustedDeviceService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 授信设备（docs/api.md 第四节）：不提供创建接口，只能在登录时 trust_device。
 */
@RestController
@RequestMapping("/api/trusted-devices")
@RequiredArgsConstructor
public class TrustedDevicesController {

    private final TrustedDeviceService trustedDeviceService;

    @GetMapping
    public Map<String, Object> list(HttpServletRequest request) {
        AuthInterceptor.requireSession(request);
        String userId = AuthInterceptor.getUserId(request);
        List<Map<String, Object>> items = trustedDeviceService.listDevices(userId);
        return Map.of("items", items, "total", items.size());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable String id, HttpServletRequest request) {
        AuthInterceptor.requireSession(request);
        String userId = AuthInterceptor.getUserId(request);
        trustedDeviceService.revoke(userId, parseId(id));
    }

    private UUID parseId(String id) {
        try {
            return UUID.fromString(id);
        } catch (IllegalArgumentException e) {
            throw BizException.notFound("授信设备不存在");
        }
    }
}
