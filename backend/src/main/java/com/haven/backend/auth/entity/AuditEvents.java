package com.haven.backend.auth.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.haven.backend.typehandler.UuidTypeHandler;
import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/**
 * <p>
 *
 * </p>
 *
 * @author Kairo
 * @since 2026-11-08
 */
@Getter
@Setter
@ToString(exclude = {"metadata", "ip", "userAgent"})
@TableName("audit_events")
public class AuditEvents implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "actor_user_id", typeHandler = UuidTypeHandler.class)
    private UUID actorUserId;

    @TableField("actor_username")
    private String actorUsername;

    @TableField("event_type")
    private String eventType;

    @TableField("target_type")
    private String targetType;

    @TableField("target_id")
    private Object targetId;

    @TableField("metadata")
    private Object metadata;

    @TableField("ip")
    private String ip;

    @TableField("user_agent")
    private String userAgent;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
