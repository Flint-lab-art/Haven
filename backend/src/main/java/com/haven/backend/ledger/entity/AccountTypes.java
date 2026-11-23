package com.haven.backend.ledger.entity;

import java.util.List;

/**
 * 账户类型（对应 {@code ledger_accounts.type}）。
 */
public final class AccountTypes {

    /** 现金。 */
    public static final String CASH = "cash";
    /** 储蓄卡 / 借记卡。 */
    public static final String BANK = "bank";
    /** 信用卡 / 花呗 / 白条，余额表示欠款。 */
    public static final String CREDIT = "credit";
    /** 微信 / 支付宝等电子钱包。 */
    public static final String EWALLET = "ewallet";

    public static final List<String> ALL = List.of(CASH, BANK, CREDIT, EWALLET);

    private AccountTypes() {}
}
