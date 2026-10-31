// Package llm 是 LLM 抽象层的接口定义。
//
// 本期（第一版）只定义接口，不实现任何 provider、不引入任何 LLM SDK 依赖、
// 不定义配置项、不暴露 HTTP 接口。业务层暂时没有任何地方 import 本包。
//
// 约束见 docs/backend/llm-extension.md 第三节与第五节：
//   - 业务层只能 import 本包，不得直接 import 具体模型 SDK；
//   - 接口签名不得出现 provider SDK 类型；
//   - 不建 openai / deepseek 之类的子包。
package llm

import "context"

// Provider 是所有 LLM 能力的根接口。本期不实现，仅定义。
type Provider interface {
	// Translate 将文本从源语言翻译为目标语言。
	// 同步调用，适用于短文本（单篇笔记正文以内）。
	Translate(ctx context.Context, req TranslateRequest) (TranslateResponse, error)

	// Embed 生成文本的向量表示，供 RAG 检索使用。
	// 单条文本生成一个向量。
	Embed(ctx context.Context, text string) ([]float32, error)
}

// TranslateRequest 是一次翻译请求。
type TranslateRequest struct {
	Text           string // 待翻译文本
	SourceLanguage string // 源语言代码，如 "zh"、"en"；空表示自动检测
	TargetLanguage string // 目标语言代码
}

// TranslateResponse 是一次翻译结果。
type TranslateResponse struct {
	Text string // 翻译结果
}
