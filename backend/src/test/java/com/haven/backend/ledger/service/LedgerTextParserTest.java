package com.haven.backend.ledger.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 快捷输入解析器：纯语法解析，不连数据库。
 * <p>
 * 覆盖金额（阿拉伯 / 中文 / 带单位）、日期（完整 / 月日 / 单日 / 相对）与非法输入。
 */
class LedgerTextParserTest {

    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-01-02T08:00:00Z"), ZoneOffset.UTC);
    private static final OffsetDateTime NOW = OffsetDateTime.now(CLOCK);
    private static final Map<String, String> NO_ALIASES = Map.of();

    private LedgerTextParser parser;

    @BeforeEach
    void setUp() {
        parser = new LedgerTextParser(CLOCK, new LedgerClassifier());
    }

    @Test
    @DisplayName("阿拉伯数字与小数金额")
    void parsesArabicAmounts() {
        assertEquals(1200L, amount("午饭12"));
        assertEquals(1250L, amount("午饭 12.5"));
        assertEquals(3200L, amount("午饭 32元"));
        assertEquals(3200L, amount("午饭 ¥32"));
    }

    @Test
    @DisplayName("中文数字金额")
    void parsesChineseAmounts() {
        assertEquals(2500L, amount("午饭 二十五块"));
        assertEquals(1250L, amount("午饭 十二点五元"));
        assertEquals(1000000L, amount("工资 一万"));
    }

    @Test
    @DisplayName("超过两位小数不会被识别为金额（正则限定 1-2 位）")
    void tooManyDecimalsIsNotAnAmount() {
        // 12.345 不匹配金额规则，末尾的 345 也不是合法金额，因此整行没有金额
        assertNull(parser.extractAmount("午饭 12.345"));
    }

    @Test
    @DisplayName("没有金额时返回 null")
    void noAmountReturnsNull() {
        assertNull(parser.extractAmount("随便写点"));
    }

    @Test
    @DisplayName("行首完整日期被剥离")
    void extractsFullDate() {
        LedgerTextParser.DatePrefix dated = parser.extractDatePrefix("2026-03-04 午饭 12", NOW);

        assertEquals("午饭 12", dated.rest());
        assertEquals(2026, dated.occurredAt().getYear());
        assertEquals(3, dated.occurredAt().getMonthValue());
        assertEquals(4, dated.occurredAt().getDayOfMonth());
    }

    @Test
    @DisplayName("月日与单日按当前年 / 当前月补全")
    void extractsPartialDates() {
        LedgerTextParser.DatePrefix monthDay = parser.extractDatePrefix("11-16 午饭", NOW);
        assertEquals(2026, monthDay.occurredAt().getYear());
        assertEquals(11, monthDay.occurredAt().getMonthValue());

        LedgerTextParser.DatePrefix dayOnly = parser.extractDatePrefix("16号 午饭", NOW);
        assertEquals(1, dayOnly.occurredAt().getMonthValue());
        assertEquals(16, dayOnly.occurredAt().getDayOfMonth());
    }

    @Test
    @DisplayName("相对日期：昨天 / 前天")
    void extractsRelativeDates() {
        LedgerTextParser.DatePrefix yesterday = parser.extractDatePrefix("昨天 午饭", NOW);
        assertEquals(NOW.toLocalDate().minusDays(1), yesterday.occurredAt().toLocalDate());

        LedgerTextParser.DatePrefix beforeYesterday = parser.extractDatePrefix("前天 午饭", NOW);
        assertEquals(
                NOW.toLocalDate().minusDays(2), beforeYesterday.occurredAt().toLocalDate());
    }

    @Test
    @DisplayName("没有日期时沿用传入的时间基准")
    void defaultsToNow() {
        LedgerTextParser.DatePrefix dated = parser.extractDatePrefix("午饭 12", NOW);

        assertEquals(NOW, dated.occurredAt());
    }

    @Test
    @DisplayName("非法日期（2 月 30 日）不被当作日期")
    void invalidDateIsLeftInPlace() {
        LedgerTextParser.DatePrefix dated = parser.extractDatePrefix("2026-02-30 午饭", NOW);

        assertEquals("2026-02-30 午饭", dated.rest());
    }

    @Test
    @DisplayName("多行解析：空行跳过，错误逐行返回")
    void parsesMultipleLines() {
        LedgerTextParser.Result result = parser.parse("午饭 12\n\n没有金额\n工资 8000\n", NO_ALIASES, NOW);

        assertEquals(2, result.items().size());
        assertEquals(1, result.errors().size());
        assertEquals(3, result.errors().getFirst().line());
        assertEquals("未找到金额", result.errors().getFirst().message());
    }

    @Test
    @DisplayName("金额为 0 的行记为错误而不是条目")
    void zeroAmountIsError() {
        LedgerTextParser.Result result = parser.parse("午饭0", NO_ALIASES, NOW);

        assertEquals(0, result.items().size());
        assertEquals("金额必须大于 0", result.errors().getFirst().message());
    }

    private long amount(String line) {
        LedgerTextParser.AmountMatch match = parser.extractAmount(line);
        return match.amountCents();
    }
}
