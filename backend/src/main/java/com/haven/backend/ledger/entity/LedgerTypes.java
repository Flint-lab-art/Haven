package com.haven.backend.ledger.entity;

import java.util.List;

/**
 * 流水类型（对应 {@code ledger_entries.type}）。
 */
public final class LedgerTypes {

    /** 支出：计入支出统计。 */
    public static final String EXPENSE = "expense";
    /** 收入：计入收入统计。 */
    public static final String INCOME = "income";
    /** 转账：自己账户之间移动资金，**不计入任何收支统计**。 */
    public static final String TRANSFER = "transfer";

    /** 会计入收支统计的类型。 */
    public static final List<String> STATISTICAL = List.of(EXPENSE, INCOME);

    /** 允许的全部类型，用于入参校验。 */
    public static final List<String> ALL = List.of(EXPENSE, INCOME, TRANSFER);

    /** 是否是需要分类的类型（支出 / 收入）。 */
    public static boolean needsCategory(String type) {
        return EXPENSE.equals(type) || INCOME.equals(type);
    }

    /** 是否是转账。 */
    public static boolean isTransfer(String type) {
        return TRANSFER.equals(type);
    }

    private LedgerTypes() {}
}
