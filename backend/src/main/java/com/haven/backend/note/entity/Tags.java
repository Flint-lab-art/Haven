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
@TableName("tags")
public class Tags implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("name")
    private String name;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
