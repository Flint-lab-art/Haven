package com.haven.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 统一 API 响应包装。
 */
@Data
@AllArgsConstructor(staticName = "of")
public class ApiResponse<T> {

    private int code;
    private String message;
    private T data;

    public static <T> ApiResponse<T> ok(T data) {
        return of(0, "ok", data);
    }

    public static <T> ApiResponse<T> ok() {
        return of(0, "ok", null);
    }

    public static <T> ApiResponse<T> err(int code, String message) {
        return of(code, message, null);
    }
}
