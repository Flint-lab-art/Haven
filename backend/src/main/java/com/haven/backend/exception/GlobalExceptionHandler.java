package com.haven.backend.exception;

import cn.dev33.satoken.exception.NotLoginException;
import cn.dev33.satoken.exception.NotPermissionException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 全局异常处理，输出格式对齐 Go 端 API 契约（docs/api.md 1.4）：
 * <pre>
 * { "error": "error_code", "message": "人类可读描述", "fields": {...} }
 * </pre>
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BizException.class)
    @ResponseStatus(HttpStatus.OK)
    public Map<String, Object> handleBiz(BizException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", mapBizCode(e.getCode()));
        body.put("message", e.getMessage());
        return body;
    }

    @ExceptionHandler(NotLoginException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public Map<String, Object> handleNotLogin(NotLoginException e) {
        return errorBody("unauthorized", "未登录或凭证无效");
    }

    @ExceptionHandler(NotPermissionException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public Map<String, Object> handleNoPermission(NotPermissionException e) {
        return errorBody("forbidden", "权限不足");
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, Object> handleValidation(MethodArgumentNotValidException e) {
        Map<String, String> fields = e.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(
                        f -> f.getField(),
                        f -> f.getDefaultMessage() != null ? f.getDefaultMessage() : "invalid",
                        (a, b) -> a));
        Map<String, Object> body = new HashMap<>();
        body.put("error", "validation_failed");
        body.put("message", "请求参数校验失败");
        body.put("fields", fields);
        return body;
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Map<String, Object> handleAll(Exception e) {
        log.error("未处理异常", e);
        return errorBody("internal_error", "服务端错误");
    }

    // ---- 内部工具 ----

    private Map<String, Object> errorBody(String error, String message) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", error);
        body.put("message", message);
        return body;
    }

    private String mapBizCode(int code) {
        return switch (code) {
            case 401 -> "unauthorized";
            case 403 -> "forbidden";
            case 404 -> "not_found";
            case 409 -> "conflict";
            case 413 -> "payload_too_large";
            case 415 -> "unsupported_media_type";
            case 422 -> "validation_failed";
            case 429 -> "too_many_requests";
            default -> "bad_request";
        };
    }
}
