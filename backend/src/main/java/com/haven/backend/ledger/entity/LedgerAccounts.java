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
 * 资金账户：现金、储蓄卡、信用卡 / 花呗、微信支付宝。
 * <p>
 * 余额不落库，一律由「期初余额 + 流水累计」实时算出，
 * 避免余额字段与流水打架。
 */
@Getter
@Setter
@ToString
@TableName("ledger.ledger_accounts")
@Accessors(chain = true)
public class LedgerAccounts implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("name")
    private String name;

    /** 图标 key（如 `icbc` / `alipay`）；空串表示不显示图标。 */
    @TableField("icon")
    private String icon;

    /** cash / bank / credit / ewallet，见 {@link AccountTypes}。 */
    @TableField("type")
    private String type;

    /** 期初余额（分）；credit 类表示期初欠款，通常为负数。 */
    @TableField("initial_balance_cents")
    private Long initialBalanceCents;

    @TableField("sort_order")
    private Integer sortOrder;

    /** 归档后不再出现在录入下拉，但历史流水仍引用。 */
    @TableField("archived")
    private Boolean archived;

    @TableField("created_at")
    private OffsetDateTime createdAt;

    @TableField("updated_at")
    private OffsetDateTime updatedAt;
}
