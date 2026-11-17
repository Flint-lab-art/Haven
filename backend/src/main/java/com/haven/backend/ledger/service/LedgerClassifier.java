package com.haven.backend.ledger.service;

import com.haven.backend.ledger.dto.ParsedLedgerItem;
import com.haven.backend.ledger.entity.LedgerCategories;
import com.haven.backend.ledger.entity.LedgerTypes;
import java.util.Map;
import org.springframework.stereotype.Component;

/**
 * 把「日期/金额解析后的剩余文本」判定为分类、方向与备注。
 * <p>
 * 从解析器里独立出来，是因为这段规则与金额、日期的语法解析无关：
 * 只要给出「分类词 + 备注 + 别名表」，就能单独测试命中 / 未命中 / 别名翻译三条分支。
 */
@Component
public class LedgerClassifier {

    /** 结果：分类（可能是别名翻译后的值）、备注、方向。 */
    public record Classification(String category, String note, String type) {}

    /**
     * 判定单条记录的分类、备注与方向。
     *
     * @param remaining 已剥掉日期与金额的文本，形如「午饭 食堂」或「午饭」
     * @param aliases 别名表；命中时用别名值作为分类
     */
    public Classification classify(String remaining, Map<String, String> aliases) {
        int split = firstWhitespace(remaining);
        String categoryToken;
        String rest;
        if (split >= 0) {
            categoryToken = remaining.substring(0, split).trim();
            rest = remaining.substring(split + 1).trim();
        } else {
            categoryToken = remaining.trim();
            rest = "";
        }

        String aliasCategory = aliases.get(categoryToken);
        String category;
        String note;
        if (aliasCategory != null) {
            // 别名命中：原词并入备注，category 使用翻译后的大类。
            category = aliasCategory;
            note = join(categoryToken, rest);
        } else if (LedgerCategories.ALL_SET.contains(categoryToken)) {
            category = categoryToken;
            note = rest;
        } else {
            // 未知词：落入未分类，原词保留在备注中，方便之后人工归类。
            category = LedgerTextParser.UNCATEGORIZED;
            note = join(categoryToken, rest);
        }

        String type = LedgerCategories.INCOME_SET.contains(category) || containsIncomeKeyword(remaining)
                ? LedgerTypes.INCOME
                : LedgerTypes.EXPENSE;
        return new Classification(category, note, type);
    }

    /** 把分类与备注组装成最终条目。 */
    public ParsedLedgerItem toItem(
            int line, String raw, long amountCents, Classification c, java.time.OffsetDateTime occurredAt) {
        return new ParsedLedgerItem(line, raw, c.type(), amountCents, c.category(), c.note(), occurredAt);
    }

    /** 提取备注的首个词，用于「人工归类后学习别名」。 */
    public String firstTokenOf(String note) {
        if (note == null || note.isBlank()) {
            return "";
        }
        int split = firstWhitespace(note);
        return split >= 0 ? note.substring(0, split) : note;
    }

    private boolean containsIncomeKeyword(String text) {
        return LedgerTextParser.INCOME_KEYWORDS.stream().anyMatch(text::contains);
    }

    private int firstWhitespace(String value) {
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            if (Character.isWhitespace(c) || c == '\u3000') {
                return i;
            }
        }
        return -1;
    }

    private String join(String first, String second) {
        if (second == null || second.isBlank()) {
            return first;
        }
        return first + " " + second;
    }
}
