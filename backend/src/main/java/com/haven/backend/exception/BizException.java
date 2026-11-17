package com.haven.backend.exception;

import lombok.Getter;

/**
 * 业务异常：携带 HTTP 状态码，由 {@link GlobalExceptionHandler} 统一转成 {@code {error,message}}。
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
