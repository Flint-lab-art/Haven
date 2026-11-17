package com.haven.backend.ledger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.haven.backend.exception.BizException;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerQuickCommitDto;
import com.haven.backend.ledger.dto.QuickCommitRequest;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.service.LedgerService;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

/**
 * 修改记账条目的收支方向与分类。
 *
 * <p>界面上「先选收支、再选分类」是两级控件，两者必须一起改对：
 * 后端要求分类与方向一致，否则支出会被算进收入排行。
 */
@SpringBootTest
@org.springframework.test.context.ActiveProfiles("test")
@Transactional
class LedgerEntryTypeChangeTest {

    @Autowired
    private LedgerService ledgerService;

    @Autowired
    private JdbcTemplate jdbc;

    private String userId;

    @BeforeEach
    void setUp() {
        // V11 起 ledger_* 有指向 users 的外键，必须先建用户
        userId = UUID.randomUUID().toString();
        jdbc.update(
                "INSERT INTO users (id, username, password_hash) VALUES (?::uuid, ?, ?)",
                userId,
                "typechange-" + userId,
                "x");
    }

    @Test
    @DisplayName("支出改成收入：方向与分类一起更新")
    void switchExpenseToIncome() {
        LedgerEntryDto entry = first(ledgerService.quickCommit(userId, new QuickCommitRequest("午饭 20", null)));
        assertEquals("expense", entry.type());

        LedgerEntryDto updated =
                ledgerService.updateEntry(userId, entry.id(), new UpdateLedgerEntryRequest("工资", "income", null, null));

        assertEquals("income", updated.type());
        assertEquals("工资", updated.category());
    }

    @Test
    @DisplayName("收入改回支出")
    void switchIncomeToExpense() {
        LedgerEntryDto entry = first(ledgerService.quickCommit(userId, new QuickCommitRequest("工资 8000", null)));
        assertEquals("income", entry.type());

        LedgerEntryDto updated = ledgerService.updateEntry(
                userId, entry.id(), new UpdateLedgerEntryRequest("餐饮", "expense", null, null));

        assertEquals("expense", updated.type());
        assertEquals("餐饮", updated.category());
    }

    @Test
    @DisplayName("方向与分类不一致时被拒绝，且不落库")
    void mismatchedTypeAndCategoryIsRejected() {
        LedgerEntryDto entry = first(ledgerService.quickCommit(userId, new QuickCommitRequest("午饭 20", null)));

        // 「工资」是收入分类，却标成支出 → 会让支出排行把工资算进去
        BizException ex = assertThrows(
                BizException.class,
                () -> ledgerService.updateEntry(
                        userId, entry.id(), new UpdateLedgerEntryRequest("工资", "expense", null, null)));
        assertEquals(422, ex.getCode());

        // 数据没被改动
        LedgerEntryDto reloaded = ledgerService
                .listEntries(userId, null, null, null, null, 20, 0)
                .items()
                .getFirst();
        assertEquals("expense", reloaded.type());
        assertEquals("未分类", reloaded.category());
    }

    @Test
    @DisplayName("只改分类为另一方向时也被拒绝")
    void categoryAloneMustMatchExistingType() {
        LedgerEntryDto entry = first(ledgerService.quickCommit(userId, new QuickCommitRequest("午饭 20", null)));

        // 只传 category，方向仍是 expense → 收入分类冲突
        BizException ex = assertThrows(
                BizException.class,
                () -> ledgerService.updateEntry(
                        userId, entry.id(), new UpdateLedgerEntryRequest("工资", null, null, null)));
        assertEquals(422, ex.getCode());
    }

    @Test
    @DisplayName("只改金额不影响方向")
    void amountOnlyKeepsType() {
        LedgerEntryDto entry = first(ledgerService.quickCommit(userId, new QuickCommitRequest("午饭 20", null)));

        LedgerEntryDto updated =
                ledgerService.updateEntry(userId, entry.id(), new UpdateLedgerEntryRequest(null, null, 3500L, null));

        assertEquals(3500L, updated.amountCents());
        assertEquals("expense", updated.type());
    }

    private static LedgerEntryDto first(LedgerQuickCommitDto result) {
        assertEquals(1, result.errors().size() + result.batch().items().size());
        return result.batch().items().getFirst();
    }
}
