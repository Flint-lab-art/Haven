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
 * 「订阅」分类：自动续费的固定支出（iCloud、Apple Music、视频音乐会员）。
 *
 * <p>与「Token」的分工：Token 是按用量计费的 AI 账单，订阅是按周期续费的服务。
 * 两者都是支出，但分开统计才能看清「每月固定花掉多少」。
 */
class LedgerSubscriptionCategoryTest {

    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-01-02T08:00:00Z"), ZoneOffset.UTC);
    private static final OffsetDateTime NOW = OffsetDateTime.now(CLOCK);

    private final LedgerClassifier classifier = new LedgerClassifier();
    private final LedgerTextParser parser = new LedgerTextParser(CLOCK, classifier);

    @Test
    @DisplayName("订阅在支出白名单里，是独立于 Token 的分类")
    void subscriptionIsExpenseCategory() {
        assertTrue(LedgerCategories.EXPENSE.contains("订阅"));
        assertTrue(LedgerCategories.ALL_SET.contains("订阅"));
        assertTrue(!LedgerCategories.INCOME_SET.contains("订阅"), "订阅不应被当成收入");
        // 与 Token 是并列关系，不是替代
        assertTrue(LedgerCategories.EXPENSE.contains("Token"));
    }

    @Test
    @DisplayName("直接写「订阅」能被识别为支出")
    void parsesSubscriptionDirectly() {
        ParsedLine line = parse("订阅 25");

        assertEquals("订阅", line.category());
        assertEquals(LedgerTypes.EXPENSE, line.type());
        assertEquals(2500L, line.amountCents());
    }

    @Test
    @DisplayName("iCloud、Apple Music、视频会员等别名都落到订阅")
    void aliasesMapToSubscription() {
        // 别名只匹配第一个空格前的词，所以这里都用单词别名
        String[][] cases = {
            {"icloud 25", "icloud"},
            {"applemusic 11", "applemusic"},
            {"netflix 60", "netflix"},
            {"爱奇艺 25", "爱奇艺"},
            {"网易云 15", "网易云"},
        };

        for (String[] c : cases) {
            String text = c[0];
            String alias = c[1];
            ParsedLine line = parse(text, Map.of(alias, "订阅"));
            assertEquals("订阅", line.category(), "别名 " + alias + " 应翻译成订阅");
        }
    }

    @Test
    @DisplayName("别名不匹配带空格的短语（分词只取第一个词）")
    void aliasDoesNotMatchMultiWord() {
        // 这解释了为什么默认别名里不能写 'apple music'
        ParsedLine line = parse("apple inc 11", Map.of("apple music", "订阅"));
        assertEquals("未分类", line.category());
    }

    @Test
    @DisplayName("带日期的订阅记录")
    void subscriptionWithDate() {
        ParsedLine line = parse("11月16 icloud 25", Map.of("icloud", "订阅"));

        assertEquals(2500L, line.amountCents());
        assertEquals(11, line.occurredAt().getMonthValue());
        assertEquals(16, line.occurredAt().getDayOfMonth());
        assertEquals("订阅", line.category());
    }

    @Test
    @DisplayName("Token 与订阅互不影响")
    void tokenAndSubscriptionCoexist() {
        assertEquals("Token", parse("claude 20", Map.of("claude", "Token")).category());
        assertEquals("订阅", parse("claude 20", Map.of("claude", "订阅")).category());
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
