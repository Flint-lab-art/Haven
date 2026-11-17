package com.haven.backend.stats.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.haven.backend.issue.mapper.IssuesMapper;
import com.haven.backend.note.entity.Folders;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.stats.dto.StatsDtos.StatsSnapshot;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * 统计聚合测试：热力图按 GROUP BY 结果补齐 152 天，文件夹与 issue 统计来自单条聚合查询。
 */
@ExtendWith(MockitoExtension.class)
class StatsServiceImplTest {

    @Mock
    private NotesMapper notesMapper;

    @Mock
    private FoldersMapper foldersMapper;

    @Mock
    private IssuesMapper issuesMapper;

    @Mock
    private Clock clock;

    @InjectMocks
    private StatsServiceImpl statsService;

    @org.junit.jupiter.api.BeforeEach
    void setUpClock() {
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        when(clock.instant()).thenReturn(Instant.parse("2026-01-02T03:04:05Z"));
    }

    @Test
    @DisplayName("热力图固定 152 天，缺失的日期补 0")
    void heatmapFillsMissingDays() {
        LocalDate today = LocalDate.ofInstant(Instant.parse("2026-01-02T03:04:05Z"), ZoneOffset.UTC);
        when(notesMapper.countByUpdatedDay(any(), any(), any(), any()))
                .thenReturn(List.of(new NotesMapper.DailyCount(today, 3)));
        when(notesMapper.sumContentLength(any())).thenReturn(0L);
        when(notesMapper.countByFolder(any())).thenReturn(List.of());
        when(foldersMapper.selectList(any())).thenReturn(List.of());
        when(issuesMapper.countByStatus(any())).thenReturn(List.of());

        StatsSnapshot stats = statsService.getStats(UUID.randomUUID().toString());

        var heatmap = stats.heatmap();
        assertEquals(152, heatmap.size());
        assertEquals(3L, heatmap.get(151).count());
        assertEquals(0L, heatmap.get(0).count());
    }

    @Test
    @DisplayName("文件夹笔记数来自聚合结果，没有笔记的文件夹为 0")
    void folderStatsUseAggregatedCounts() {
        UUID folderId = UUID.randomUUID();
        Folders folder = new Folders().setId(folderId).setName("工作").setSortOrder(0);
        Folders empty = new Folders().setId(UUID.randomUUID()).setName("空").setSortOrder(1);
        when(notesMapper.countByFolder(any())).thenReturn(List.of(new NotesMapper.FolderCount(folderId, 7)));
        when(notesMapper.sumContentLength(any())).thenReturn(0L);
        when(notesMapper.countByUpdatedDay(any(), any(), any(), any())).thenReturn(List.of());
        when(foldersMapper.selectList(any())).thenReturn(List.of(folder, empty));
        when(issuesMapper.countByStatus(any())).thenReturn(List.of());

        StatsSnapshot stats = statsService.getStats(UUID.randomUUID().toString());

        var folders = stats.folders();
        assertEquals(7L, folders.get(0).count());
        assertEquals(0L, folders.get(1).count());
    }

    @Test
    @DisplayName("issue 状态统计的 total 等于各状态之和")
    void issueTotalsSumStatuses() {
        when(issuesMapper.countByStatus(any()))
                .thenReturn(List.of(
                        new IssuesMapper.StatusCount("todo", 2),
                        new IssuesMapper.StatusCount("in_progress", 1),
                        new IssuesMapper.StatusCount("done", 4)));
        when(notesMapper.sumContentLength(any())).thenReturn(0L);
        when(notesMapper.countByUpdatedDay(any(), any(), any(), any())).thenReturn(List.of());
        when(notesMapper.countByFolder(any())).thenReturn(List.of());
        when(foldersMapper.selectList(any())).thenReturn(List.of());

        StatsSnapshot stats = statsService.getStats(UUID.randomUUID().toString());

        var issues = stats.issues();
        assertEquals(7L, issues.total());
        assertEquals(2L, issues.todo());
        assertEquals(1L, issues.inProgress());
        assertEquals(4L, issues.done());
    }
}
