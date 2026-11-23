package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * 事后修正一条流水。
 * <p>
 * 所有字段可选，传 null 表示不改。{@code clearToAccount} 用于把转账改回支出 / 收入
 * 时显式清掉转入账户（MyBatis-Plus 的 updateById 会跳过 null）。
 */
public record UpdateLedgerEntryRequest(
        Short categoryId,

        UUID accountId,

        UUID toAccountId,

        /** 为 true 时清空转入账户。 */
        Boolean clearToAccount,

        @Positive(message = "amount_cents 必须大于 0") Long amountCents,

        @Size(max = 500, message = "备注过长") String note,

        /** 传空字符串表示清空备注。 */
        OffsetDateTime occurredAt,

        @Pattern(regexp = "expense|income|transfer", message = "type 只能是 expense、income 或 transfer")
        String type) {}
