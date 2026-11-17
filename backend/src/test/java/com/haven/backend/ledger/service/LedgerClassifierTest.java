package com.haven.backend.ledger.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.haven.backend.ledger.entity.LedgerTypes;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 分类判定规则：命中别名 / 命中内置分类 / 未命中归入未分类，以及收入方向判定。
 */
class LedgerClassifierTest {

    private final LedgerClassifier classifier = new LedgerClassifier();

    @Test
    @DisplayName("命中内置分类时直接使用，备注原样保留")
    void builtInCategoryWins() {
        LedgerClassifier.Classification c = classifier.classify("餐饮 食堂", Map.of());

        assertEquals("餐饮", c.category());
        assertEquals("食堂", c.note());
        assertEquals(LedgerTypes.EXPENSE, c.type());
    }

    @Test
    @DisplayName("命中别名时用别名值作为分类，原词并入备注")
    void aliasTranslatesCategory() {
        LedgerClassifier.Classification c = classifier.classify("午饭 食堂", Map.of("午饭", "餐饮"));

        assertEquals("餐饮", c.category());
        assertEquals("午饭 食堂", c.note());
    }

    @Test
    @DisplayName("未知词归入未分类，原词保留在备注")
    void unknownTokensAreUncategorized() {
        LedgerClassifier.Classification c = classifier.classify("张三 借钱", Map.of());

        assertEquals(LedgerTextParser.UNCATEGORIZED, c.category());
        assertEquals("张三 借钱", c.note());
    }

    @Test
    @DisplayName("收入分类判定为 income")
    void incomeCategoriesAreIncome() {
        assertEquals(LedgerTypes.INCOME, classifier.classify("工资", Map.of()).type());
        assertEquals(LedgerTypes.INCOME, classifier.classify("报销 打车", Map.of()).type());
    }

    @Test
    @DisplayName("备注里出现收入关键词也判为收入")
    void incomeKeywordsInNoteCount() {
        LedgerClassifier.Classification c = classifier.classify("张三 退款", Map.of());

        assertEquals(LedgerTextParser.UNCATEGORIZED, c.category());
        assertEquals(LedgerTypes.INCOME, c.type());
    }

    @Test
    @DisplayName("首个词提取用于学习别名")
    void firstTokenOfNote() {
        assertEquals("张三", classifier.firstTokenOf("张三 借钱"));
        assertEquals("张三", classifier.firstTokenOf("张三"));
        assertEquals("", classifier.firstTokenOf("   "));
    }

    @Test
    @DisplayName("全角空格也能作为分隔符")
    void fullWidthSpaceIsSeparator() {
        LedgerClassifier.Classification c = classifier.classify("餐饮\u3000食堂", Map.of());

        assertEquals("餐饮", c.category());
        assertEquals("食堂", c.note());
    }
}
