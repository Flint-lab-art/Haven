// Package httpx 提供跨领域共用的 HTTP 辅助。
//
// 依据 docs/architecture.md 5.4：统一错误响应构造函数放在这里，
// 所有 handler 调用同一套；错误细节不返回给客户端。
package httpx

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
)

// ErrorBody 是 api.md 1.4 定义的错误响应。
// fields 仅在 422 validation_failed 时出现。
type ErrorBody struct {
	Error   string            `json:"error"`
	Message string            `json:"message"`
	Fields  map[string]string `json:"fields,omitempty"`
}

// 错误码常量，取值见 docs/api.md 1.4。
const (
	CodeBadRequest       = "bad_request"
	CodeUnauthorized     = "unauthorized"
	CodeForbidden        = "forbidden"
	CodeNotFound         = "not_found"
	CodeConflict         = "conflict"
	CodeValidationFailed = "validation_failed"
	CodeInternal         = "internal_error"
)

// FailInternal 返回 500，细节只进日志（api.md 1.4、architecture.md 5.4）。
func FailInternal(c *gin.Context, err error) {
	if err != nil {
		slog.Error("请求处理失败", "method", c.Request.Method, "path", c.Request.URL.Path, "err", err)
	}
	c.AbortWithStatusJSON(http.StatusInternalServerError, ErrorBody{
		Error:   CodeInternal,
		Message: "服务端错误",
	})
}

// FailUnauthorized 返回 401。
func FailUnauthorized(c *gin.Context) {
	FailUnauthorizedWith(c, "未登录或凭证无效")
}

// FailUnauthorizedWith 返回 401，并带自定义 message（如“动态码错误”）。
func FailUnauthorizedWith(c *gin.Context, message string) {
	c.AbortWithStatusJSON(http.StatusUnauthorized, ErrorBody{
		Error:   CodeUnauthorized,
		Message: message,
	})
}

// FailBadRequest 返回 400（JSON 解析失败等），解析细节只进日志。
func FailBadRequest(c *gin.Context, err error) {
	if err != nil {
		slog.Debug("请求体解析失败", "method", c.Request.Method, "path", c.Request.URL.Path, "err", err)
	}
	FailBadRequestWith(c, "请求体格式错误")
}

// FailBadRequestWith 返回 400，并带自定义 message。
func FailBadRequestWith(c *gin.Context, message string) {
	c.AbortWithStatusJSON(http.StatusBadRequest, ErrorBody{
		Error:   CodeBadRequest,
		Message: message,
	})
}

// FailNotFound 返回 404。
func FailNotFound(c *gin.Context) {
	c.AbortWithStatusJSON(http.StatusNotFound, ErrorBody{
		Error:   CodeNotFound,
		Message: "资源不存在",
	})
}

// FailConflict 返回 409。
func FailConflict(c *gin.Context, message string) {
	c.AbortWithStatusJSON(http.StatusConflict, ErrorBody{
		Error:   CodeConflict,
		Message: message,
	})
}

// FailUnprocessable 返回 422，但不带 fields（语义化校验失败）。
func FailUnprocessable(c *gin.Context, message string) {
	c.AbortWithStatusJSON(http.StatusUnprocessableEntity, ErrorBody{
		Error:   CodeValidationFailed,
		Message: message,
	})
}

// FailForbidden 返回 403。
func FailForbidden(c *gin.Context) {
	c.AbortWithStatusJSON(http.StatusForbidden, ErrorBody{
		Error:   CodeForbidden,
		Message: "权限不足",
	})
}

// FailValidation 返回 422，并带 fields。
func FailValidation(c *gin.Context, fields map[string]string) {
	c.AbortWithStatusJSON(http.StatusUnprocessableEntity, ErrorBody{
		Error:   CodeValidationFailed,
		Message: "字段校验失败",
		Fields:  fields,
	})
}

// Fail 按领域错误映射成 api.md 1.4 的响应。
//
// 只映射认证包已定义的业务错误；未识别的错误一律 500。
func Fail(c *gin.Context, err error) {
	switch {
	case errors.Is(err, auth.ErrInvalidCredentials):
		c.AbortWithStatusJSON(http.StatusUnauthorized, ErrorBody{
			Error:   CodeUnauthorized,
			Message: auth.ErrInvalidCredentials.Error(),
		})
	case errors.Is(err, auth.ErrPendingExpired):
		c.AbortWithStatusJSON(http.StatusUnauthorized, ErrorBody{
			Error:   CodeUnauthorized,
			Message: auth.ErrPendingExpired.Error(),
		})
	case errors.Is(err, auth.ErrBadTotp):
		c.AbortWithStatusJSON(http.StatusUnauthorized, ErrorBody{
			Error:   CodeUnauthorized,
			Message: auth.ErrBadTotp.Error(),
		})
	case errors.Is(err, auth.ErrTotpAlreadyEnabled):
		c.AbortWithStatusJSON(http.StatusConflict, ErrorBody{
			Error:   CodeConflict,
			Message: auth.ErrTotpAlreadyEnabled.Error(),
		})
	case errors.Is(err, auth.ErrTotpNotEnabled):
		FailValidation(c, map[string]string{"code": "尚未启用 TOTP"})
	case errors.Is(err, auth.ErrNotFound):
		c.AbortWithStatusJSON(http.StatusNotFound, ErrorBody{
			Error:   CodeNotFound,
			Message: "资源不存在",
		})
	default:
		FailInternal(c, err)
	}
}

// InstallAuthErrorHandlers 把统一错误响应注入 auth 包，
// 使鉴权中间件不必依赖 httpx（避免包循环）。
func InstallAuthErrorHandlers() {
	auth.SetErrorHandlers(
		func(c *gin.Context, _ error) { FailUnauthorized(c) },
		func(c *gin.Context, _ error) { FailForbidden(c) },
		FailInternal,
	)
}
