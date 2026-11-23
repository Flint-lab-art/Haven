package com.haven.backend.ledger.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.haven.backend.typehandler.UuidTypeHandler;
import java.io.Serial;
import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import lombok.experimental.Accessors;

/**
 * 一条流水。
 * <p>
 * 三种形态（由数据库 {@code ledger_entries_shape_check} 兜底）：
 * <ul>
 *   <li>支出 / 收入：有 {@code categoryId} 与 {@code accountId}，{@code toAccountId} 为空；</li>
 *   <li>转账：有 {@code accountId}（转出）与 {@code toAccountId}（转入），{@code categoryId} 为空。</li>
 * </ul>
 * 转账不计入收支统计。
 */
@Getter
@Setter
@ToString
@TableName("ledger.ledger_entries")
@Accessors(chain = true)
public class LedgerEntries implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    /** expense / income / transfer。 */
    @TableField("type")
    private String type;

    @TableField("amount_cents")
    private Long amountCents;

    /** 支出 / 收入的分类；转账为空。 */
    @TableField("category_id")
    private Short categoryId;

    /** 支出 / 收入的资金账户；转账时的转出账户。 */
    @TableField(value = "account_id", typeHandler = UuidTypeHandler.class)
    private UUID accountId;

    /** 转账时的转入账户；支出 / 收入为空。 */
    @TableField(value = "to_account_id", typeHandler = UuidTypeHandler.class)
    private UUID toAccountId;

    @TableField("note")
    private String note;

    @TableField("occurred_at")
    private OffsetDateTime occurredAt;

    @TableField("created_at")
    private OffsetDateTime createdAt;

    @TableField("updated_at")
    private OffsetDateTime updatedAt;
}
