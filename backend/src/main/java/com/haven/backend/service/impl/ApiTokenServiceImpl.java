package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.dto.CreateTokenRequest;
import com.haven.backend.entity.Tokens;
import com.haven.backend.exception.BizException;
import com.haven.backend.mapper.TokensMapper;
import com.haven.backend.service.ApiTokenService;
import com.haven.backend.util.ApiTokenUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;

/**
 * API Token 管理服务实现。
 * <p>
 * Token 明文仅在创建时返回一次；数据库只存 SHA-256 哈希与展示前缀。
 * 撤销 = 写 revoked_at，不删行。
 */
@Service
@RequiredArgsConstructor
public class ApiTokenServiceImpl implements ApiTokenService {

    private final TokensMapper tokensMapper;

    @Override
    public List<Map<String, Object>> listTokens(String userId) {
        List<Tokens> tokens = tokensMapper.selectList(
                new LambdaQueryWrapper<Tokens>()
                        .eq(Tokens::getUserId, UUID.fromString(userId))
                        .orderByDesc(Tokens::getCreatedAt));

        List<Map<String, Object>> result = new ArrayList<>();
        for (Tokens t : tokens) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", t.getId().toString());
            item.put("name", t.getName());
            item.put("token_prefix", t.getTokenPrefix());
            item.put("scope", t.getScope());
            item.put("expires_at", t.getExpiresAt());
            item.put("last_used_at", t.getLastUsedAt());
            item.put("revoked_at", t.getRevokedAt());
            item.put("created_at", t.getCreatedAt());
            result.add(item);
        }
        return result;
    }

    @Override
    @Transactional
    public Map<String, Object> createToken(String userId, CreateTokenRequest req) {
        String[] tokenAndPrefix = ApiTokenUtil.generate(req.getScope());
        String token = tokenAndPrefix[0];
        String prefix = tokenAndPrefix[1];

        Tokens entity = new Tokens();
        entity.setId(UUID.randomUUID());
        entity.setUserId(UUID.fromString(userId));
        entity.setName(req.getName());
        entity.setTokenHash(ApiTokenUtil.hash(token));
        entity.setTokenPrefix(prefix);
        entity.setScope(req.getScope());
        entity.setExpiresAt(req.getExpiresAt());
        entity.setCreatedAt(OffsetDateTime.now());
        tokensMapper.insert(entity);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", entity.getId().toString());
        result.put("name", entity.getName());
        result.put("token_prefix", prefix);
        result.put("scope", entity.getScope());
        result.put("expires_at", entity.getExpiresAt());
        result.put("last_used_at", null);
        result.put("revoked_at", null);
        result.put("created_at", entity.getCreatedAt());
        // 明文只在这里返回一次
        result.put("token", token);
        return result;
    }

    @Override
    @Transactional
    public void revokeToken(String userId, String tokenId) {
        UUID id;
        try {
            id = UUID.fromString(tokenId);
        } catch (IllegalArgumentException e) {
            throw BizException.notFound("Token 不存在");
        }
        Tokens token = tokensMapper.selectOne(
                new LambdaQueryWrapper<Tokens>()
                        .eq(Tokens::getId, id)
                        .eq(Tokens::getUserId, UUID.fromString(userId)));
        if (token == null) {
            throw BizException.notFound("Token 不存在");
        }
        if (token.getRevokedAt() != null) {
            throw BizException.validation("Token 已撤销");
        }
        token.setRevokedAt(OffsetDateTime.now());
        tokensMapper.updateById(token);
    }
}
