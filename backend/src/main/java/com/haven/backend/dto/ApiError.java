package com.haven.backend.dto;

import java.util.Map;

/**
 * 统一错误响应体：{@code {error, message, fields?}}。
 *
 * @param error 机器可读错误码，如 validation_failed
 * @param message 人类可读描述
 * @param fields 字段级错误，没有时为 null（不序列化）
 */
public record ApiError(String error, String message, Map<String, String> fields) {

    /** 只有 error + message 的错误体。 */
    public static ApiError of(String error, String message) {
        return new ApiError(error, message, null);
    }
}
