package com.haven.backend.ledger.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.haven.backend.ledger.entity.LedgerTypes;
import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 「还款」分类：属于支出，且能通过快捷输入直接识别。
 */
class LedgerRepaymentCategoryTest {

    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-01-02T08:00:00Z"), ZoneOffset.UTC);
    private static final OffsetDateTime NOW = OffsetDateTime.now(CLOCK);

    private final LedgerClassifier classifier = new LedgerClassifier();
    private final LedgerTextParser parser = new LedgerTextParser(CLOCK, classifier);

    @Test
    @DisplayName("还款是支出分类，不是收入")
    void repaymentIsExpense() {
        LedgerClassifier.Classification c = classifier.classify("还款 2000", Map.of());

        assertEquals("还款", c.category());
        assertEquals(LedgerTypes.EXPENSE, c.type());
    }

    @Test
    @DisplayName("直接写还款能被识别")
    void parsesRepaymentDirectly() {
        ParsedLine line = parse("还款 2000");

        assertEquals("还款", line.category());
        assertEquals(LedgerTypes.EXPENSE, line.type());
        assertEquals(200000L, line.amountCents());
    }

    @Test
    @DisplayName("别名「还花呗」翻译成还款")
    void aliasMapsToRepayment() {
        ParsedLine line = parse("还花呗 1500", Map.of("还花呗", "还款"));

        assertEquals("还款", line.category());
        assertEquals("还花呗", line.note());
    }

    @Test
    @DisplayName("带日期的还款记录：日期被剥离，金额按分存储")
    void repaymentWithDate() {
        ParsedLine line = parse("11月16 还款 2000");

        assertEquals(200000L, line.amountCents());
        assertEquals(11, line.occurredAt().getMonthValue());
        assertEquals(16, line.occurredAt().getDayOfMonth());
        assertEquals("还款", line.category());
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
