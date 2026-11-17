package com.haven.backend.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.audit.AuditEventType;
import com.haven.backend.audit.AuditRecorder;
import com.haven.backend.audit.AuditTargetType;
import com.haven.backend.auth.dto.AuthDtos.ApiTokenCreated;
import com.haven.backend.auth.dto.AuthDtos.ApiTokenList;
import com.haven.backend.auth.dto.AuthDtos.ApiTokenSummary;
import com.haven.backend.auth.dto.CreateTokenRequest;
import com.haven.backend.auth.entity.Tokens;
import com.haven.backend.auth.mapper.TokensMapper;
import com.haven.backend.auth.service.ApiTokenService;
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
    private final AuditRecorder auditRecorder;
    private final Clock clock;

    @Override
    public ApiTokenList listTokens(String userId) {
        List<Tokens> tokens = tokensMapper.selectList(new LambdaQueryWrapper<Tokens>()
                .eq(Tokens::getUserId, UUID.fromString(userId))
                .orderByDesc(Tokens::getCreatedAt));

        List<ApiTokenSummary> result = new ArrayList<>();
        for (Tokens t : tokens) {
            result.add(new ApiTokenSummary(
                    t.getId(),
                    t.getName(),
                    t.getTokenPrefix(),
                    t.getScope(),
                    t.getExpiresAt(),
                    t.getLastUsedAt(),
                    t.getRevokedAt(),
                    t.getCreatedAt()));
        }
        return new ApiTokenList(result, result.size());
    }

    @Override
    @Transactional
    public ApiTokenCreated createToken(String userId, CreateTokenRequest req) {
        String[] tokenAndPrefix = ApiTokenUtil.generate(req.scope());
        String token = tokenAndPrefix[0];
        String prefix = tokenAndPrefix[1];

        Tokens entity = new Tokens();
        entity.setId(UUID.randomUUID());
        entity.setUserId(UUID.fromString(userId));
        entity.setName(req.name());
        entity.setTokenHash(ApiTokenUtil.hash(token));
        entity.setTokenPrefix(prefix);
        entity.setScope(req.scope());
        entity.setExpiresAt(req.expiresAt());
        entity.setCreatedAt(OffsetDateTime.now(clock));
        tokensMapper.insert(entity);

        auditRecorder.record(
                entity.getUserId(),
                null, // 调用方已在会话中完成身份确认，这里只记录操作者 ID
                AuditEventType.TOKEN_CREATED,
                AuditTargetType.TOKEN,
                entity.getId(),
                null,
                null);
        // 明文只在这里返回一次
        return new ApiTokenCreated(
                entity.getId(),
                entity.getName(),
                prefix,
                entity.getScope(),
                entity.getExpiresAt(),
                entity.getCreatedAt(),
                token);
    }

    @Override
    @Transactional
    public void revokeToken(String userId, UUID tokenId) {
        Tokens token = tokensMapper.selectOne(new LambdaQueryWrapper<Tokens>()
                .eq(Tokens::getId, tokenId)
                .eq(Tokens::getUserId, UUID.fromString(userId)));
        if (token == null) {
            throw BizException.notFound("Token 不存在");
        }
        if (token.getRevokedAt() != null) {
            throw BizException.validation("Token 已撤销");
        }
        token.setRevokedAt(OffsetDateTime.now(clock));
        tokensMapper.updateById(token);
        auditRecorder.record(
                UUID.fromString(userId),
                null,
                AuditEventType.TOKEN_REVOKED,
                AuditTargetType.TOKEN,
                token.getId(),
                null,
                null);
    }

    @Override
    @Transactional
    public void revokeAllForUser(String userId) {
        Tokens patch = new Tokens();
        patch.setRevokedAt(OffsetDateTime.now(clock));
        tokensMapper.update(
                patch,
                new LambdaQueryWrapper<Tokens>()
                        .eq(Tokens::getUserId, UUID.fromString(userId))
                        .isNull(Tokens::getRevokedAt));
    }
}
