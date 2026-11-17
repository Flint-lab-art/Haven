package com.haven.backend.ledger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerAliasPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerBatchDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerDailyPoint;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerQuickCommitDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerSummaryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerTrendDto;
import com.haven.backend.ledger.dto.ParsedLedgerItem;
import com.haven.backend.ledger.dto.QuickCommitRequest;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import com.haven.backend.ledger.service.LedgerService;
import java.time.Clock;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@org.springframework.test.context.ActiveProfiles("test")
@Transactional
class LedgerSmokeTest {

    @Autowired
    private LedgerService ledgerService;

    @Autowired
    private Clock clock;

    @Test
    void quickParseHandlesCategoriesAmountsAndIncome() {
        String userId = UUID.randomUUID().toString();
        seedAliases(userId);

        QuickParseResult result = ledgerService.quickParse(userId, """
                                午饭12
                                晚饭 20
                                网购 零食 100
                                房租 水电 2200
                                工资 10000
                                午饭0
                                没有金额
                                """);

        assertEquals(5, result.items().size());
        assertEquals(2, result.errors().size());

        List<ParsedLedgerItem> items = result.items();
        assertEquals(1200L, items.get(0).amountCents());
        assertEquals("餐饮", items.get(0).category());
        assertEquals("expense", items.get(0).type());
        assertEquals("午饭", items.get(0).note());

        assertEquals("餐饮", items.get(1).category());
        assertEquals(2000L, items.get(1).amountCents());

        assertEquals("购物", items.get(2).category());
        assertEquals(10000L, items.get(2).amountCents());
        assertEquals("网购 零食", items.get(2).note());

        assertEquals("居家", items.get(3).category());
        assertEquals(220000L, items.get(3).amountCents());

        assertEquals("工资", items.get(4).category());
        assertEquals("income", items.get(4).type());
        assertEquals(1000000L, items.get(4).amountCents());
    }

    @Test
    void incomeAliasesResolveToIncomeCategories() {
        String userId = UUID.randomUUID().toString();
        ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("薪水", "工资"));

        QuickParseResult result = ledgerService.quickParse(userId, """
                                薪水 12000
                                报销 320
                                退款 99
                                红包 200
                                """);

        assertEquals(4, result.items().size());
        assertEquals(0, result.errors().size());

        List<ParsedLedgerItem> items = result.items();
        assertEquals(
                List.of("工资", "报销", "退款", "红包"),
                items.stream().map(ParsedLedgerItem::category).toList());
        assertTrue(items.stream().allMatch(item -> "income".equals(item.type())));
        assertEquals("薪水", items.getFirst().note());
        assertEquals(1200000L, items.getFirst().amountCents());
    }

    @Test
    void quickParseSupportsLeadingDates() {
        String userId = UUID.randomUUID().toString();
        seedAliases(userId);

        LocalDate today = LocalDate.now(clock);
        YearMonth thisMonth = YearMonth.from(today);

        QuickParseResult result = ledgerService.quickParse(userId, """
                                11月16 午饭 16
                                2026-01-02 午饭 20
                                昨天 晚饭 30
                                16号 午饭 12
                                """);

        assertEquals(4, result.items().size());
        assertEquals(0, result.errors().size());

        List<ParsedLedgerItem> items = result.items();
        assertEquals(
                LocalDate.of(today.getYear(), 11, 16), items.get(0).occurredAt().toLocalDate());
        assertEquals(LocalDate.of(2026, 1, 2), items.get(1).occurredAt().toLocalDate());
        assertEquals(today.minusDays(1), items.get(2).occurredAt().toLocalDate());
        assertEquals(thisMonth.atDay(16), items.get(3).occurredAt().toLocalDate());

        // 不写日期时沿用当前时间
        QuickParseResult plain = ledgerService.quickParse(userId, "午饭 12");
        assertEquals(today, plain.items().getFirst().occurredAt().toLocalDate());
    }

    @Test
    void quickParseSupportsAmountFormats() {
        String userId = UUID.randomUUID().toString();
        seedAliases(userId);

        QuickParseResult result = ledgerService.quickParse(userId, """
                                午饭 12.5
                                午饭 32元
                                午饭 ¥32
                                午饭 二十五块
                                """);

        assertEquals(4, result.items().size());
        assertEquals(0, result.errors().size());
        assertEquals(
                List.of(1250L, 3200L, 3200L, 2500L),
                result.items().stream().map(ParsedLedgerItem::amountCents).toList());
    }

    @Test
    void batchIsIdempotentSummaryAndPatchWork() {
        String userId = UUID.randomUUID().toString();
        seedAliases(userId);

        QuickParseResult parsed = ledgerService.quickParse(userId, """
                                午饭12
                                晚饭 20
                                网购 零食 100
                                张三 30
                                工资 8000
                                """);
        List<CreateLedgerEntryRequest> items = parsed.items().stream()
                .map(p ->
                        new CreateLedgerEntryRequest(p.type(), p.amountCents(), p.category(), p.note(), p.occurredAt()))
                .toList();

        CreateLedgerBatchRequest batch = new CreateLedgerBatchRequest("batch-1", "raw text", items);

        LedgerBatchDto first = ledgerService.createBatch(userId, batch);
        assertTrue(first.created());
        assertEquals(5, first.total());

        LedgerBatchDto second = ledgerService.createBatch(userId, batch);
        assertFalse(second.created());
        assertEquals(5, second.total());

        LedgerSummaryDto summary =
                ledgerService.summary(userId, YearMonth.now(clock).toString());
        assertEquals(1200L + 2000L + 10000L + 3000L, summary.totalExpenseCents());
        assertEquals(800000L, summary.totalIncomeCents());
        assertEquals(5, summary.totalCount());
        assertEquals(3, summary.recent().size());

        assertTrue(summary.categoryRanking().stream().anyMatch(i -> "餐饮".equals(i.category())));
        assertTrue(summary.incomeCategoryRanking().stream()
                .anyMatch(i -> "工资".equals(i.category()) && i.amountCents() == 800000L));

        // 月度走势：按天补零到整月
        assertEquals(YearMonth.now(clock).lengthOfMonth(), summary.daily().size());

        // 最近 7 天：总览与按天走势
        LedgerTrendDto trend = ledgerService.trend(userId, 7);
        assertEquals(7, trend.days());
        assertEquals(16200L, trend.totalExpenseCents());
        assertEquals(800000L, trend.totalIncomeCents());
        assertEquals(5, trend.totalCount());

        List<LedgerDailyPoint> trendDaily = trend.daily();
        assertEquals(7, trendDaily.size());
        LedgerDailyPoint today = trendDaily.getLast();
        assertEquals(LocalDate.now(clock).toString(), today.date());
        assertEquals(16200L, today.expenseCents());
        assertEquals(800000L, today.incomeCents());
        assertEquals(5L, today.count());
        assertEquals(0L, trendDaily.getFirst().expenseCents());

        LedgerEntryDto uncategorized = first.items().stream()
                .filter(i -> "未分类".equals(i.category()))
                .findFirst()
                .orElseThrow();

        ledgerService.updateEntry(userId, uncategorized.id(), new UpdateLedgerEntryRequest("餐饮", null, null));

        LedgerAliasPage aliases = ledgerService.listAliases(userId);
        assertTrue(aliases.items().stream().anyMatch(i -> "张三".equals(i.alias()) && "餐饮".equals(i.category())));

        ledgerService.deleteEntry(userId, uncategorized.id());
        assertEquals(
                4L,
                ledgerService.listEntries(userId, null, null, null, null, 20, 0).total());
    }

    @Test
    void quickCommitParsesAndWritesInOneCall() {
        String userId = UUID.randomUUID().toString();
        seedAliases(userId);

        LedgerQuickCommitDto result = ledgerService.quickCommit(userId, new QuickCommitRequest("""
                                                午饭12
                                                工资 8000
                                                没有金额
                                                """, null));

        assertTrue(result.batch().created());
        assertEquals(2, result.batch().total());
        assertEquals(2, result.batch().items().size());
        assertEquals(1, result.errors().size());

        // 同一个 batch_id 重试不会重复写入
        String batchId = result.batch().batchId();
        LedgerQuickCommitDto replay = ledgerService.quickCommit(userId, new QuickCommitRequest("""
                                                午饭12
                                                工资 8000
                                                没有金额
                                                """, batchId));
        assertFalse(replay.batch().created());
        assertEquals(2, replay.batch().total());

        // 全部解析失败时不写空批次
        LedgerQuickCommitDto empty = ledgerService.quickCommit(userId, new QuickCommitRequest("随便写点", null));
        assertFalse(empty.batch().created());
        assertEquals(0, empty.batch().total());
        assertEquals(
                2L,
                ledgerService.listEntries(userId, null, null, null, null, 20, 0).total());
    }

    private void seedAliases(String userId) {
        ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("午饭", "餐饮"));
        ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("晚饭", "餐饮"));
        ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("网购", "购物"));
        ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("房租", "居家"));
    }
}
