package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;

/**
 * 设置某个月某个一级分类的预算。
 */
public record UpsertBudgetRequest(
        @NotNull(message = "category_id 不能为空") Short categoryId,

        @NotNull(message = "month 不能为空") @Pattern(regexp = "^\\d{4}-\\d{2}$", message = "month 格式必须是 YYYY-MM")
        String month,

        @NotNull(message = "amount_cents 不能为空") @Positive(message = "amount_cents 必须大于 0")
        Long amountCents) {}
