package search

import "testing"

// TestEscapeLike 覆盖 ILIKE 通配符转义（search.md 第四节）。
//
// 关键词里的 % 和 _ 必须转义成字面量，否则用户搜 "%" 会匹配到全部笔记。
func TestEscapeLike(t *testing.T) {
	cases := []struct {
		name string
		in   string
		want string
	}{
		{"普通中文", "编程", "%编程%"},
		{"普通英文", "go", "%go%"},
		{"空串", "", "%%"},
		{"百分号", "%", "%\\%%"},
		{"下划线", "_", "%\\_%"},
		{"反斜杠", `\`, `%\\%`},
		{"反斜杠在通配符前", `\%`, `%\\\%%`},
		{"多个通配符", "a%b_c", "%a\\%b\\_c%"},
		{"连续百分号", "%%", "%\\%\\%%"},
		{"多字节不按字节处理", "笔记_01", "%笔记\\_01%"},
		{"已含转义样式", `a\%`, `%a\\\%%`},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := escapeLike(tc.in); got != tc.want {
				t.Errorf("escapeLike(%q) = %q，期望 %q", tc.in, got, tc.want)
			}
		})
	}
}

// TestEscapeLikeAlwaysWraps 确认返回值总是被 % 包裹，调用方不需要自己拼通配符。
func TestEscapeLikeAlwaysWraps(t *testing.T) {
	for _, in := range []string{"", "a", "%", `\`} {
		got := escapeLike(in)
		if len(got) < 2 || got[0] != '%' || got[len(got)-1] != '%' {
			t.Errorf("escapeLike(%q) = %q，首尾都应是 %%", in, got)
		}
	}
}
