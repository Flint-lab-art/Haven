package com.haven.backend.auth.service;

import com.haven.backend.auth.dto.AuthDtos.ApiTokenCreated;
import com.haven.backend.auth.dto.AuthDtos.ApiTokenList;
import com.haven.backend.auth.dto.CreateTokenRequest;
import java.util.UUID;

/**
 * API Token 管理服务接口。
 */
public interface ApiTokenService {

    /** 列出当前用户的全部 API Token（含已撤销，不含明文）。 */
    ApiTokenList listTokens(String userId);

    /** 创建 API Token，返回一次性明文。 */
    ApiTokenCreated createToken(String userId, CreateTokenRequest req);

    /** 撤销 API Token（写 revoked_at，不删行）。 */
    void revokeToken(String userId, UUID tokenId);

    /**
     * 撤销当前用户全部未撤销的 API Token。
     * <p>
     * 用于修改密码等凭据轮换场景，避免旧 Token 在密码失效后仍可访问。
     */
    void revokeAllForUser(String userId);
}
