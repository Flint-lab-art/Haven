package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import java.time.OffsetDateTime;

/**
 * 事后修正记账条目：分类、收支方向、金额与发生时间。
 * <p>
 * {@code type} 与 {@code category} 必须方向一致（支出分类配 {@code expense}、收入分类配 {@code income}），
 * 校验在服务层做——因为单独改 {@code type} 时也要拿现有分类来判断。
 */
public record UpdateLedgerEntryRequest(
        String category,

        /** {@code expense} 或 {@code income}；不传表示不改方向。 */
        @Pattern(regexp = "^(expense|income)$", message = "type 只能是 expense 或 income")
        String type,

        @Positive(message = "amount_cents 必须大于 0") Long amountCents,

        OffsetDateTime occurredAt) {}
