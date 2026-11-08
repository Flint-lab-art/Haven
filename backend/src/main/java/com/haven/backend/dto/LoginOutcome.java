package com.haven.backend.dto;

import java.util.Map;

/**
 * 登录结果。
 *
 * @param body               返回给前端的 JSON 字段
 * @param trustedDeviceToken 本次新创建的授信设备明文令牌（需要写入 Cookie），没有则为 null
 */
public record LoginOutcome(Map<String, Object> body, String trustedDeviceToken) {
}
