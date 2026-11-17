package com.haven.backend.exception;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.haven.backend.dto.ApiError;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.mock.http.MockHttpInputMessage;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/**
 * 错误契约测试：所有异常都必须映射到正确的状态码，并且响应体是 {@code {error,message}}。
 */
class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    @DisplayName("BizException 422 返回 422 而不是 400")
    void validationReturns422() {
        var response = handler.handleBiz(BizException.validation("标题不能为空"));

        assertEquals(HttpStatus.UNPROCESSABLE_ENTITY, response.getStatusCode());
        assertEquals("validation_failed", response.getBody().error());
        assertEquals("标题不能为空", response.getBody().message());
    }

    @Test
    @DisplayName("413 映射到 payload_too_large")
    void payloadTooLargeReturns413() {
        var response = handler.handleBiz(new BizException(413, "文件超过 10 MiB"));

        assertEquals(HttpStatus.PAYLOAD_TOO_LARGE, response.getStatusCode());
        assertEquals("payload_too_large", response.getBody().error());
    }

    @Test
    @DisplayName("缺少请求参数返回 400 而不是 500")
    void missingParameterReturns400() {
        ApiError body = handler.handleMissingParameter(new MissingServletRequestParameterException("limit", "int"));

        assertEquals("bad_request", body.error());
        assertEquals("缺少必需参数: limit", body.message());
    }

    @Test
    @DisplayName("参数类型不匹配返回 400 而不是 500")
    void typeMismatchReturns400() {
        var ex = new MethodArgumentTypeMismatchException(
                "abc", Integer.class, "limit", null, new NumberFormatException("abc"));

        ApiError body = handler.handleTypeMismatch(ex);

        assertEquals("bad_request", body.error());
    }

    @Test
    @DisplayName("请求体无法解析返回 400 而不是 500")
    void unreadableBodyReturns400() {
        var ex = new HttpMessageNotReadableException("bad json", new MockHttpInputMessage(new byte[0]));

        ApiError body = handler.handleNotReadable(ex);

        assertEquals("bad_request", body.error());
    }

    @Test
    @DisplayName("不支持的 Content-Type 返回 415")
    void unsupportedMediaTypeReturns415() {
        ApiError body = handler.handleMediaTypeNotSupported(new HttpMediaTypeNotSupportedException("text/plain"));

        assertEquals("unsupported_media_type", body.error());
    }

    @Test
    @DisplayName("非法 UUID 等 IllegalArgumentException 返回 400 而不是 500")
    void illegalArgumentReturns400() {
        ApiError body = handler.handleIllegalArgument(new IllegalArgumentException("bad uuid"));

        assertEquals("bad_request", body.error());
    }

    @Test
    @DisplayName("唯一约束冲突返回 409")
    void dataIntegrityReturns409() {
        ApiError body = handler.handleDataIntegrity(new org.springframework.dao.DuplicateKeyException("dup"));

        assertEquals("conflict", body.error());
    }

    @Test
    @DisplayName("上传超限返回 413")
    void maxUploadSizeReturns413() {
        ApiError body =
                handler.handleMaxUploadSize(new org.springframework.web.multipart.MaxUploadSizeExceededException(1024));

        assertEquals("payload_too_large", body.error());
    }

    @Test
    @DisplayName("兜底异常返回 500，且响应体统一为 {error,message}")
    void unknownExceptionReturns500() {
        ApiError body = handler.handleAll(new IllegalStateException("boom"));

        assertEquals("internal_error", body.error());
        assertEquals("服务端错误", body.message());
    }
}
