package com.haven.backend.stats.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.issue.entity.Issues;
import com.haven.backend.issue.mapper.IssuesMapper;
import com.haven.backend.note.entity.Folders;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.stats.dto.StatsDtos.FolderStat;
import com.haven.backend.stats.dto.StatsDtos.HeatmapCell;
import com.haven.backend.stats.dto.StatsDtos.RecentNote;
import com.haven.backend.stats.dto.StatsDtos.StatsIssues;
import com.haven.backend.stats.dto.StatsDtos.StatsRecentIssue;
import com.haven.backend.stats.dto.StatsDtos.StatsSnapshot;
import com.haven.backend.stats.dto.StatsDtos.StatsTotals;
import com.haven.backend.stats.dto.StatsDtos.StatsWeek;
import com.haven.backend.stats.service.StatsService;
import java.time.Clock;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 统计服务。
 * <p>
 * 所有聚合下推到 SQL（GROUP BY / SUM），不再按天、按文件夹逐条 COUNT，
 * 也不再为统计字数把全部笔记正文加载进内存。
 */
@Service
@RequiredArgsConstructor
public class StatsServiceImpl implements StatsService {

    /** 热力图窗口天数。 */
    private static final int HEATMAP_DAYS = 152;
    /** 最近笔记 / 最近 issue 条数。 */
    private static final int RECENT_LIMIT = 5;

    private static final String STATUS_TODO = "todo";
    private static final String STATUS_IN_PROGRESS = "in_progress";
    private static final String STATUS_DONE = "done";

    private final NotesMapper notesMapper;
    private final FoldersMapper foldersMapper;
    private final IssuesMapper issuesMapper;
    private final Clock clock;

    @Override
    @Transactional(readOnly = true)
    public StatsSnapshot getStats(String userId) {
        UUID uid = UUID.fromString(userId);
        OffsetDateTime now = OffsetDateTime.now(clock);
        OffsetDateTime weekAgo = now.minusDays(7);

        return new StatsSnapshot(
                buildTotals(uid),
                buildWeek(uid, weekAgo),
                buildHeatmap(uid, now),
                buildRecentNotes(uid),
                buildFolderStats(uid),
                buildIssuesStat(uid));
    }

    private StatsTotals buildTotals(UUID uid) {
        long totalNotes = notesMapper.selectCount(
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid).isNull(Notes::getDeletedAt));
        long totalWords = notesMapper.sumContentLength(uid);
        return new StatsTotals(totalNotes, totalWords);
    }

    private StatsWeek buildWeek(UUID uid, OffsetDateTime weekAgo) {
        long createdWeek = notesMapper.selectCount(new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid)
                .ge(Notes::getCreatedAt, weekAgo)
                .isNull(Notes::getDeletedAt));
        long updatedWeek = notesMapper.selectCount(new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid)
                .ge(Notes::getUpdatedAt, weekAgo)
                .isNull(Notes::getDeletedAt));
        return new StatsWeek(createdWeek, updatedWeek);
    }

    /** 一次 GROUP BY 查出窗口内每天的更新数，再补齐没有数据的天。 */
    private List<HeatmapCell> buildHeatmap(UUID uid, OffsetDateTime now) {
        ZoneId zone = clock.getZone();
        LocalDate today = now.atZoneSameInstant(zone).toLocalDate();
        LocalDate start = today.minusDays(HEATMAP_DAYS - 1);
        // 日界以业务时区为准；转成 UTC 查询值后再与 timestamptz 比较
        OffsetDateTime from = start.atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = today.plusDays(1).atStartOfDay(zone).toOffsetDateTime();

        Map<LocalDate, Long> counts = notesMapper.countByUpdatedDay(uid, from, to, zone.getId()).stream()
                .collect(Collectors.toMap(NotesMapper.DailyCount::day, NotesMapper.DailyCount::cnt));

        List<HeatmapCell> heatmap = new ArrayList<>(HEATMAP_DAYS);
        for (int i = 0; i < HEATMAP_DAYS; i++) {
            LocalDate day = start.plusDays(i);
            heatmap.add(new HeatmapCell(day.toString(), counts.getOrDefault(day, 0L)));
        }
        return heatmap;
    }

    private List<RecentNote> buildRecentNotes(UUID uid) {
        List<Notes> recent = notesMapper.selectList(new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid)
                .isNull(Notes::getDeletedAt)
                .orderByDesc(Notes::getUpdatedAt)
                .last("LIMIT " + RECENT_LIMIT));
        return recent.stream()
                .map(n -> new RecentNote(n.getId(), n.getTitle(), n.getUpdatedAt()))
                .collect(Collectors.toList());
    }

    /** 一次 GROUP BY 查出各文件夹笔记数，避免每个文件夹一次 COUNT。 */
    private List<FolderStat> buildFolderStats(UUID uid) {
        List<Folders> folders = foldersMapper.selectList(
                new LambdaQueryWrapper<Folders>().eq(Folders::getUserId, uid).orderByAsc(Folders::getSortOrder));
        Map<UUID, Long> counts = notesMapper.countByFolder(uid).stream()
                .collect(Collectors.toMap(NotesMapper.FolderCount::folderId, NotesMapper.FolderCount::cnt));

        return folders.stream()
                .map(f -> new FolderStat(f.getId(), f.getName(), counts.getOrDefault(f.getId(), 0L)))
                .collect(Collectors.toList());
    }

    /** 一次 GROUP BY 查出各状态数量。 */
    private StatsIssues buildIssuesStat(UUID uid) {
        Map<String, Long> byStatus = issuesMapper.countByStatus(uid).stream()
                .collect(Collectors.toMap(IssuesMapper.StatusCount::status, IssuesMapper.StatusCount::cnt));
        long total = byStatus.values().stream().mapToLong(Long::longValue).sum();

        List<Issues> recentIssues = issuesMapper.selectList(new LambdaQueryWrapper<Issues>()
                .eq(Issues::getUserId, uid)
                .ne(Issues::getStatus, STATUS_DONE)
                .orderByDesc(Issues::getUpdatedAt)
                .last("LIMIT " + RECENT_LIMIT));
        List<StatsRecentIssue> recentIssueList = recentIssues.stream()
                .map(i -> new StatsRecentIssue(
                        i.getId(),
                        i.getTitle(),
                        i.getType(),
                        i.getStatus(),
                        i.getPriority(),
                        i.getUpdatedAt(),
                        null,
                        null))
                .toList();

        return new StatsIssues(
                total,
                byStatus.getOrDefault(STATUS_TODO, 0L),
                byStatus.getOrDefault(STATUS_IN_PROGRESS, 0L),
                byStatus.getOrDefault(STATUS_DONE, 0L),
                recentIssueList);
    }
}
