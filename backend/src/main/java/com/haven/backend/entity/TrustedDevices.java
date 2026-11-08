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
 * 授信设备：30 天内同设备登录免动态码。
 */
@Getter
@Setter
@ToString
@TableName("trusted_devices")
public class TrustedDevices implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("device_name")
    private String deviceName;

    /** 客户端携带的明文设备令牌的 SHA-256 哈希。 */
    @TableField("token_hash")
    private String tokenHash;

    @TableField("created_at")
    private OffsetDateTime createdAt;

    @TableField("last_used_at")
    private OffsetDateTime lastUsedAt;

    @TableField("expires_at")
    private OffsetDateTime expiresAt;
}
