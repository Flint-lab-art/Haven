package com.haven.backend.note.mapper;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

/**
 * 聚合查询的 SQL 冒烟测试：验证 GROUP BY / SUM / 时区表达式在 PostgreSQL 上可执行且结果正确。
 * <p>
 * 与 {@code LedgerSmokeTest} 一样依赖本地 dev 库（测试整体被事务回滚）。
 */
@SpringBootTest
@org.springframework.test.context.ActiveProfiles("test")
@Transactional
class NotesMapperAggregationTest {

    @Autowired
    private NotesMapper notesMapper;

    @Autowired
    private com.haven.backend.issue.mapper.IssuesMapper issuesMapper;

    @Test
    @DisplayName("sumContentLength 可执行并返回非负数")
    void sumContentLengthRuns() {
        long sum = notesMapper.sumContentLength(UUID.randomUUID());

        assertTrue(sum >= 0);
    }

    @Test
    @DisplayName("countByUpdatedDay 按天聚合，时区参数可绑定")
    void countByUpdatedDayRuns() {
        ZoneId zone = ZoneId.systemDefault();
        LocalDate today = LocalDate.now(zone);
        OffsetDateTime from = today.minusDays(7).atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = today.plusDays(1).atStartOfDay(zone).toOffsetDateTime();

        List<NotesMapper.DailyCount> rows = notesMapper.countByUpdatedDay(UUID.randomUUID(), from, to, zone.getId());

        assertEquals(0, rows.size());
    }

    @Test
    @DisplayName("countByFolder 可执行")
    void countByFolderRuns() {
        assertTrue(notesMapper.countByFolder(UUID.randomUUID()).isEmpty());
    }

    @Test
    @DisplayName("countByStatus 可执行")
    void countByStatusRuns() {
        assertTrue(issuesMapper.countByStatus(UUID.randomUUID()).isEmpty());
    }

    @Test
    @DisplayName("selectTagsForNotes 的 IN 列表可绑定")
    void selectTagsForNotesRuns() {
        List<NoteTagsMapper.NoteTag> rows =
                noteTagsMapper.selectTagsForNotes(UUID.randomUUID(), List.of(UUID.randomUUID()));

        assertTrue(rows.isEmpty());
    }

    @Autowired
    private NoteTagsMapper noteTagsMapper;
}
