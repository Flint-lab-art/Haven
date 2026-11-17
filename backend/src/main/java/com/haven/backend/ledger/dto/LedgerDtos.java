package com.haven.backend.ledger.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 记账模块的响应契约。
 * <p>
 * 用一个文件集中定义所有对外 DTO，字段名与前端 {@code frontend/src/api/ledger.ts} 保持一致
 * （项目全局 Jackson 使用 SNAKE_CASE，这里的 record 组件名即 camelCase）。
 */
public final class LedgerDtos {

    private LedgerDtos() {}

    /** 单条记账记录。 */
    public record LedgerEntryDto(
            UUID id,
            String type,
            Long amountCents,
            String category,
            String note,
            OffsetDateTime occurredAt,
            String batchId,
            OffsetDateTime createdAt) {}

    /** 批次写入 / 回放结果。 */
    public record LedgerBatchDto(
            boolean created,
            String batchId,
            String rawText,
            OffsetDateTime createdAt,
            List<LedgerEntryDto> items,
            long total) {}

    /** 快捷指令一步记账结果：批次结果 + 本次解析的逐行错误。 */
    public record LedgerQuickCommitDto(LedgerBatchDto batch, List<LedgerParseError> errors) {}

    /** 分页列表。 */
    public record LedgerEntryPage(List<LedgerEntryDto> items, long total) {}

    /** 分类排行项。 */
    public record LedgerCategoryRank(String category, long amountCents, long count) {}

    /** 按天聚合点（无记录的日期补零）。 */
    public record LedgerDailyPoint(String date, long expenseCents, long incomeCents, long count) {}

    /** 月度汇总。 */
    public record LedgerSummaryDto(
            String month,
            OffsetDateTime from,
            OffsetDateTime to,
            long totalExpenseCents,
            long totalIncomeCents,
            long totalCount,
            List<LedgerCategoryRank> categoryRanking,
            List<LedgerCategoryRank> incomeCategoryRanking,
            List<LedgerDailyPoint> daily,
            List<LedgerEntryDto> recent) {}

    /** 最近 N 天趋势，字段与月度汇总一致，额外带 days。 */
    public record LedgerTrendDto(
            int days,
            OffsetDateTime from,
            OffsetDateTime to,
            long totalExpenseCents,
            long totalIncomeCents,
            long totalCount,
            List<LedgerCategoryRank> categoryRanking,
            List<LedgerCategoryRank> incomeCategoryRanking,
            List<LedgerDailyPoint> daily) {}

    /** 别名列表。 */
    public record LedgerAliasPage(List<LedgerAliasDto> items, long total) {}

    /** 单个别名。 */
    public record LedgerAliasDto(String alias, String category) {}

    /** 分类列表。 */
    public record LedgerCategoriesDto(List<String> items, long total) {}
}
