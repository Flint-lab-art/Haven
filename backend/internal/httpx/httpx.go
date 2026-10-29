// Package httpx 提供跨领域共用的 HTTP 辅助。
//
// 依据 docs/architecture.md 5.4：统一错误响应与分页参数都放在这里，
// 所有 handler 调用同一套；错误细节不返回给客户端。
package httpx

import (
	"errors"
	"log/slog"
	"net/http"
	"regexp"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
)

var uuidPattern = regexp.MustCompile(
	`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`,
)

// IsUUID 校验外部传入的 uuid，避免把非法字符串交给 PostgreSQL 导致 500。
func IsUUID(value string) bool {
	return uuidPattern.MatchString(value)
}

// ErrorBody 是 api.md 1.4 定义的错误响应。
// fields 仅在 422 validation_failed 时出现。
type ErrorBody struct {
	Error   string            `json:"error"`
	Message string            `json:"message"`
	Fields  map[string]string `json:"fields,omitempty"`
}

// ListBody 是 api.md 1.3 规定的列表响应包裹：空列表必须是 []，不能是 null。
type ListBody struct {
	Items any `json:"items"`
	Total int `json:"total"`
}

// NewList 构造列表响应。items 为 nil 时输出空数组。
func NewList(items any, total int) ListBody {
	if items == nil {
		items = []any{}
	}
	return ListBody{Items: items, Total: total}
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

// 分页默认值（api.md 1.5）。
const (
	DefaultLimit = 20
	MaxLimit     = 100
)

// Pagination 是解析后的 limit / offset。
type Pagination struct {
	Limit  int
	Offset int
}

// Batch 封装一次分页查询。
type Batch struct {
	Pagination
	// Total 是过滤后的总数。
	Total int
}

// ParsePagination 解析 ?limit=&offset=。
//
// api.md 1.5：limit 默认 20，最大 100；offset 默认 0。
// 非法值（负数、非数字）返回错误，由调用方转成 422。
func ParsePagination(c *gin.Context) (Pagination, error) {
	p := Pagination{Limit: DefaultLimit, Offset: 0}

	if raw := c.Query("limit"); raw != "" {
		v, err := strconv.Atoi(raw)
		if err != nil || v <= 0 {
			return p, errors.New("limit 必须是正整数")
		}
		if v > MaxLimit {
			v = MaxLimit
		}
		p.Limit = v
	}

	if raw := c.Query("offset"); raw != "" {
		v, err := strconv.Atoi(raw)
		if err != nil || v < 0 {
			return p, errors.New("offset 必须是非负整数")
		}
		p.Offset = v
	}

	return p, nil
}

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

// Fail 按领域错误映射成 api.md 1.4 的响应。
//
// 只映射认证包已定义的业务错误；未识别的错误一律 500。
func Fail(c *gin.Context, err error) {
	switch {
	case errors.Is(err, auth.ErrInvalidCredentials):
		FailUnauthorizedWith(c, auth.ErrInvalidCredentials.Error())
	case errors.Is(err, auth.ErrPendingExpired):
		FailUnauthorizedWith(c, auth.ErrPendingExpired.Error())
	case errors.Is(err, auth.ErrBadTotp):
		FailUnauthorizedWith(c, auth.ErrBadTotp.Error())
	case errors.Is(err, auth.ErrTotpAlreadyEnabled):
		FailConflict(c, auth.ErrTotpAlreadyEnabled.Error())
	case errors.Is(err, auth.ErrTotpNotEnabled):
		FailValidation(c, map[string]string{"code": "尚未启用 TOTP"})
	case errors.Is(err, auth.ErrNotFound):
		FailNotFound(c)
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
