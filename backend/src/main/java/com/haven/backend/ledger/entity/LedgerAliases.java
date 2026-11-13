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
import java.util.UUID;

/**
 * 分类别名，例如“奶茶” -> “餐饮”。
 * <p>
 * 主键为 {@code (user_id, alias)}，写入使用自定义 upsert SQL。
 */
@Getter
@Setter
@ToString
@TableName("ledger_aliases")
@Accessors(chain = true)
public class LedgerAliases implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("alias")
    private String alias;

    @TableField("category")
    private String category;
}
