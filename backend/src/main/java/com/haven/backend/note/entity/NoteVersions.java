package com.haven.backend.note.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.haven.backend.typehandler.UuidListTypeHandler;
import com.haven.backend.typehandler.UuidTypeHandler;
import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString(exclude = {"content"})
@TableName("note.note_versions")
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

    /** 最近一次合并写入时间；不改写 created_at。 */
    @TableField("updated_at")
    private OffsetDateTime updatedAt;

    /** 合并窗口起点；窗口内编辑只合并内容，不移动该时间点。 */
    @TableField("window_started_at")
    private OffsetDateTime windowStartedAt;
}
