package com.haven.backend.exception;

import lombok.Getter;

/**
 * 业务异常，由 GlobalExceptionHandler 统一捕获并转为 ApiResponse。
 */
@Getter
public class BizException extends RuntimeException {

    private final int code;

    public BizException(int code, String message) {
        super(message);
        this.code = code;
    }

    public BizException(String message) {
        this(400, message);
    }

    public static BizException notFound(String message) {
        return new BizException(404, message);
    }

    public static BizException unauthorized(String message) {
        return new BizException(401, message);
    }

    public static BizException conflict(String message) {
        return new BizException(409, message);
    }

    public static BizException forbidden(String message) {
        return new BizException(403, message);
    }

    public static BizException validation(String message) {
        return new BizException(422, message);
    }

    public static BizException internal(String message) {
        return new BizException(500, message);
    }
}
