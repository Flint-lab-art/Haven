package com.haven.backend.ledger.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.haven.backend.typehandler.UuidTypeHandler;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serial;
import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@ToString
@TableName("ledger_entries")
@Accessors(chain = true)
public class LedgerEntries implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    /** expense / income。 */
    @TableField("type")
    private String type;

    @TableField("amount_cents")
    private Long amountCents;

    /** 餐饮 / 购物 / 交通 / 居家 / 娱乐 / 医疗 / 未分类。 */
    @TableField("category")
    private String category;

    @TableField("note")
    private String note;

    @TableField("occurred_at")
    private OffsetDateTime occurredAt;

    @TableField("batch_id")
    private String batchId;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
