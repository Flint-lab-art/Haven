package com.haven.backend.ledger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.mapper.UsersMapper;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

/**
 * 记账表结构的数据库约束：类型组合、金额精度、分类层级、预算唯一性。
 * <p>
 * 这些约束是最后一道防线：Service 已经校验过，但绕过 Service 的写入
 * （脚本、手工 SQL、未来新入口）仍必须被数据库拒绝。
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class LedgerConstraintTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private UsersMapper usersMapper;

    private UUID newUser() {
        Users user = new Users();
        user.setId(UUID.randomUUID());
        user.setUsername("cons-" + UUID.randomUUID().toString().substring(0, 8));
        user.setPasswordHash("x");
        user.setTotpEnabled(false);
        user.setCreatedAt(OffsetDateTime.now());
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.insert(user);
        return user.getId();
    }

    private UUID newAccount(UUID userId, String name, String type) {
        return newAccountIn(jdbc, userId, name, type);
    }

    private UUID newAccountIn(JdbcTemplate jdbc, UUID userId, String name, String type) {
        UUID id = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO ledger.ledger_accounts (id, user_id, name, type) VALUES (?::uuid, ?::uuid, ?, ?)",
                id.toString(),
                userId.toString(),
                name,
                type);
        return id;
    }

    /**
     * 断言某条写入会被数据库拒绝。
     * <p>
     * 约束失败会让当前事务进入 aborted 状态，后续语句全报 25P02。
     * 所以这里走**自动提交**（不包进任何事务）：失败只影响这一条，
     * 不会污染外层，也不需要额外借连接开嵌套事务——
     * 之前用 {@code REQUIRES_NEW} 的做法在连接异常时会留下 idle in transaction，
     * 让后续断言等到连接超时。
     */
    private void assertRejected(String sql, Object... args) {
        RuntimeException error = null;
        try {
            jdbc.execute((org.springframework.jdbc.core.ConnectionCallback<Void>) (connection) -> {
                boolean original = connection.getAutoCommit();
                connection.setAutoCommit(true);
                try (var statement = connection.prepareStatement(sql)) {
                    for (int i = 0; i < args.length; i++) {
                        statement.setObject(i + 1, args[i]);
                    }
                    statement.executeUpdate();
                } catch (java.sql.SQLException e) {
                    throw new RuntimeException(e);
                } finally {
                    connection.setAutoCommit(original);
                }
                return null;
            });
        } catch (RuntimeException e) {
            error = e;
        }
        assertNotNull(error, "预期被数据库拒绝，但写入成功了：" + sql);
    }

    @Test
    @DisplayName("金额列是整数分，不会悄悄变成浮点")
    void amountColumnIsInteger() {
        String dataType = jdbc.queryForObject(
                "SELECT data_type FROM information_schema.columns "
                        + "WHERE table_schema = 'ledger' AND table_name = 'ledger_entries' "
                        + "AND column_name = 'amount_cents'",
                String.class);
        assertEquals("bigint", dataType, "金额必须用整数分存储，避免浮点误差");
    }

    @Test
    @DisplayName("金额必须大于 0")
    void amountMustBePositive() {
        UUID uid = newUser();
        UUID acc = newAccount(uid, "卡", "bank");
        assertRejected(
                "INSERT INTO ledger.ledger_entries (user_id, type, amount_cents, category_id, account_id, occurred_at) "
                        + "VALUES (?::uuid, 'expense', 0, 102, ?::uuid, now())",
                uid.toString(),
                acc.toString());
    }

    @Test
    @DisplayName("转账必须两个账户且不同；不能带分类")
    void transferShapeIsEnforced() {
        UUID uid = newUser();
        UUID a = newAccount(uid, "A", "bank");
        UUID b = newAccount(uid, "B", "ewallet");

        // 缺少转入账户
        assertRejected(
                "INSERT INTO ledger.ledger_entries (user_id, type, amount_cents, account_id, occurred_at) "
                        + "VALUES (?::uuid, 'transfer', 100, ?::uuid, now())",
                uid.toString(),
                a.toString());

        // 两侧相同
        assertRejected(
                "INSERT INTO ledger.ledger_entries "
                        + "(user_id, type, amount_cents, account_id, to_account_id, occurred_at) "
                        + "VALUES (?::uuid, 'transfer', 100, ?::uuid, ?::uuid, now())",
                uid.toString(),
                a.toString(),
                a.toString());

        // 带分类
        assertRejected(
                "INSERT INTO ledger.ledger_entries "
                        + "(user_id, type, amount_cents, category_id, account_id, to_account_id, occurred_at) "
                        + "VALUES (?::uuid, 'transfer', 100, 102, ?::uuid, ?::uuid, now())",
                uid.toString(),
                a.toString(),
                b.toString());

        // 合法转账
        jdbc.update(
                "INSERT INTO ledger.ledger_entries "
                        + "(user_id, type, amount_cents, account_id, to_account_id, occurred_at) "
                        + "VALUES (?::uuid, 'transfer', 100, ?::uuid, ?::uuid, now())",
                uid.toString(),
                a.toString(),
                b.toString());
        assertEquals(
                1,
                jdbc.queryForObject(
                        "SELECT count(*) FROM ledger.ledger_entries WHERE user_id = ?::uuid AND type = 'transfer'",
                        Integer.class,
                        uid.toString()));
    }

    @Test
    @DisplayName("支出 / 收入必须有分类且不能有转入账户")
    void expenseShapeIsEnforced() {
        UUID uid = newUser();
        UUID a = newAccount(uid, "A", "bank");
        UUID b = newAccount(uid, "B", "ewallet");

        // 缺分类
        assertRejected(
                "INSERT INTO ledger.ledger_entries (user_id, type, amount_cents, account_id, occurred_at) "
                        + "VALUES (?::uuid, 'expense', 100, ?::uuid, now())",
                uid.toString(),
                a.toString());

        // 支出却带了转入账户
        assertRejected(
                "INSERT INTO ledger.ledger_entries "
                        + "(user_id, type, amount_cents, category_id, account_id, to_account_id, occurred_at) "
                        + "VALUES (?::uuid, 'expense', 100, 102, ?::uuid, ?::uuid, now())",
                uid.toString(),
                a.toString(),
                b.toString());
    }

    @Test
    @DisplayName("流水类型只允许 expense / income / transfer")
    void typeWhitelistIsEnforced() {
        UUID uid = newUser();
        UUID acc = newAccount(uid, "卡", "bank");
        assertRejected(
                "INSERT INTO ledger.ledger_entries (user_id, type, amount_cents, category_id, account_id, occurred_at) "
                        + "VALUES (?::uuid, 'unknown', 100, 102, ?::uuid, now())",
                uid.toString(),
                acc.toString());
    }

    @Test
    @DisplayName("分类种子：一级 7 支出 + 1 收入，二级都有父")
    void categorySeedIsConsistent() {
        List<Short> roots = jdbc.queryForList(
                "SELECT id FROM ledger.ledger_categories WHERE parent_id IS NULL ORDER BY id", Short.class);
        assertEquals(
                List.of((short) 1, (short) 2, (short) 3, (short) 4, (short) 5, (short) 6, (short) 7, (short) 8), roots);

        Integer orphan = jdbc.queryForObject(
                "SELECT count(*) FROM ledger.ledger_categories c "
                        + "WHERE c.parent_id IS NOT NULL AND NOT EXISTS "
                        + "(SELECT 1 FROM ledger.ledger_categories p WHERE p.id = c.parent_id)",
                Integer.class);
        assertEquals(0, orphan, "每个二级分类都必须有存在的父级");

        Integer transferChildren = jdbc.queryForObject(
                "SELECT count(*) FROM ledger.ledger_categories WHERE parent_id IS NOT NULL AND kind = 'transfer'",
                Integer.class);
        assertEquals(0, transferChildren);
    }

    @Test
    @DisplayName("预算：同月同分类唯一，金额必须大于 0")
    void budgetConstraintsHold() {
        UUID uid = newUser();
        jdbc.update(
                "INSERT INTO ledger.ledger_budgets (user_id, category_id, month, amount_cents) "
                        + "VALUES (?::uuid, 1, '2026-11', 100000)",
                uid.toString());

        // 同月同分类只能有一条
        assertRejected(
                "INSERT INTO ledger.ledger_budgets (user_id, category_id, month, amount_cents) "
                        + "VALUES (?::uuid, 1, '2026-11', 50000)",
                uid.toString());

        // 预算金额必须大于 0
        assertRejected(
                "INSERT INTO ledger.ledger_budgets (user_id, category_id, month, amount_cents) "
                        + "VALUES (?::uuid, 2, '2026-11', 0)",
                uid.toString());
    }

    @Test
    @DisplayName("账户：同用户下名称不区分大小写唯一")
    void accountNameIsUniquePerUser() {
        UUID uid = newUser();
        newAccount(uid, "Cash", "cash");
        // 同名账户（忽略大小写）应被拒绝
        assertRejected(
                "INSERT INTO ledger.ledger_accounts (id, user_id, name, type) VALUES (?::uuid, ?::uuid, ?, ?)",
                UUID.randomUUID().toString(),
                uid.toString(),
                "cash",
                "cash");
    }

    @Test
    @DisplayName("账户类型只允许 cash / bank / credit / ewallet")
    void accountTypeWhitelist() {
        UUID uid = newUser();
        assertRejected(
                "INSERT INTO ledger.ledger_accounts (id, user_id, name, type) VALUES (?::uuid, ?::uuid, ?, ?)",
                UUID.randomUUID().toString(),
                uid.toString(),
                "奇怪账户",
                "bitcoin");

        // 合法类型可以写
        newAccount(uid, "信用卡", "credit");
        assertEquals(
                1,
                jdbc.queryForObject(
                        "SELECT count(*) FROM ledger.ledger_accounts WHERE user_id = ?::uuid AND type = 'credit'",
                        Integer.class,
                        uid.toString()));
    }
}
