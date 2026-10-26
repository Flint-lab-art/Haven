# llm-extension — LLM 抽象层预留

> 本文件回答：LLM 抽象层的接口定义、本期实现边界、未来扩展时的落点。
> 依赖：无

## 一、定位

本期**不实现任何 LLM 调用**。只定义抽象接口，为后续 RAG 检索、笔记静态翻译等扩展预留位置。接口先放在这里，防止业务代码把“以后要接 LLM”这件事忘掉，也防止届时改动侵入现有模块。

## 二、本期实现边界

- 只定义 Go interface，放在 `backend/internal/llm` 包下；
- **不实现任何 provider**（不接 OpenAI、不接 DeepSeek、不接本地模型）；
- **不引入任何 LLM SDK 依赖**；
- 不定义配置项（API key、base URL、模型名等一概不出现）；
- 不写 HTTP 接口，前端无感知。

## 三、接口定义

接口按“能力”划分，不按“模型”划分。业务层只依赖能力接口，不依赖具体 provider。

```go
package llm

import "context"

// Provider 是所有 LLM 能力的根接口。
// 本期不实现，仅定义。
type Provider interface {
    // Translate 将文本从源语言翻译为目标语言。
    // 同步调用，适用于短文本（单篇笔记正文以内）。
    Translate(ctx context.Context, req TranslateRequest) (TranslateResponse, error)

    // Embed 生成文本的向量表示，供 RAG 检索使用。
    // 单条文本生成一个向量。
    Embed(ctx context.Context, text string) ([]float32, error)
}

type TranslateRequest struct {
    Text           string // 待翻译文本
    SourceLanguage string // 源语言代码，如 "zh"、"en"；空表示自动检测
    TargetLanguage string // 目标语言代码
}

type TranslateResponse struct {
    Text string // 翻译结果
}
```

**说明**：

- `Translate` 和 `Embed` 是两个独立能力，未来可以由不同 provider 实现；
- 接口**只覆盖“输入文本 → 输出结果”**，不涉及流式、不涉及对话、不涉及 tool use——这些不是本项目当前场景需要的；
- `Provider` 是根接口，未来如需拆分（如 `Translator` / `Embedder` 两个接口），在实现第一个 provider 时再拆，现在不预先拆。

## 四、未来扩展的落点

以下内容**本期不实现**，但写在这里，标明未来改动应该落在哪，避免届时重新设计。

### 4.1 配置项

未来接入 provider 时，`architecture.md` 的配置项一节需要新增：

- `LLM_PROVIDER`：provider 名（如 `openai` / `deepseek` / `local`）；
- `LLM_API_KEY`：API 密钥（如适用）；
- `LLM_BASE_URL`：API 地址（如适用）；
- `LLM_MODEL`：模型名。

### 4.2 触发方式

- **翻译**：同步调用。用户在笔记详情页点“翻译”，后端调 `Translate`，返回结果直接展示，不落库。
- **RAG 检索**：异步任务。`Embed` 在笔记保存后异步执行，向量存储方案届时决定（pgvector 或外部存储），**本期不引入**。

### 4.3 数据出境规则

未来接入外部 LLM 时，必须明确哪些内容允许发送出去：

- 只有 **public 笔记** 允许送往外部 provider；
- private 笔记的翻译 / 嵌入只能走本地模型，或经用户显式确认后临时发送；
- 这条规则在实现第一个 provider 时写入 `conventions.md` 第四节，本文件不预先写死。

## 五、硬性约束

- 业务层**不得直接 import 任何 LLM SDK**，只能 import `backend/internal/llm`；
- 抽象层**不泄漏具体 provider 的 SDK 类型**到业务层（如 OpenAI 的 `ChatCompletionRequest` 不得出现在接口签名里）；
- 本期**不写任何实现代码**，不建 `backend/internal/llm/openai` 之类的子包。
