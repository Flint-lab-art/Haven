package folders

import (
	"errors"
	"strings"
	"testing"
)

// TestNormalizeIcon 覆盖文件夹图标的规整规则（api.md 7.2）：
// nil / 空白 → NULL；含换行 → ErrIconInvalid；超过 MaxIconRunes → ErrIconTooLong。
func TestNormalizeIcon(t *testing.T) {
	str := func(s string) *string { return &s }

	cases := []struct {
		name    string
		in      *string
		want    string // 期望的规整结果；wantNil 为 true 时忽略
		wantNil bool
		wantErr error
	}{
		{name: "nil 保持 nil", in: nil, wantNil: true},
		{name: "空串归为零值", in: str(""), wantNil: true},
		{name: "纯空白归为零值", in: str("   "), wantNil: true},
		{name: "纯制表符归为零值", in: str("\t \t"), wantNil: true},
		{name: "单个 Emoji", in: str("📚"), want: "📚"},
		{name: "首尾空白被 trim", in: str("  📚  "), want: "📚"},
		{name: "16 rune 边界允许", in: str(strings.Repeat("a", MaxIconRunes)), want: strings.Repeat("a", MaxIconRunes)},
		{name: "17 rune 拒绝", in: str(strings.Repeat("a", MaxIconRunes+1)), wantErr: ErrIconTooLong},
		{name: "16 个 Emoji 按 rune 计允许", in: str(strings.Repeat("📚", MaxIconRunes)), want: strings.Repeat("📚", MaxIconRunes)},
		{name: "17 个 Emoji 按 rune 计拒绝", in: str(strings.Repeat("📚", MaxIconRunes+1)), wantErr: ErrIconTooLong},
		{name: "含换行拒绝", in: str("📚\n📖"), wantErr: ErrIconInvalid},
		{name: "含回车拒绝", in: str("📚\r📖"), wantErr: ErrIconInvalid},
		// 纯换行等同于空白：先 TrimSpace 成空串，按「未设置图标」处理，不报错。
		{name: "仅换行视为未设置", in: str("\n"), wantNil: true},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := normalizeIcon(tc.in)
			if tc.wantErr != nil {
				if !errors.Is(err, tc.wantErr) {
					t.Fatalf("normalizeIcon(%v) err = %v，期望 %v", ptrStr(tc.in), err, tc.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("normalizeIcon(%v) 返回意外错误: %v", ptrStr(tc.in), err)
			}
			if tc.wantNil {
				if got != nil {
					t.Errorf("normalizeIcon(%v) = %q，期望 nil", ptrStr(tc.in), *got)
				}
				return
			}
			if got == nil {
				t.Fatalf("normalizeIcon(%v) = nil，期望 %q", ptrStr(tc.in), tc.want)
			}
			if *got != tc.want {
				t.Errorf("normalizeIcon(%v) = %q，期望 %q", ptrStr(tc.in), *got, tc.want)
			}
		})
	}
}

// TestNormalizeIconTrimBeforeLength 确认先 trim 再计长度：
// 长度超限但 trim 后合法时应当通过。
func TestNormalizeIconTrimBeforeLength(t *testing.T) {
	padded := "  " + strings.Repeat("a", MaxIconRunes) + "  "
	if len([]rune(padded)) <= MaxIconRunes {
		t.Fatalf("测试数据本身不满足前置条件")
	}
	got, err := normalizeIcon(&padded)
	if err != nil {
		t.Fatalf("trim 后应合法，实际报错: %v", err)
	}
	if got == nil || *got != strings.Repeat("a", MaxIconRunes) {
		t.Errorf("应返回 trim 后的值，实际 %v", ptrStr(got))
	}
}

func ptrStr(p *string) string {
	if p == nil {
		return "nil"
	}
	return *p
}
