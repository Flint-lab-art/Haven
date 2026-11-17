package com.haven.backend.ledger.entity;

import java.util.List;

/**
 * 记账方向（对应 {@code ledger_entries.type}）。
 */
public final class LedgerTypes {

    /** 支出。 */
    public static final String EXPENSE = "expense";
    /** 收入。 */
    public static final String INCOME = "income";

    /** 允许的全部方向，用于批量校验。 */
    public static final List<String> ALL = List.of(EXPENSE, INCOME);

    private LedgerTypes() {}
}
