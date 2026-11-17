package com.haven.backend.auth.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * 认证模块的响应契约。
 * <p>
 * 登录第一步/第二步共用 {@link LoginResponse}：{@code totpRequiresVerify} 为 true 时带 {@code tempToken}。
 */
public final class AuthDtos {

    private AuthDtos() {}

    /** 登录/当前身份里的用户简要信息。 */
    public record UserBrief(UUID id, String username) {}

    /** 登录响应。 */
    public record LoginResponse(UserBrief user, boolean totpRequired, String tempToken) {

        /** 附加第二步登录所需的临时令牌。 */
        public LoginResponse withTempToken(String token) {
            return new LoginResponse(user, totpRequired, token);
        }
    }

    /** GET /api/me 的响应。 */
    public record MeResponse(boolean anonymous, String authType, MeUser user) {}

    /** /api/me 里的用户信息（含是否启用动态码）。 */
    public record MeUser(UUID id, String username, boolean totpEnabled) {}

    /** TOTP 绑定信息。 */
    public record TotpSetupResponse(String secret, String otpauthUri) {}

    /** TOTP 状态。 */
    public record TotpStatusResponse(boolean totpEnabled) {}

    /** 会话列表项。 */
    public record SessionSummary(
            UUID id, String userAgent, OffsetDateTime createdAt, OffsetDateTime lastUsedAt, boolean isCurrent) {}

    /** 会话列表。 */
    public record SessionList(java.util.List<SessionSummary> items, long total) {}

    /** 授信设备。 */
    public record TrustedDeviceSummary(
            UUID id,
            String deviceName,
            OffsetDateTime createdAt,
            OffsetDateTime lastUsedAt,
            OffsetDateTime expiresAt) {}

    /** 授信设备列表。 */
    public record TrustedDeviceList(java.util.List<TrustedDeviceSummary> items, long total) {}

    /** API Token（不含明文）。 */
    public record ApiTokenSummary(
            UUID id,
            String name,
            String tokenPrefix,
            String scope,
            OffsetDateTime expiresAt,
            OffsetDateTime lastUsedAt,
            OffsetDateTime revokedAt,
            OffsetDateTime createdAt) {}

    /** 新建 Token 的返回：唯一一次带明文。 */
    public record ApiTokenCreated(
            UUID id,
            String name,
            String tokenPrefix,
            String scope,
            OffsetDateTime expiresAt,
            OffsetDateTime createdAt,
            String token) {}

    /** Token 列表。 */
    public record ApiTokenList(java.util.List<ApiTokenSummary> items, long total) {}
}
