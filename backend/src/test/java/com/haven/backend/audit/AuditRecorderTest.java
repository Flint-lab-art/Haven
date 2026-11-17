package com.haven.backend.audit;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.haven.backend.auth.entity.AuditEvents;
import com.haven.backend.auth.mapper.AuditEventsMapper;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataAccessResourceFailureException;

/**
 * 审计记录器：事件字段映射正确，写入失败不得影响主流程。
 */
@ExtendWith(MockitoExtension.class)
class AuditRecorderTest {

    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-01-02T03:04:05Z"), ZoneOffset.UTC);

    @Mock
    private AuditEventsMapper auditEventsMapper;

    @Test
    @DisplayName("事件类型与目标类型按 CHECK 约束的字符串落库")
    void recordsEventWithEnumValues() {
        AuditRecorder recorder = new AuditRecorder(auditEventsMapper, CLOCK);
        UUID userId = UUID.randomUUID();

        recorder.record(
                userId,
                "alice",
                AuditEventType.TOKEN_CREATED,
                AuditTargetType.TOKEN,
                UUID.randomUUID(),
                "1.2.3.4",
                "ua");

        ArgumentCaptor<AuditEvents> captor = ArgumentCaptor.forClass(AuditEvents.class);
        verify(auditEventsMapper).insert(captor.capture());
        AuditEvents saved = captor.getValue();
        assertEquals("token_created", saved.getEventType());
        assertEquals("token", saved.getTargetType());
        assertEquals("alice", saved.getActorUsername());
        assertEquals("1.2.3.4", saved.getIp());
        assertEquals(java.time.OffsetDateTime.ofInstant(CLOCK.instant(), ZoneOffset.UTC), saved.getCreatedAt());
    }

    @Test
    @DisplayName("数据库异常被吞掉，不影响主流程")
    void failureDoesNotPropagate() {
        when(auditEventsMapper.insert(any(AuditEvents.class)))
                .thenThrow(new DataAccessResourceFailureException("db down"));
        AuditRecorder recorder = new AuditRecorder(auditEventsMapper, CLOCK);

        assertDoesNotThrow(() -> recorder.record(null, "bob", AuditEventType.LOGIN_FAILURE, null, null, null, null));
    }

    @Test
    @DisplayName("未提供用户名/IP 时落空串，满足 NOT NULL 约束")
    void blanksNullFields() {
        AuditRecorder recorder = new AuditRecorder(auditEventsMapper, CLOCK);

        recorder.record(null, null, AuditEventType.LOGIN_FAILURE, null, null, null, null);

        ArgumentCaptor<AuditEvents> captor = ArgumentCaptor.forClass(AuditEvents.class);
        verify(auditEventsMapper).insert(captor.capture());
        assertEquals("", captor.getValue().getActorUsername());
        assertEquals("", captor.getValue().getIp());
        assertEquals("", captor.getValue().getUserAgent());
    }
}
