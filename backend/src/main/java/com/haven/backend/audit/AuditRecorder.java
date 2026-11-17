package com.haven.backend.audit;

import com.haven.backend.auth.entity.AuditEvents;
import com.haven.backend.auth.mapper.AuditEventsMapper;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 安全审计记录器。
 * <p>
 * 所有方法都是「尽力而为」：<b>审计写入失败只记日志，不影响主流程</b>。
 * 审计失败不应该让用户登录失败或改密失败，但也不能静默丢失，因此统一打 warn 日志。
 * <p>
 * 约束：绝不写入密码、Token 明文、TOTP secret 等敏感内容。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuditRecorder {

    private final AuditEventsMapper auditEventsMapper;
    private final Clock clock;

    /**
     * 记录一条审计事件。
     *
     * @param actorUserId 操作者，匿名事件（如登录失败）可为 null
     * @param actorUsername 用户名快照，账号删除后仍可追溯
     * @param type 事件类型
     * @param targetType 目标类型，没有具体目标时传 null
     * @param targetId 目标 ID，可为 null
     * @param ip 客户端 IP，可为 null
     * @param userAgent User-Agent，可为 null
     */
    public void record(
            UUID actorUserId,
            String actorUsername,
            AuditEventType type,
            AuditTargetType targetType,
            UUID targetId,
            String ip,
            String userAgent) {
        try {
            AuditEvents event = new AuditEvents();
            event.setId(UUID.randomUUID());
            event.setActorUserId(actorUserId);
            event.setActorUsername(actorUsername != null ? actorUsername : "");
            event.setEventType(type.value());
            event.setTargetType(targetType != null ? targetType.value() : null);
            event.setTargetId(targetId);
            event.setIp(ip != null ? ip : "");
            event.setUserAgent(userAgent != null ? userAgent : "");
            event.setCreatedAt(OffsetDateTime.now(clock));
            auditEventsMapper.insert(event);
        } catch (RuntimeException e) {
            // 审计是旁路能力：失败不阻断业务，但必须留痕
            log.warn("写入审计事件失败, type={}, actor={}", type.value(), actorUserId, e);
        }
    }
}
