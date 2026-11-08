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
@TableName("tokens")
public class Tokens implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("id")
    private UUID id;

    @TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
    private UUID userId;

    @TableField("name")
    private String name;

    @TableField("token_hash")
    private String tokenHash;

    @TableField("token_prefix")
    private String tokenPrefix;

    @TableField("scope")
    private String scope;

    @TableField("expires_at")
    private OffsetDateTime expiresAt;

    @TableField("last_used_at")
    private OffsetDateTime lastUsedAt;

    @TableField("revoked_at")
    private OffsetDateTime revokedAt;

    @TableField("created_at")
    private OffsetDateTime createdAt;
}
