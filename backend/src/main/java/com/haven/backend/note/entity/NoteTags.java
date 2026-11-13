package com.haven.backend.note.entity;

import com.baomidou.mybatisplus.annotation.TableField;
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
@TableName("note_tags")
public class NoteTags implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableField(value = "note_id", typeHandler = UuidTypeHandler.class)
    private UUID noteId;

    @TableField(value = "tag_id", typeHandler = UuidTypeHandler.class)
    private UUID tagId;
}
