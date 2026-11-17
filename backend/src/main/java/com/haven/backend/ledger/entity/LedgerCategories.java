package com.haven.backend.ledger.entity;

import java.util.List;
import java.util.Set;
import java.util.stream.Stream;

/**
 * 记账分类清单（与迁移 V4/V6/V10/V12 的 CHECK 约束保持一致）。
 * <p>
 * 分类清单属于领域数据，放在这里而不是 ServiceImpl 的静态字段里，
 * 也避免手工拼接"支出+收入"导致两份清单漂移。
 * <p>
 * 加分类时必须同时改三处，漏一处会导致写入被数据库拒绝：
 * 1. 这里（后端白名单与分类识别）
 * 2. {@code frontend/src/utils/ledger.ts}（下拉选项、色阶、图表颜色）
 * 3. 一个新的迁移脚本（放宽 CHECK 约束，并补默认别名）
 */
public final class LedgerCategories {

    /** 支出大类。 */
    public static final List<String> EXPENSE = List.of("餐饮", "购物", "交通", "居家", "娱乐", "医疗", "还款", "Token", "未分类");

    /** 收入大类：与支出共用单层 category 字段，用 type 区分方向。 */
    public static final List<String> INCOME = List.of("工资", "奖金", "报销", "退款", "红包", "其他收入");

    /** 所有允许的分类（由支出 + 收入派生，避免重复维护）。 */
    public static final List<String> ALL =
            Stream.concat(EXPENSE.stream(), INCOME.stream()).toList();

    /** 允许的分类集合，便于 O(1) 校验。 */
    public static final Set<String> ALL_SET = Set.copyOf(ALL);

    /** 收入分类集合。 */
    public static final Set<String> INCOME_SET = Set.copyOf(INCOME);

    private LedgerCategories() {}
}
