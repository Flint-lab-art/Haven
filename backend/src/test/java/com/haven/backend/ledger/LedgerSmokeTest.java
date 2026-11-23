package com.haven.backend.ledger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.ledger.dto.AccountRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.LedgerDtos.AccountDto;
import com.haven.backend.ledger.dto.LedgerDtos.BudgetDto;
import com.haven.backend.ledger.dto.LedgerDtos.CategoryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerSummaryDto;
import com.haven.backend.ledger.dto.UpsertBudgetRequest;
import com.haven.backend.ledger.service.LedgerService;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

/**
 * 记账核心闭环：账户余额、转账不计收支、两级分类、月度预算。
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class LedgerSmokeTest {

    /** 餐饮（一级）。 */
    private static final short FOOD = 1;
    /** 餐饮 · 午餐（二级）。 */
    private static final short LUNCH = 102;
    /** 收入（一级）。 */
    private static final short INCOME_ROOT = 8;
    /** 收入 · 工资（二级）。 */
    private static final short SALARY = 801;
    /** 其他（一级）。 */
    private static final short OTHER = 7;

    @Autowired
    private LedgerService ledgerService;

    @Autowired
    private UsersMapper usersMapper;

    private String userId;
    private UUID bank;
    private UUID wallet;

    @BeforeEach
    void setUp() {
        Users user = new Users();
        user.setId(UUID.randomUUID());
        user.setUsername("ledger-" + UUID.randomUUID().toString().substring(0, 8));
        user.setPasswordHash("x");
        user.setTotpEnabled(false);
        user.setCreatedAt(OffsetDateTime.now());
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.insert(user);
        userId = user.getId().toString();

        bank = createAccount("工资卡", "bank", 100_000L);
        wallet = createAccount("微信", "ewallet", 0L);
    }

    private UUID createAccount(String name, String type, long initial) {
        return ledgerService
                .createAccount(userId, new AccountRequest(name, null, type, initial, null, null, null))
                .id();
    }

    @Test
    @DisplayName("分类树：7 个一级支出 + 1 个一级收入，二级挂在父下")
    void categoryTreeIsTwoLevel() {
        List<CategoryDto> roots = ledgerService.categoryTree();

        long expenseRoots =
                roots.stream().filter(r -> "expense".equals(r.kind())).count();
        long incomeRoots = roots.stream().filter(r -> "income".equals(r.kind())).count();
        assertEquals(7, expenseRoots, "一级支出应是 7 个");
        assertEquals(1, incomeRoots, "一级收入应是 1 个");

        CategoryDto food =
                roots.stream().filter(r -> r.id() == FOOD).findFirst().orElseThrow();
        assertEquals("餐饮", food.name());
        assertTrue(food.children().size() >= 5, "餐饮下应有 5 个以上二级分类");
        assertTrue(food.children().stream().anyMatch(c -> "午餐".equals(c.name())));
    }

    @Test
    @DisplayName("支出让账户余额减少，二级分类正确回填一级名")
    void expenseReducesBalance() {
        LedgerEntryDto entry = ledgerService.createEntry(
                userId, new CreateLedgerEntryRequest("expense", 2_500L, LUNCH, bank, null, "午饭", null));

        assertEquals("午餐", entry.categoryName());
        assertEquals("餐饮", entry.rootCategoryName());
        assertEquals("工资卡", entry.accountName());

        assertEquals(97_500L, balanceOf(bank));
    }

    @Test
    @DisplayName("收入让账户余额增加")
    void incomeIncreasesBalance() {
        ledgerService.createEntry(
                userId, new CreateLedgerEntryRequest("income", 800_000L, SALARY, bank, null, "工资", null));
        assertEquals(900_000L, balanceOf(bank));
    }

    @Test
    @DisplayName("转账：两个账户一减一增，且不计入收支统计")
    void transferMovesMoneyWithoutTouchingStats() {
        // 工资卡 → 微信 1000
        LedgerEntryDto transfer = ledgerService.createEntry(
                userId, new CreateLedgerEntryRequest("transfer", 100_000L, null, bank, wallet, "转到微信", null));

        assertEquals("transfer", transfer.type());
        assertNull(transfer.categoryId());
        assertNull(transfer.categoryName());
        assertEquals(0L, balanceOf(bank), "转出账户应清零");
        assertEquals(100_000L, balanceOf(wallet), "转入账户应全额到账");

        LedgerSummaryDto summary = ledgerService.summary(userId, null);
        assertEquals(0L, summary.totalExpenseCents(), "转账不能计入支出");
        assertEquals(0L, summary.totalIncomeCents(), "转账不能计入收入");
        assertEquals(0L, summary.totalCount(), "转账不计入统计笔数");
        assertEquals(1L, summary.transferCount(), "但转账笔数要单独给出");
    }

    @Test
    @DisplayName("转账两侧账户不能相同")
    void transferRequiresDistinctAccounts() {
        BizException ex = assertThrows(
                BizException.class,
                () -> ledgerService.createEntry(
                        userId, new CreateLedgerEntryRequest("transfer", 100L, null, bank, bank, null, null)));
        assertEquals(422, ex.getCode());
    }

    @Test
    @DisplayName("转账不能带分类，支出必须有分类")
    void typeRequiresCorrectFields() {
        assertThrows(
                BizException.class,
                () -> ledgerService.createEntry(
                        userId, new CreateLedgerEntryRequest("transfer", 100L, LUNCH, bank, wallet, null, null)));

        assertThrows(
                BizException.class,
                () -> ledgerService.createEntry(
                        userId, new CreateLedgerEntryRequest("expense", 100L, null, bank, null, null, null)));
    }

    @Test
    @DisplayName("分类与流水类型必须匹配：工资分类不能记支出")
    void categoryKindMustMatchType() {
        BizException ex = assertThrows(
                BizException.class,
                () -> ledgerService.createEntry(
                        userId, new CreateLedgerEntryRequest("expense", 100L, SALARY, bank, null, null, null)));
        assertEquals(422, ex.getCode());
    }

    @Test
    @DisplayName("月度汇总按一级分类聚合：一级与二级都能归到餐饮")
    void summaryGroupsByRootCategory() {
        // 直接记一级
        ledgerService.createEntry(
                userId, new CreateLedgerEntryRequest("expense", 1_000L, FOOD, bank, null, null, null));
        // 记二级
        ledgerService.createEntry(
                userId, new CreateLedgerEntryRequest("expense", 2_000L, LUNCH, bank, null, null, null));

        LedgerSummaryDto summary = ledgerService.summary(userId, null);
        assertEquals(3_000L, summary.totalExpenseCents());
        assertEquals(2L, summary.totalCount());

        var food = summary.expenseByCategory().stream()
                .filter(c -> c.categoryId() == FOOD)
                .findFirst()
                .orElseThrow();
        assertEquals(3_000L, food.spentCents(), "一级与二级支出都应归到「餐饮」");
        assertEquals("餐饮", food.categoryName());
    }

    @Test
    @DisplayName("修改流水：从支出改成转账时清空分类")
    void updatingToTransferClearsCategory() {
        LedgerEntryDto entry = ledgerService.createEntry(
                userId, new CreateLedgerEntryRequest("expense", 1_000L, LUNCH, bank, null, null, null));

        LedgerEntryDto updated = ledgerService.updateEntry(
                userId,
                entry.id(),
                new com.haven.backend.ledger.dto.UpdateLedgerEntryRequest(
                        null, null, wallet, null, null, null, null, "transfer"));

        assertEquals("transfer", updated.type());
        assertNull(updated.categoryId(), "转成转账后分类必须清空");
        assertEquals(wallet, updated.toAccountId());
    }

    @Test
    @DisplayName("预算：总预算 = 各项之和，二级支出也能算进一级预算")
    void budgetSumsItemsAndCountsChildCategories() {
        ledgerService.createEntry(
                userId, new CreateLedgerEntryRequest("expense", 1_500L, LUNCH, bank, null, null, null));

        ledgerService.upsertBudget(userId, new UpsertBudgetRequest(FOOD, "2026-11", 100_000L));
        BudgetDto budget = ledgerService.upsertBudget(userId, new UpsertBudgetRequest(OTHER, "2026-11", 50_000L));

        assertEquals(
                100_000L,
                budget.items().stream()
                        .filter(i -> i.categoryId() == FOOD)
                        .findFirst()
                        .orElseThrow()
                        .amountCents());
        assertEquals(150_000L, budget.totalBudgetCents(), "总预算 = 1000 + 500");
        assertEquals(1_500L, budget.totalSpentCents(), "二级「午餐」的支出要算进「餐饮」预算");
    }

    @Test
    @DisplayName("预算只能绑一级支出分类")
    void budgetRequiresExpenseRootCategory() {
        assertThrows(
                BizException.class,
                () -> ledgerService.upsertBudget(userId, new UpsertBudgetRequest(LUNCH, "2026-11", 100L)));
        assertThrows(
                BizException.class,
                () -> ledgerService.upsertBudget(userId, new UpsertBudgetRequest(INCOME_ROOT, "2026-11", 100L)));
    }

    @Test
    @DisplayName("有流水的账户不能删，只能归档")
    void accountWithEntriesCannotBeDeleted() {
        ledgerService.createEntry(userId, new CreateLedgerEntryRequest("expense", 100L, LUNCH, bank, null, null, null));

        BizException ex = assertThrows(BizException.class, () -> ledgerService.deleteAccount(userId, bank));
        assertEquals(409, ex.getCode());

        // 归档是允许的
        ledgerService.updateAccount(userId, bank, new AccountRequest("工资卡", null, "bank", 100_000L, null, true, bank));
        AccountDto archived = ledgerService.listAccounts(userId).stream()
                .filter(a -> a.id().equals(bank))
                .findFirst()
                .orElseThrow();
        assertTrue(archived.archived());
    }

    private long balanceOf(UUID accountId) {
        return ledgerService.listAccounts(userId).stream()
                .filter(a -> a.id().equals(accountId))
                .findFirst()
                .orElseThrow()
                .balanceCents();
    }
}
