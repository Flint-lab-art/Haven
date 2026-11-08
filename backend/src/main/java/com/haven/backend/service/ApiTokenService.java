package com.haven.backend.service;

import com.haven.backend.dto.CreateTokenRequest;

import java.util.List;
import java.util.Map;

/**
 * API Token 管理服务接口。
 */
public interface ApiTokenService {

    /** 列出当前用户的全部 API Token（含已撤销，不含明文）。 */
    List<Map<String, Object>> listTokens(String userId);

    /** 创建 API Token，返回一次性明文。 */
    Map<String, Object> createToken(String userId, CreateTokenRequest req);

    /** 撤销 API Token（写 revoked_at，不删行）。 */
    void revokeToken(String userId, String tokenId);
}
