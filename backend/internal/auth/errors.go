package auth

import (
	"github.com/gin-gonic/gin"
)

// SetErrorCallbacks 注入统一错误响应。
//
// auth 包不直接依赖 internal/httpx（httpx 反过来要引用 auth 的错误值），
// 由 main 在启动时调用一次完成接线。任一回调为 nil 时保留默认实现。
func SetErrorCallbacks(
	badRequest func(c *gin.Context, err error),
	validationFailed func(c *gin.Context, fields map[string]string),
	internalError func(c *gin.Context, err error),
	notFound func(c *gin.Context),
	conflict func(c *gin.Context, message string),
	unauthorized func(c *gin.Context, message string),
	unprocessable func(c *gin.Context, message string),
) {
	if badRequest != nil {
		BadRequest = badRequest
	}
	if validationFailed != nil {
		ValidationFailed = validationFailed
	}
	if internalError != nil {
		InternalError = internalError
	}
	if notFound != nil {
		NotFound = notFound
	}
	if conflict != nil {
		Conflict = conflict
	}
	if unauthorized != nil {
		Unauthorized = unauthorized
	}
	if unprocessable != nil {
		Unprocessable = unprocessable
	}
}

// 默认实现：返回 api.md 1.4 的最小错误体。main 会用 httpx 覆盖成完整实现。

var (
	BadRequest       = defaultErrorCallback(400, "bad_request", "请求体格式错误")
	ValidationFailed = func(c *gin.Context, fields map[string]string) {
		c.AbortWithStatusJSON(422, gin.H{"error": "validation_failed", "message": "字段校验失败", "fields": fields})
	}
	InternalError = defaultErrorCallback(500, "internal_error", "服务端错误")
	NotFound      = func(c *gin.Context) {
		c.AbortWithStatusJSON(404, gin.H{"error": "not_found", "message": "资源不存在"})
	}
	Conflict = func(c *gin.Context, message string) {
		c.AbortWithStatusJSON(409, gin.H{"error": "conflict", "message": message})
	}
	Unauthorized = func(c *gin.Context, message string) {
		c.AbortWithStatusJSON(401, gin.H{"error": "unauthorized", "message": message})
	}
	Unprocessable = func(c *gin.Context, message string) {
		c.AbortWithStatusJSON(422, gin.H{"error": "validation_failed", "message": message})
	}
)

func defaultErrorCallback(status int, code, message string) func(*gin.Context, error) {
	return func(c *gin.Context, _ error) {
		c.AbortWithStatusJSON(status, gin.H{"error": code, "message": message})
	}
}
