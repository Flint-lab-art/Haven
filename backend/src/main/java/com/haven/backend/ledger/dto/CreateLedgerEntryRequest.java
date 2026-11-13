package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;

import java.time.OffsetDateTime;

/**
 * 批次内单条记账记录。
 */
public record CreateLedgerEntryRequest(

        @NotBlank(message = "type 不能为空")
        @Pattern(regexp = "expense|income", message = "type 只能是 expense 或 income")
        String type,

        @NotNull(message = "amount_cents 不能为空")
        @Positive(message = "amount_cents 必须大于 0")
        Long amountCents,

        @NotBlank(message = "category 不能为空")
        String category,

        String note,

        /** 消费/收入发生时间；为空时使用服务端当前时间。 */
        OffsetDateTime occurredAt
) {
}
