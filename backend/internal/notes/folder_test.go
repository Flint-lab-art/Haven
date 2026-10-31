package notes

import "testing"

// TestSameFolder 覆盖「是否真的移动了文件夹」的判定（api.md 6.4）。
//
// 该判定决定 PATCH 是否把 sort_order 重置为 0，判错会让编辑器每次保存都重置目录内排序。
func TestSameFolder(t *testing.T) {
	str := func(s string) *string { return &s }
	a, b := "folder-a", "folder-b"

	cases := []struct {
		name string
		a, b *string
		want bool
	}{
		{"两个 nil（都无归属）", nil, nil, true},
		{"nil 与值", nil, str(a), false},
		{"值与 nil", str(a), nil, false},
		{"相同值（不同指针）", str(a), str(a), true},
		{"不同值", str(a), str(b), false},
		{"空串与 nil", str(""), nil, false},
		{"两个空串", str(""), str(""), true},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := sameFolder(tc.a, tc.b); got != tc.want {
				t.Errorf("sameFolder(%v, %v) = %v，期望 %v", fmtPtr(tc.a), fmtPtr(tc.b), got, tc.want)
			}
		})
	}
}

// TestSameFolderSamePointer 确认同一指针也不会因为指针相等而误判。
func TestSameFolderSamePointer(t *testing.T) {
	p := "folder-a"
	if !sameFolder(&p, &p) {
		t.Errorf("同一指针应判定为相同")
	}
}

func fmtPtr(p *string) string {
	if p == nil {
		return "nil"
	}
	return *p
}
