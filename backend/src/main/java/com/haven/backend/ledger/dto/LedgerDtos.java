package com.haven.backend.ledger.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 记账模块的响应契约。
 * <p>
 * 字段名与前端 {@code frontend/src/api/ledger.ts} 对齐
 * （项目全局 Jackson 使用 SNAKE_CASE，这里的 record 组件名即 camelCase）。
 */
public final class LedgerDtos {

    private LedgerDtos() {}

    /** 账户。 */
    public record AccountDto(
            UUID id,
            String name,
            /** 图标 key；空串表示不显示。 */
            String icon,
            String type,
            long initialBalanceCents,
            /** 实时余额 = 期初 + 流水累计；credit 类为负数表示欠款。 */
            long balanceCents,
            int sortOrder,
            boolean archived) {}

    /** 分类（两级）。 */
    public record CategoryDto(
            short id,
            /** 一级分类为 null。 */
            Short parentId,
            String name,
            /** emoji 图标；空串表示没有。 */
            String icon,
            /** expense / income / transfer。 */
            String kind,
            int sortOrder,
            List<CategoryDto> children) {}

    /** 一条流水。 */
    public record LedgerEntryDto(
            UUID id,
            /** expense / income / transfer。 */
            String type,
            long amountCents,
            /** 支出 / 收入的分类；转账为 null。 */
            Short categoryId,
            String categoryName,
            /** 一级分类名，便于前端按大类分组时不用再查表。 */
            String rootCategoryName,
            /** 支出 / 收入的账户；转账时为转出账户。 */
            UUID accountId,
            String accountName,
            /** 转账的转入账户。 */
            UUID toAccountId,
            String toAccountName,
            String note,
            OffsetDateTime occurredAt,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt) {}

    /** 分页列表。 */
    public record LedgerEntryPage(List<LedgerEntryDto> items, long total) {}

    /** 某个月某个一级分类的支出合计。 */
    public record CategorySpend(short categoryId, String categoryName, long spentCents) {}

    /** 预算项：一级分类 + 预算 + 已花。 */
    public record BudgetItemDto(
            short categoryId,
            String categoryName,
            long amountCents,
            long spentCents,
            /** 剩余 = 预算 − 已花，可能为负。 */
            long remainingCents) {}

    /** 月度预算视图：总预算 = 各项之和。 */
    public record BudgetDto(String month, long totalBudgetCents, long totalSpentCents, List<BudgetItemDto> items) {}

    /** 月度汇总。 */
    public record LedgerSummaryDto(
            String month,
            OffsetDateTime from,
            OffsetDateTime to,
            long totalExpenseCents,
            long totalIncomeCents,
            /** 不含转账。 */
            long totalCount,
            /** 转账笔数，单独给出。 */
            long transferCount,
            List<CategorySpend> expenseByCategory,
            List<CategorySpend> incomeByCategory) {}

    /** 最近 N 天趋势。 */
    public record LedgerTrendDto(
            int days,
            OffsetDateTime from,
            OffsetDateTime to,
            long totalExpenseCents,
            long totalIncomeCents,
            long totalCount,
            List<DailyPoint> daily) {}

    /** 按天聚合点。 */
    public record DailyPoint(String date, long expenseCents, long incomeCents, long count) {}

    /**
     * 任意区间的统计。
     *
     * 区间由前端按「周 / 月 / 季 / 年」算好后传入，后端不关心粒度的语义，
     * 只负责在给定区间内聚合。这样加新粒度（比如「自定义区间」）不用改后端。
     *
     * `buckets` 是区间内按天切好的点（已补零），
     * 前端需要按月视图时自己把这些天合并即可——避免后端出两套分桶逻辑。
     */
    public record LedgerRangeStatsDto(
            OffsetDateTime from,
            OffsetDateTime to,
            long totalExpenseCents,
            long totalIncomeCents,
            long totalCount,
            long transferCount,
            List<CategorySpend> expenseByCategory,
            List<CategorySpend> incomeByCategory,
            List<DailyPoint> buckets) {}
}
