package com.haven.backend.stats.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 首页统计的响应契约，与前端 {@code frontend/src/api/stats.ts} 保持一致。
 */
public final class StatsDtos {

    private StatsDtos() {}

    /** 总量统计。 */
    public record StatsTotals(long notes, long words, long publicNotes) {}

    /** 本周动态。 */
    public record StatsWeek(long created, long updated) {}

    /** 热力图的一天。 */
    public record HeatmapCell(String date, long count) {}

    /** 最近编辑的一项。 */
    public record RecentNote(UUID id, String title, OffsetDateTime updatedAt, String visibility) {}

    /** 一个文件夹及其笔记数。 */
    public record FolderStat(UUID id, String name, long count) {}

    /** 仪表盘 Issue 概览里的一条未完成 Issue。 */
    public record StatsRecentIssue(
            UUID id,
            String title,
            String type,
            String status,
            String priority,
            OffsetDateTime updatedAt,
            UUID parentId,
            String parentTitle) {}

    /** Issue 汇总。 */
    public record StatsIssues(long total, long todo, long inProgress, long done, List<StatsRecentIssue> recent) {}

    /** GET /api/stats 的完整快照。 */
    public record StatsSnapshot(
            StatsTotals totals,
            StatsWeek week,
            List<HeatmapCell> heatmap,
            List<RecentNote> recent,
            List<FolderStat> folders,
            StatsIssues issues) {}
}
