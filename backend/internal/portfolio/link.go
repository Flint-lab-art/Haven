package portfolio

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strings"
	"time"
)

// 链接标题抓取（docs/v3/api.md 第五节）。
//
// 相关链接在公开页展示标题而不是 URL，因此新增链接时后端尽力抓一次 <title>。
// 抓取失败不影响添加：标题留空，由使用者稍后手动填写。

const (
	// titleFetchTimeout 是抓取单个页面标题的超时时间。
	titleFetchTimeout = 5 * time.Second
	// titleFetchMaxBytes 是读取响应的上限，避免被超大页面拖垮。
	titleFetchMaxBytes = 256 << 10 // 256 KiB
	// titleMaxRunes 是标题的最大长度，超出截断。
	titleMaxRunes = 120
)

// titlePattern 匹配 <title>标签，兼容大小写与跨行。
var titlePattern = regexp.MustCompile(`(?is)<title[^>]*>(.*?)</title>`)

// ErrInvalidURL 链接地址不合法（422）。
var ErrInvalidURL = errors.New("链接地址不合法，需要 http(s):// 开头的完整地址")

// ValidateURL 校验并规范化链接：必须是 http/https，去掉首尾空白。
func ValidateURL(raw string) (string, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return "", ErrInvalidURL
	}

	parsed, err := url.Parse(value)
	if err != nil {
		return "", ErrInvalidURL
	}
	if parsed.Scheme != "http" && parsed.Scheme != "https" {
		return "", ErrInvalidURL
	}
	if parsed.Host == "" {
		return "", ErrInvalidURL
	}
	return parsed.String(), nil
}

// FetchTitle 尽力抓取页面标题。失败时返回空串，调用方不应因此中断保存。
func FetchTitle(ctx context.Context, rawURL string) string {
	ctx, cancel := context.WithTimeout(ctx, titleFetchTimeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
	if err != nil {
		return ""
	}
	// 有些站点对没有 UA 的请求直接拒绝
	req.Header.Set("User-Agent", "Mozilla/5.0 (compatible; Haven/1.0)")
	req.Header.Set("Accept", "text/html,application/xhtml+xml")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return ""
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, titleFetchMaxBytes))
	if err != nil {
		return ""
	}

	match := titlePattern.FindSubmatch(body)
	if len(match) < 2 {
		return ""
	}

	title := htmlUnescape(strings.TrimSpace(string(match[1])))
	// 折叠连续空白，避免标题里带换行
	title = strings.Join(strings.Fields(title), " ")
	return truncateRunes(title, titleMaxRunes)
}

// htmlUnescape 处理标题里最常见的几个实体。
//
// 不引入 html 包之外的依赖；这里覆盖 < > & " ' 与 &nbsp; 已够用。
func htmlUnescape(s string) string {
	replacer := strings.NewReplacer(
		"&lt;", "<",
		"&gt;", ">",
		"&quot;", "\"",
		"&#39;", "'",
		"&#x27;", "'",
		"&nbsp;", " ",
		"&amp;", "&",
	)
	return replacer.Replace(s)
}

// truncateRunes 按 rune 截断，避免切坏多字节字符。
func truncateRunes(s string, limit int) string {
	runes := []rune(s)
	if len(runes) <= limit {
		return s
	}
	return string(runes[:limit])
}

// hostOf 返回 URL 的主机名，用于判断展示哪种图标。
func hostOf(raw string) string {
	parsed, err := url.Parse(raw)
	if err != nil {
		return ""
	}
	return strings.TrimPrefix(strings.ToLower(parsed.Hostname()), "www.")
}

// RepoKind 按 URL 判断链接类型（docs/v3/frontend/frontend.md 第八节）。
//
//   - github.com        → "github"
//   - 配置的 Gogs 域名   → "gogs"
//   - 其他               → "link"
func (s *Service) RepoKind(raw string) string {
	host := hostOf(raw)
	if host == "" {
		return "link"
	}
	if host == "github.com" {
		return "github"
	}
	if gogs := hostOf(s.gogsBaseURL); gogs != "" && host == gogs {
		return "gogs"
	}
	return "link"
}
