package com.haven.backend.ledger;

import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.ParsedLedgerItem;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import com.haven.backend.ledger.service.LedgerService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@Transactional
class LedgerSmokeTest {

        @Autowired
        private LedgerService ledgerService;

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
                assertEquals(List.of("工资", "报销", "退款", "红包"),
                                items.stream().map(ParsedLedgerItem::category).toList());
                assertTrue(items.stream().allMatch(item -> "income".equals(item.type())));
                assertEquals("薪水", items.getFirst().note());
                assertEquals(1200000L, items.getFirst().amountCents());
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
                assertEquals(List.of(1250L, 3200L, 3200L, 2500L),
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
                                .map(p -> new CreateLedgerEntryRequest(
                                                p.type(), p.amountCents(), p.category(), p.note(), p.occurredAt()))
                                .toList();

                CreateLedgerBatchRequest batch = new CreateLedgerBatchRequest(
                                "batch-1", "raw text", items);

                Map<String, Object> first = ledgerService.createBatch(userId, batch);
                assertEquals(true, first.get("created"));
                assertEquals(5, first.get("total"));

                Map<String, Object> second = ledgerService.createBatch(userId, batch);
                assertEquals(false, second.get("created"));
                assertEquals(5, second.get("total"));

                Map<String, Object> summary = ledgerService.summary(userId, YearMonth.now().toString());
                assertEquals(1200L + 2000L + 10000L + 3000L, summary.get("total_expense_cents"));
                assertEquals(800000L, summary.get("total_income_cents"));
                assertEquals(5, summary.get("total_count"));
                assertEquals(3, ((List<?>) summary.get("recent")).size());

                @SuppressWarnings("unchecked")
                List<Map<String, Object>> summaryItems = (List<Map<String, Object>>) summary.get("category_ranking");
                assertTrue(summaryItems.stream().anyMatch(i -> "餐饮".equals(i.get("category"))));

                @SuppressWarnings("unchecked")
                List<Map<String, Object>> incomeItems = (List<Map<String, Object>>) summary.get("income_category_ranking");
                assertTrue(incomeItems.stream().anyMatch(i -> "工资".equals(i.get("category"))
                                && Long.valueOf(800000L).equals(i.get("amount_cents"))));

                // 月度走势：按天补零到整月
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> monthDaily = (List<Map<String, Object>>) summary.get("daily");
                assertEquals(YearMonth.now().lengthOfMonth(), monthDaily.size());

                // 最近 7 天：总览与按天走势
                Map<String, Object> trend = ledgerService.trend(userId, 7);
                assertEquals(7, trend.get("days"));
                assertEquals(16200L, trend.get("total_expense_cents"));
                assertEquals(800000L, trend.get("total_income_cents"));
                assertEquals(5, trend.get("total_count"));

                @SuppressWarnings("unchecked")
                List<Map<String, Object>> trendDaily = (List<Map<String, Object>>) trend.get("daily");
                assertEquals(7, trendDaily.size());
                Map<String, Object> today = trendDaily.getLast();
                assertEquals(LocalDate.now().toString(), today.get("date"));
                assertEquals(16200L, today.get("expense_cents"));
                assertEquals(800000L, today.get("income_cents"));
                assertEquals(5L, today.get("count"));
                assertEquals(0L, trendDaily.getFirst().get("expense_cents"));

                @SuppressWarnings("unchecked")
                List<Map<String, Object>> batchItems = (List<Map<String, Object>>) first.get("items");
                Map<String, Object> uncategorized = batchItems.stream()
                                .filter(i -> "未分类".equals(i.get("category")))
                                .findFirst()
                                .orElseThrow();

                ledgerService.updateEntry(userId, UUID.fromString((String) uncategorized.get("id")),
                                new UpdateLedgerEntryRequest("餐饮", null, null));

                Map<String, Object> aliases = ledgerService.listAliases(userId);
                assertTrue(((List<?>) aliases.get("items")).stream()
                                .anyMatch(i -> "张三".equals(((Map<?, ?>) i).get("alias"))
                                                && "餐饮".equals(((Map<?, ?>) i).get("category"))));

                ledgerService.deleteEntry(userId, UUID.fromString((String) uncategorized.get("id")));
                assertEquals(4L, ledgerService.listEntries(userId, null, null, null, null, 20, 0).get("total"));
        }

        private void seedAliases(String userId) {
                ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("午饭", "餐饮"));
                ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("晚饭", "餐饮"));
                ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("网购", "购物"));
                ledgerService.upsertAlias(userId, new UpsertLedgerAliasRequest("房租", "居家"));
        }
}
