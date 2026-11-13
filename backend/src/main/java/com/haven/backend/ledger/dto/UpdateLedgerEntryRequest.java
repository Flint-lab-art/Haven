package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.Positive;

import java.time.OffsetDateTime;

/**
 * 事后修正记账条目，只允许改分类、金额与发生时间。
 */
public record UpdateLedgerEntryRequest(
        String category,

        @Positive(message = "amount_cents 必须大于 0")
        Long amountCents,

        OffsetDateTime occurredAt
) {
}
