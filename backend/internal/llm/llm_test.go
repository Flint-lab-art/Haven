package llm

import "context"

// fakeProvider 只在测试里存在，用来确认接口签名可被实现。
// 生产代码本期不允许有任何 provider 实现（llm-extension.md 第二节）。
type fakeProvider struct{}

func (fakeProvider) Translate(_ context.Context, req TranslateRequest) (TranslateResponse, error) {
	return TranslateResponse{Text: req.Text}, nil
}

func (fakeProvider) Embed(_ context.Context, text string) ([]float32, error) {
	return []float32{float32(len(text))}, nil
}

var _ Provider = fakeProvider{}
