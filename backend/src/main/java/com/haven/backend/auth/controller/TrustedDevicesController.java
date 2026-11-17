package com.haven.backend.auth.controller;

import com.haven.backend.auth.dto.AuthDtos.TrustedDeviceList;
import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.interceptor.RequireAccess;
import com.haven.backend.auth.interceptor.RequiredAccess;
import com.haven.backend.auth.service.TrustedDeviceService;
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
 * 授信设备（docs/api.md 第四节）：不提供创建接口，只能在登录时 trust_device。
 */
@RequireAccess(RequiredAccess.SESSION)
@RestController
@RequestMapping("/api/trusted-devices")
@RequiredArgsConstructor
public class TrustedDevicesController {

    private final TrustedDeviceService trustedDeviceService;

    @GetMapping
    public TrustedDeviceList list(HttpServletRequest request) {
        String userId = AuthInterceptor.getUserId(request);
        return trustedDeviceService.listDevices(userId);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.getUserId(request);
        trustedDeviceService.revoke(userId, id);
    }
}
