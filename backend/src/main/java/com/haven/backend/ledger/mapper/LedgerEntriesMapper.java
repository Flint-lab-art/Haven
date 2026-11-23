package com.haven.backend.ledger.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.haven.backend.ledger.entity.LedgerEntries;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 流水 Mapper。
 * <p>
 * 常规 CRUD 走 MyBatis-Plus；统计类查询用参数化 SQL 一次聚合，
 * 避免把全量流水拉进内存再算。
 */
public interface LedgerEntriesMapper extends BaseMapper<LedgerEntries> {

    /**
     * 每个账户的余额。
     * <p>
     * 余额 = 期初余额 + 流水累计变动：
     * 支出让账户变少、收入让账户变多；转账时转出账户变少、转入账户变多。
     * 转账的两侧都要算，所以分成「按 account_id」和「按 to_account_id」两段再合并。
     */
    @Select("""
            WITH signed AS (
                -- 支出 / 收入 / 转账转出：都落在 account_id 上
                SELECT account_id AS id,
                       CASE WHEN type = 'income' THEN amount_cents ELSE -amount_cents END AS delta
                FROM ledger.ledger_entries
                WHERE user_id = #{userId}
                  AND account_id IS NOT NULL
                UNION ALL
                -- 转账转入：落在 to_account_id 上，余额增加
                SELECT to_account_id AS id, amount_cents AS delta
                FROM ledger.ledger_entries
                WHERE user_id = #{userId}
                  AND to_account_id IS NOT NULL
            ),
            delta AS (
                SELECT id, SUM(delta) AS total FROM signed GROUP BY id
            )
            SELECT a.id,
                   a.name,
                   a.type,
                   a.initial_balance_cents + COALESCE(d.total, 0) AS balance_cents
            FROM ledger.ledger_accounts a
            LEFT JOIN delta d ON d.id = a.id
            WHERE a.user_id = #{userId}
            ORDER BY a.sort_order, a.name
            """)
    List<AccountBalance> accountBalances(@Param("userId") UUID userId);

    /**
     * 指定区间内按一级分类聚合的支出 / 收入合计。
     * <p>
     * 二级分类用 {@code coalesce(parent_id, id)} 归到一级，
     * 直接把流水记在一级上也不会漏算。转账不计入。
     */
    @Select("""
            SELECT COALESCE(c.parent_id, c.id) AS category_id,
                   SUM(e.amount_cents)        AS amount_cents
            FROM ledger.ledger_entries e
            JOIN ledger.ledger_categories c ON c.id = e.category_id
            WHERE e.user_id = #{userId}
              AND e.type = #{type}
              AND e.occurred_at >= #{from}
              AND e.occurred_at < #{to}
            GROUP BY COALESCE(c.parent_id, c.id)
            """)
    List<CategoryTotal> totalsByRootCategory(
            @Param("userId") UUID userId,
            @Param("type") String type,
            @Param("from") OffsetDateTime from,
            @Param("to") OffsetDateTime to);

    /** 账户余额行。 */
    record AccountBalance(UUID id, String name, String type, Long balanceCents) {}

    /** 一级分类合计行。 */
    record CategoryTotal(Short categoryId, Long amountCents) {}
}
