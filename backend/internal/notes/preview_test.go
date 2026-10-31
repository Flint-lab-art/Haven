package notes

import (
	"strings"
	"testing"
)

// TestPreview 覆盖列表正文预览的截断规则（api.md 6.1）：
// 按 rune 截断至 PreviewRuneLimit，超出以 … 结尾。
func TestPreview(t *testing.T) {
	cases := []struct {
		name string
		in   string
		want string
	}{
		{"空串", "", ""},
		{"单个字符", "a", "a"},
		{"刚好等于上限", strings.Repeat("a", PreviewRuneLimit), strings.Repeat("a", PreviewRuneLimit)},
		{"超过上限一个", strings.Repeat("a", PreviewRuneLimit+1),
			strings.Repeat("a", PreviewRuneLimit) + "…"},
		{"远超过上限", strings.Repeat("x", PreviewRuneLimit*3),
			strings.Repeat("x", PreviewRuneLimit) + "…"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := Preview(tc.in); got != tc.want {
				t.Errorf("Preview(len=%d) = %q，期望 %q", len(tc.in), got, tc.want)
			}
		})
	}
}

// TestPreviewRunesNotBytes 确认截断按 rune 计数，不按字节切分（中文每字 3 字节）。
//
// 若误用 content[:N] 会切出半个汉字，这里用中文与 Emoji 双重覆盖。
func TestPreviewRunesNotBytes(t *testing.T) {
	zh := strings.Repeat("中", PreviewRuneLimit)
	if got := Preview(zh); got != zh {
		t.Errorf("Preview 对 %d 个中文应原样返回，实际长度 %d", PreviewRuneLimit, len([]rune(got)))
	}

	zhOver := zh + "文"
	want := zh + "…"
	if got := Preview(zhOver); got != want {
		t.Errorf("Preview 超出 1 个中文应截断并加 …，实际 %q", got)
	}

	emoji := strings.Repeat("😀", PreviewRuneLimit+1)
	got := Preview(emoji)
	if n := len([]rune(got)); n != PreviewRuneLimit+1 { // 200 个 Emoji + 省略号
		t.Errorf("Emoji 截断后 rune 数应为 %d，实际 %d", PreviewRuneLimit+1, n)
	}
	if !strings.HasSuffix(got, "…") {
		t.Errorf("Emoji 截断后应以 … 结尾，实际 %q", got)
	}
}

// TestPreviewNoEllipsisAtLimit 确认恰好等于上限时不加省略号。
func TestPreviewNoEllipsisAtLimit(t *testing.T) {
	in := strings.Repeat("中", PreviewRuneLimit)
	if strings.HasSuffix(Preview(in), "…") {
		t.Errorf("长度恰好为上限时不应追加省略号")
	}
}
