package com.haven.backend.entity;

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
@ToString
@TableName("pending_totp")
public class PendingTotp implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("token")
    private String token;

    @TableField("ip")
    private String ip;

    @TableField("user_agent")
    private String userAgent;

    /** 本次两步验证是否勾选了「信任这台设备」。 */
    @TableField("trust_device")
    private Boolean trustDevice;

    @TableField("expires_at")
    private OffsetDateTime expiresAt;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
