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
 * 月度预算。只绑一级分类。
 */
@Getter
@Setter
@ToString
@TableName("ledger.ledger_budgets")
@Accessors(chain = true)
public class LedgerBudgets implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    /** 一级分类 id。 */
    @TableField("category_id")
    private Short categoryId;

    /** YYYY-MM。 */
    @TableField("month")
    private String month;

    @TableField("amount_cents")
    private Long amountCents;

    @TableField("created_at")
    private OffsetDateTime createdAt;

    @TableField("updated_at")
    private OffsetDateTime updatedAt;
}
