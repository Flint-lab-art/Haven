package com.haven.backend.ledger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.haven.backend.ledger.entity.LedgerCategories;
import com.haven.backend.ledger.entity.LedgerEntries;
import com.haven.backend.ledger.mapper.LedgerEntriesMapper;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * 记账表的数据库约束测试。
 * <p>
 * 这些约束是金额正确性的最后一道防线：即便 service 层校验被改坏，或者有人绕过 API 直接写库，
 * 数据库也必须拒绝非法金额与非法分类。
 * <p>
 * 关键点：PostgreSQL 在事务内触发约束错误后，<b>整个事务会进入 aborted 状态</b>（25P02），
 * 后续语句一律失败。因此每个写入用例都放在<b>独立的子事务</b>里执行，
 * 无论成功还是失败都只回滚这一个子事务，外层测试事务不受影响。
 */
@SpringBootTest
@ActiveProfiles("test")
class LedgerConstraintTest {

    @Autowired
    private LedgerEntriesMapper entriesMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private PlatformTransactionManager transactionManager;

    @Test
    @DisplayName("0 元与负数金额被数据库拒绝")
    void nonPositiveAmountIsRejected() {
        assertInsertRejected(0L);
        assertInsertRejected(-1L);
        assertInsertRejected(-100_000L);
    }

    @Test
    @DisplayName("1 分是最小合法金额")
    void oneCentIsAccepted() {
        // 在子事务里写入并同事务读回，随后整体回滚
        long readBack = insertAndReadBackCents(1L);

        assertEquals(1L, readBack);
    }

    @Test
    @DisplayName("大额金额不会被截断（bigint 而非 int4）")
    void largeAmountIsNotTruncated() {
        // 100 万元；用 int4 存分会溢出
        long oneMillionYuanInCents = 100_000_000L;

        assertEquals(oneMillionYuanInCents, insertAndReadBackCents(oneMillionYuanInCents));
    }

    @Test
    @DisplayName("金额列必须是整数类型（分），不能悄悄变成浮点")
    void amountColumnIsInteger() {
        String dataType = jdbc.queryForObject(
                "SELECT data_type FROM information_schema.columns "
                        + "WHERE table_schema = current_schema() "
                        + "AND table_name = 'ledger_entries' AND column_name = 'amount_cents'",
                String.class);

        assertEquals("bigint", dataType, "金额必须用整数分存储，避免浮点误差");
    }

    @Test
    @DisplayName("非法分类被数据库拒绝")
    void unknownCategoryIsRejected() {
        assertThrows(
                DataIntegrityViolationException.class,
                () -> inRolledBackTransaction(() -> insertWithCategory(1200L, "不存在的分类")));
    }

    @Test
    @DisplayName("「还款」是合法分类")
    void repaymentCategoryIsAccepted() {
        String category = inRolledBackTransaction(() -> {
            UUID id = insertWithCategory(200000L, "还款");
            return jdbc.queryForObject(
                    "SELECT category FROM ledger_entries WHERE id = ?::uuid", String.class, id.toString());
        });

        assertEquals("还款", category);
    }

    @Test
    @DisplayName("非法方向被数据库拒绝")
    void unknownTypeIsRejected() {
        assertThrows(
                DataIntegrityViolationException.class,
                () -> inRolledBackTransaction(() -> insertWithType(1200L, "transfer")));
    }

    @Test
    @DisplayName("分类白名单与后端常量保持一致")
    void categoryWhitelistMatchesJavaConstants() {
        String definition = jdbc.queryForObject(
                "SELECT pg_get_constraintdef(oid) FROM pg_constraint "
                        + "WHERE conname = 'ledger_entries_category_check' "
                        + "AND connamespace = current_schema()::regnamespace",
                String.class);

        assertNotNull(definition);
        for (String category : LedgerCategories.ALL) {
            assertTrue(definition.contains("'" + category + "'"), "数据库约束缺少分类「" + category + "」：" + definition);
        }
    }

    // -----------------------------------------------------------------------

    /** 断言写入被拒绝；子事务保证失败只 abort 自己。 */
    private void assertInsertRejected(long amountCents) {
        assertThrows(
                DataIntegrityViolationException.class,
                () -> inRolledBackTransaction(() -> {
                    insert(amountCents);
                    return null;
                }));
    }

    /** 在子事务里写入并读回金额，随后回滚。 */
    private long insertAndReadBackCents(long amountCents) {
        Long cents = inRolledBackTransaction(() -> {
            UUID id = insert(amountCents);
            return jdbc.queryForObject(
                    "SELECT amount_cents FROM ledger_entries WHERE id = ?::uuid", Long.class, id.toString());
        });
        assertNotNull(cents);
        return cents;
    }

    /**
     * 在 REQUIRES_NEW 子事务里执行并总是回滚。
     * <p>
     * 子事务隔离了"约束失败导致事务 abort"的副作用，外层测试事务始终可用。
     */
    private <T> T inRolledBackTransaction(java.util.function.Supplier<T> action) {
        TransactionTemplate template = new TransactionTemplate(transactionManager);
        template.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        return template.execute(status -> {
            try {
                return action.get();
            } finally {
                status.setRollbackOnly();
            }
        });
    }

    private UUID insert(long amountCents) {
        return insertWithCategory(amountCents, "餐饮");
    }

    private UUID insertWithCategory(long amountCents, String category) {
        return insertInternal(amountCents, category, "expense");
    }

    private UUID insertWithType(long amountCents, String type) {
        return insertInternal(amountCents, "餐饮", type);
    }

    private UUID insertInternal(long amountCents, String category, String type) {
        // 先建用户与批次：V11 起 ledger_entries 有指向 users 和 ledger_batches 的外键，
        // 测试数据必须自洽，否则任何插入都会因「父记录不存在」失败，
        // 把真正的约束错误（金额、分类）淹没在外键错误里。
        UUID userId = UUID.randomUUID();
        String batchId = "constraint-test-" + UUID.randomUUID();
        jdbc.update(
                "INSERT INTO users (id, username, password_hash) VALUES (?::uuid, ?, ?)",
                userId.toString(),
                "constraint-" + userId,
                "x");
        jdbc.update("INSERT INTO ledger_batches (user_id, batch_id) VALUES (?::uuid, ?)", userId.toString(), batchId);

        LedgerEntries entry = new LedgerEntries()
                .setId(UUID.randomUUID())
                .setUserId(userId)
                .setType(type)
                .setAmountCents(amountCents)
                .setCategory(category)
                .setNote("")
                .setOccurredAt(OffsetDateTime.now())
                .setBatchId(batchId)
                .setCreatedAt(OffsetDateTime.now());
        entriesMapper.insert(entry);
        return entry.getId();
    }

    @Test
    @DisplayName("删除用户会级联清理记账数据（V11 外键）")
    void deletingUserCascadesLedgerData() {
        inRolledBackTransaction(() -> {
            UUID userId = UUID.randomUUID();
            jdbc.update(
                    "INSERT INTO users (id, username, password_hash) VALUES (?::uuid, ?, ?)",
                    userId.toString(),
                    "cascade-" + userId,
                    "x");
            jdbc.update("INSERT INTO ledger_batches (user_id, batch_id) VALUES (?::uuid, 'b1')", userId.toString());
            jdbc.update("""
                    INSERT INTO ledger_entries (user_id, type, amount_cents, category, occurred_at, batch_id)
                    VALUES (?::uuid, 'expense', 100, '餐饮', now(), 'b1')
                    """, userId.toString());
            jdbc.update(
                    "INSERT INTO ledger_aliases (user_id, alias, category) VALUES (?::uuid, '午餐', '餐饮')",
                    userId.toString());

            jdbc.update("DELETE FROM users WHERE id = ?::uuid", userId.toString());

            // 三张表都必须被清空，否则就是遗留的孤儿数据
            assertEquals(0, count("SELECT count(*) FROM ledger_entries WHERE user_id = ?::uuid", userId));
            assertEquals(0, count("SELECT count(*) FROM ledger_batches WHERE user_id = ?::uuid", userId));
            assertEquals(0, count("SELECT count(*) FROM ledger_aliases WHERE user_id = ?::uuid", userId));
            return null;
        });
    }

    @Test
    @DisplayName("明细不能引用不存在的批次")
    void entryRequiresExistingBatch() {
        assertThrows(
                DataIntegrityViolationException.class,
                () -> inRolledBackTransaction(() -> {
                    UUID userId = UUID.randomUUID();
                    jdbc.update(
                            "INSERT INTO users (id, username, password_hash) VALUES (?::uuid, ?, ?)",
                            userId.toString(),
                            "orphan-" + userId,
                            "x");
                    // 建了用户但没建批次 b-missing
                    jdbc.update("""
                            INSERT INTO ledger_entries (user_id, type, amount_cents, category, occurred_at, batch_id)
                            VALUES (?::uuid, 'expense', 100, '餐饮', now(), 'b-missing')
                            """, userId.toString());
                    return null;
                }));
    }

    private int count(String sql, UUID userId) {
        Integer n = jdbc.queryForObject(sql, Integer.class, userId.toString());
        return n == null ? 0 : n;
    }
}
