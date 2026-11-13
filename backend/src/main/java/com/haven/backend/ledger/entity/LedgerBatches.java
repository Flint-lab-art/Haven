package com.haven.backend.ledger.entity;

import com.baomidou.mybatisplus.annotation.TableField;
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

/**
 * 记账批次，用于支撑 batch_id 幂等。
 * <p>
 * 主键为 {@code (user_id, batch_id)}，MyBatis-Plus 不支持复合主键查询，
 * 因此这里不使用 selectById/updateById，统一通过 Wrapper 或自定义 SQL 操作。
 */
@Getter
@Setter
@ToString
@TableName("ledger_batches")
@Accessors(chain = true)
public class LedgerBatches implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("batch_id")
    private String batchId;

    @TableField("raw_text")
    private String rawText;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
