package com.haven.backend.ledger.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.io.Serial;
import java.io.Serializable;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import lombok.experimental.Accessors;

/**
 * 两级分类。
 * <p>
 * 一级 {@code parentId} 为 null；二级指向所属一级。
 * 统计时用 {@code coalesce(parent_id, id)} 把二级归到一级，
 * 这样直接把流水记在一级上也不会被漏算。
 * <p>
 * 删除一律软删（{@code enabled = false}）：历史流水还引用着，物理删会断。
 */
@Getter
@Setter
@ToString
@TableName("ledger.ledger_categories")
@Accessors(chain = true)
public class LedgerCategories implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private Short id;

    @TableField("parent_id")
    private Short parentId;

    @TableField("name")
    private String name;

    /** emoji 图标；空串表示没有。 */
    @TableField("icon")
    private String icon;

    /** expense / income / transfer，见 {@link LedgerTypes}。 */
    @TableField("kind")
    private String kind;

    @TableField("sort_order")
    private Integer sortOrder;

    @TableField("enabled")
    private Boolean enabled;
}
