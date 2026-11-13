package com.haven.backend.ledger.dto;

import java.time.OffsetDateTime;

/**
 * quick 接口解析出的单条记录，可直接作为 batch 接口的 items 元素回传。
 */
public record ParsedLedgerItem(
        int line,
        String raw,
        String type,
        long amountCents,
        String category,
        String note,
        OffsetDateTime occurredAt
) {
}
