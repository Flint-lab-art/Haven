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
 * 登录日志。
 * <p>
 * 与 {@code audit_events} 分开：登录事件需要独立的事务语义（失败日志必须在
 * 登录事务回滚后仍然保留），查询也只需要固定字段。
 */
@Getter
@Setter
@ToString(exclude = {"ip", "userAgent", "sessionHash"})
@TableName("login_logs")
public class LoginLogs implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("username")
    private String username;

    @TableField("event_type")
    private String eventType;

    @TableField("method")
    private String method;

    @TableField("success")
    private boolean success;

    @TableField("failure_reason")
    private String failureReason;

    @TableField("ip")
    private String ip;

    @TableField("user_agent")
    private String userAgent;

    @TableField("session_hash")
    private String sessionHash;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
