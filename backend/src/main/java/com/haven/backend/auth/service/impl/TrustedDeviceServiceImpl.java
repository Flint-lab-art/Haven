package com.haven.backend.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.audit.AuditEventType;
import com.haven.backend.audit.AuditRecorder;
import com.haven.backend.audit.AuditTargetType;
import com.haven.backend.auth.dto.AuthDtos.TrustedDeviceList;
import com.haven.backend.auth.dto.AuthDtos.TrustedDeviceSummary;
import com.haven.backend.auth.entity.TrustedDevices;
import com.haven.backend.auth.mapper.TrustedDevicesMapper;
import com.haven.backend.auth.service.TrustedDeviceService;
import com.haven.backend.auth.util.ApiTokenUtil;
import com.haven.backend.exception.BizException;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TrustedDeviceServiceImpl implements TrustedDeviceService {

    private final TrustedDevicesMapper trustedDevicesMapper;
    private final AuditRecorder auditRecorder;
    private final Clock clock;

    @Override
    public boolean isTrusted(String userId, String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            return false;
        }

        TrustedDevices device = trustedDevicesMapper.selectOne(
                new LambdaQueryWrapper<TrustedDevices>().eq(TrustedDevices::getTokenHash, ApiTokenUtil.hash(rawToken)));
        if (device == null || !device.getUserId().equals(UUID.fromString(userId))) {
            return false;
        }

        OffsetDateTime now = OffsetDateTime.now(clock);
        if (!device.getExpiresAt().isAfter(now)) {
            trustedDevicesMapper.deleteById(device.getId());
            return false;
        }

        device.setLastUsedAt(now);
        trustedDevicesMapper.updateById(device);
        return true;
    }

    @Override
    @Transactional
    public String create(String userId, String userAgent) {
        String rawToken = ApiTokenUtil.randomToken();
        OffsetDateTime now = OffsetDateTime.now(clock);

        TrustedDevices device = new TrustedDevices();
        device.setId(UUID.randomUUID());
        device.setUserId(UUID.fromString(userId));
        device.setDeviceName(deviceNameFromUserAgent(userAgent));
        device.setTokenHash(ApiTokenUtil.hash(rawToken));
        device.setCreatedAt(now);
        device.setLastUsedAt(now);
        device.setExpiresAt(now.plusDays(TRUST_DAYS));
        trustedDevicesMapper.insert(device);

        // 顺手清理该用户已过期的授信设备
        trustedDevicesMapper.delete(new LambdaQueryWrapper<TrustedDevices>()
                .eq(TrustedDevices::getUserId, device.getUserId())
                .le(TrustedDevices::getExpiresAt, now));

        auditRecorder.record(
                device.getUserId(),
                null,
                AuditEventType.TRUSTED_DEVICE_ADDED,
                AuditTargetType.TRUSTED_DEVICE,
                device.getId(),
                null,
                userAgent);
        return rawToken;
    }

    @Override
    public TrustedDeviceList listDevices(String userId) {
        List<TrustedDevices> devices = trustedDevicesMapper.selectList(new LambdaQueryWrapper<TrustedDevices>()
                .eq(TrustedDevices::getUserId, UUID.fromString(userId))
                .gt(TrustedDevices::getExpiresAt, OffsetDateTime.now(clock))
                .orderByDesc(TrustedDevices::getCreatedAt));

        List<TrustedDeviceSummary> result = new ArrayList<>();
        for (TrustedDevices device : devices) {
            result.add(new TrustedDeviceSummary(
                    device.getId(),
                    device.getDeviceName(),
                    device.getCreatedAt(),
                    device.getLastUsedAt(),
                    device.getExpiresAt()));
        }
        return new TrustedDeviceList(result, result.size());
    }

    @Override
    public void revoke(String userId, UUID deviceId) {
        TrustedDevices device = trustedDevicesMapper.selectOne(new LambdaQueryWrapper<TrustedDevices>()
                .eq(TrustedDevices::getId, deviceId)
                .eq(TrustedDevices::getUserId, UUID.fromString(userId)));
        if (device == null) {
            throw BizException.notFound("授信设备不存在");
        }
        trustedDevicesMapper.deleteById(deviceId);
        auditRecorder.record(
                UUID.fromString(userId),
                null,
                AuditEventType.TRUSTED_DEVICE_REVOKED,
                AuditTargetType.TRUSTED_DEVICE,
                deviceId,
                null,
                null);
    }

    @Override
    public void revokeAll(String userId) {
        trustedDevicesMapper.delete(
                new LambdaQueryWrapper<TrustedDevices>().eq(TrustedDevices::getUserId, UUID.fromString(userId)));
    }

    /** 从 UA 提取一个简短设备名，规则与前端 deviceLabel 保持一致。 */
    static String deviceNameFromUserAgent(String ua) {
        if (ua == null || ua.isBlank()) {
            return "未知设备";
        }

        String browser = "";
        if (ua.contains("Edg/")) {
            browser = "Edge";
        } else if (ua.contains("Firefox/")) {
            browser = "Firefox";
        } else if (ua.contains("Chrome/")) {
            browser = "Chrome";
        } else if (ua.contains("Safari/")) {
            browser = "Safari";
        } else if (ua.contains("curl/")) {
            browser = "curl";
        }

        String os = "";
        if (ua.contains("Mac OS X")) {
            os = "macOS";
        } else if (ua.contains("Windows")) {
            os = "Windows";
        } else if (ua.contains("Android")) {
            os = "Android";
        } else if (ua.contains("iPhone") || ua.contains("iPad")) {
            os = "iOS";
        } else if (ua.contains("Linux")) {
            os = "Linux";
        }

        if (!os.isEmpty() || !browser.isEmpty()) {
            return (os + " · " + browser).replaceAll("^ · | · $", "");
        }
        return ua.length() > 40 ? ua.substring(0, 40) : ua;
    }
}
