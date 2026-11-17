package com.haven.backend.ledger.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.haven.backend.ledger.entity.LedgerEntries;
import com.haven.backend.ledger.entity.LedgerTypes;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 统计纯计算：总额、分类排行、按天补零与时区归属。
 */
class LedgerStatsCalculatorTest {

    private static final ZoneId ZONE = ZoneOffset.UTC;
    private final LedgerStatsCalculator calculator = new LedgerStatsCalculator();

    @Test
    @DisplayName("总额、笔数与收支分开统计")
    void totalsAreSplitByDirection() {
        List<LedgerEntries> entries = List.of(
                entry(LedgerTypes.EXPENSE, "餐饮", 1200, "2026-01-02T01:00:00Z"),
                entry(LedgerTypes.EXPENSE, "购物", 3000, "2026-01-02T02:00:00Z"),
                entry(LedgerTypes.INCOME, "工资", 800000, "2026-01-03T01:00:00Z"));

        LedgerStatsCalculator.WindowStats stats = calculator.summarize(entries, dates(1, 3), ZONE);

        assertEquals(4200L, stats.totalExpenseCents());
        assertEquals(800000L, stats.totalIncomeCents());
        assertEquals(3, stats.totalCount());
    }

    @Test
    @DisplayName("按天走势补零，且金额归入正确日期")
    void dailySeriesIsFilled() {
        List<LedgerEntries> entries = List.of(
                entry(LedgerTypes.EXPENSE, "餐饮", 1200, "2026-01-02T01:00:00Z"),
                entry(LedgerTypes.INCOME, "工资", 800000, "2026-01-02T02:00:00Z"));

        LedgerStatsCalculator.WindowStats stats = calculator.summarize(entries, dates(1, 4), ZONE);

        assertEquals(4, stats.daily().size());
        assertEquals("2026-01-01", stats.daily().get(0).date());
        assertEquals(0L, stats.daily().get(0).count());
        // 条目发生在 1 月 2 日，对应索引 1
        assertEquals("2026-01-02", stats.daily().get(1).date());
        assertEquals(2L, stats.daily().get(1).count());
        assertEquals(1200L, stats.daily().get(1).expenseCents());
        assertEquals(800000L, stats.daily().get(1).incomeCents());
    }

    @Test
    @DisplayName("分类排行按金额降序，金额相同按分类名升序")
    void rankingIsSortedStable() {
        List<LedgerEntries> entries = List.of(
                entry(LedgerTypes.EXPENSE, "餐饮", 1200, "2026-01-02T01:00:00Z"),
                entry(LedgerTypes.EXPENSE, "购物", 1200, "2026-01-02T01:00:00Z"),
                entry(LedgerTypes.EXPENSE, "交通", 5000, "2026-01-02T01:00:00Z"));

        var ranking = calculator.summarize(entries, dates(2, 2), ZONE).categoryRanking();

        assertEquals("交通", ranking.get(0).category());
        assertEquals(5000L, ranking.get(0).amountCents());
        assertEquals(1L, ranking.get(0).count());
        assertEquals(3, ranking.size());
        // 金额相同的两项按分类名升序
        assertEquals("购物", ranking.get(1).category());
        assertEquals("餐饮", ranking.get(2).category());
    }

    @Test
    @DisplayName("发生在窗口外的条目不进按天走势，但计入总额")
    void outOfWindowEntriesOnlyCountInTotals() {
        List<LedgerEntries> entries = List.of(entry(LedgerTypes.EXPENSE, "餐饮", 1200, "2026-02-01T01:00:00Z"));

        LedgerStatsCalculator.WindowStats stats = calculator.summarize(entries, dates(1, 2), ZONE);

        assertEquals(1200L, stats.totalExpenseCents());
        assertEquals(0L, stats.daily().get(0).count());
        assertTrue(stats.daily().stream().allMatch(d -> d.count() == 0));
    }

    @Test
    @DisplayName("没有发生时间（null）的条目只计入总额")
    void nullOccurredAtSkipsDaily() {
        LedgerEntries e = entry(LedgerTypes.EXPENSE, "餐饮", 1200, "2026-01-02T01:00:00Z");
        e.setOccurredAt(null);

        LedgerStatsCalculator.WindowStats stats = calculator.summarize(List.of(e), dates(1, 2), ZONE);

        assertEquals(1200L, stats.totalExpenseCents());
        assertEquals(0L, stats.daily().get(0).count());
    }

    @Test
    @DisplayName("金额为 null 时按 0 处理，不抛 NPE")
    void nullAmountTreatedAsZero() {
        LedgerEntries e = entry(LedgerTypes.EXPENSE, "餐饮", 0L, "2026-01-02T01:00:00Z");
        e.setAmountCents(null);

        LedgerStatsCalculator.WindowStats stats = calculator.summarize(List.of(e), dates(1, 2), ZONE);

        assertEquals(0L, stats.totalExpenseCents());
        assertEquals(1, stats.totalCount());
    }

    private static List<LocalDate> dates(int fromDay, int toDay) {
        return LocalDate.of(2026, 1, fromDay)
                .datesUntil(LocalDate.of(2026, 1, toDay).plusDays(1))
                .toList();
    }

    private static LedgerEntries entry(String type, String category, long cents, String occurredAt) {
        return new LedgerEntries()
                .setId(java.util.UUID.randomUUID())
                .setType(type)
                .setCategory(category)
                .setAmountCents(cents)
                .setOccurredAt(OffsetDateTime.parse(occurredAt));
    }
}
