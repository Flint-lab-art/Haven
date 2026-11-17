package com.haven.backend.ledger.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.haven.backend.ledger.entity.LedgerCategories;
import com.haven.backend.ledger.entity.LedgerTypes;
import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 「Token」分类：属于支出，用于 AI 服务按用量计费的订阅。
 *
 * <p>加分类要同时改白名单、前端选项和数据库 CHECK 约束，漏任何一处都会
 * 表现为「解析没问题，但写入被数据库拒绝」。这里把白名单与解析两段都钉住。
 */
class LedgerTokenCategoryTest {

    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-01-02T08:00:00Z"), ZoneOffset.UTC);
    private static final OffsetDateTime NOW = OffsetDateTime.now(CLOCK);

    private final LedgerClassifier classifier = new LedgerClassifier();
    private final LedgerTextParser parser = new LedgerTextParser(CLOCK, classifier);

    @Test
    @DisplayName("Token 在支出白名单里，不在收入白名单里")
    void tokenIsExpenseCategory() {
        assertTrue(LedgerCategories.EXPENSE.contains("Token"));
        assertTrue(LedgerCategories.ALL_SET.contains("Token"));
        assertTrue(!LedgerCategories.INCOME_SET.contains("Token"), "Token 不应被当成收入");
    }

    @Test
    @DisplayName("直接写 Token 能被识别为支出")
    void parsesTokenDirectly() {
        ParsedLine line = parse("Token 20");

        assertEquals("Token", line.category());
        assertEquals(LedgerTypes.EXPENSE, line.type());
        assertEquals(2000L, line.amountCents());
    }

    @Test
    @DisplayName("别名「openai」翻译成 Token 分类")
    void aliasMapsToToken() {
        ParsedLine line = parse("openai 20", Map.of("openai", "Token"));

        assertEquals("Token", line.category());
        assertEquals(LedgerTypes.EXPENSE, line.type());
        assertEquals("openai", line.note());
        assertEquals(2000L, line.amountCents());
    }

    @Test
    @DisplayName("带日期与备注的 Token 记录")
    void tokenWithDateAndNote() {
        ParsedLine line = parse("11月16 claude 订阅 150", Map.of("claude", "Token"));

        assertEquals(15000L, line.amountCents());
        assertEquals(11, line.occurredAt().getMonthValue());
        assertEquals(16, line.occurredAt().getDayOfMonth());
        assertEquals("Token", line.category());
    }

    private ParsedLine parse(String text) {
        return parse(text, Map.of());
    }

    private ParsedLine parse(String text, Map<String, String> aliases) {
        LedgerTextParser.Result result = parser.parse(text, aliases, NOW);
        assertEquals(1, result.items().size(), "应解析出 1 条: " + result.errors());
        var item = result.items().getFirst();
        return new ParsedLine(item.type(), item.category(), item.note(), item.amountCents(), item.occurredAt());
    }

    private record ParsedLine(String type, String category, String note, long amountCents, OffsetDateTime occurredAt) {}
}
