package com.haven.backend.note.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.haven.backend.typehandler.UuidListTypeHandler;
import com.haven.backend.typehandler.UuidTypeHandler;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@ToString
@TableName("note_versions")
public class NoteVersions implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "note_id", typeHandler = UuidTypeHandler.class)
    private UUID noteId;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("title")
    private String title;

    @TableField("content")
    private String content;

    @TableField(value = "folder_id", typeHandler = UuidTypeHandler.class)
    private UUID folderId;

    @TableField(value = "tag_ids", typeHandler = UuidListTypeHandler.class)
    private List<UUID> tagIds;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
