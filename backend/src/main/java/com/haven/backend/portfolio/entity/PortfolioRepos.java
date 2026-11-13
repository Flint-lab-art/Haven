package com.haven.backend.portfolio.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.haven.backend.typehandler.UuidTypeHandler;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.util.UUID;

@Getter
@Setter
@ToString
@TableName("portfolio_repos")
public class PortfolioRepos implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "portfolio_item_id", typeHandler = UuidTypeHandler.class)
    private UUID portfolioItemId;

    @TableField("url")
    private String url;

    @TableField("title")
    private String title;

    @TableField("is_primary")
    private Boolean isPrimary;
}
