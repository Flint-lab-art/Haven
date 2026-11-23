package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * 新建一条流水。
 * <p>
 * 三种形态由 {@code type} 决定，字段组合由 Service 校验：
 * <ul>
 *   <li>{@code expense} / {@code income}：必须给 {@code categoryId} 与 {@code accountId}；</li>
 *   <li>{@code transfer}：必须给 {@code accountId}（转出）与 {@code toAccountId}（转入），不给分类。</li>
 * </ul>
 */
public record CreateLedgerEntryRequest(
        @NotNull(message = "type 不能为空")
        @Pattern(regexp = "expense|income|transfer", message = "type 只能是 expense、income 或 transfer")
        String type,

        @NotNull(message = "amount_cents 不能为空") @Positive(message = "amount_cents 必须大于 0")
        Long amountCents,

        /** 支出 / 收入的分类；可填一级或二级。 */
        Short categoryId,

        /** 支出 / 收入的账户；转账时的转出账户。 */
        UUID accountId,

        /** 转账的转入账户。 */
        UUID toAccountId,

        @Size(max = 500, message = "备注过长") String note,

        /** 发生时间；为空时使用服务端当前时间。 */
        OffsetDateTime occurredAt) {}
