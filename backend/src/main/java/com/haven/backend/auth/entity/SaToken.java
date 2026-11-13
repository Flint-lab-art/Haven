package com.haven.backend.auth.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.OffsetDateTime;

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
@TableName("sa_token")
public class SaToken implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("token_value")
    private String tokenValue;

    @TableField("token_type")
    private String tokenType;

    @TableField("login_id")
    private String loginId;

    @TableField("device")
    private String device;

    @TableField("token_timeout")
    private Long tokenTimeout;

    @TableField("session_timeout")
    private Long sessionTimeout;

    @TableField("extra_data")
    private Object extraData;

    @TableField("create_time")
    private OffsetDateTime createTime;

    @TableField("last_active_time")
    private OffsetDateTime lastActiveTime;
}
