package com.haven.backend.note.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.haven.backend.typehandler.UuidTypeHandler;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@ToString
@TableName("notes")
public class Notes implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("title")
    private String title;

    @TableField("content")
    private String content;

    @TableField("visibility")
    private String visibility;

    @TableField("published_at")
    private OffsetDateTime publishedAt;

    @TableField("search_text")
    private String searchText;

    @TableField("created_at")
    private OffsetDateTime createdAt;

    @TableField("updated_at")
    private OffsetDateTime updatedAt;

    @TableField(value = "folder_id", typeHandler = UuidTypeHandler.class)
    private UUID folderId;

    @TableField("sort_order")
    private Integer sortOrder;

    @TableField("deleted_at")
    private OffsetDateTime deletedAt;
}
