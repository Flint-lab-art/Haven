package folders

import "testing"

// TestMaxNameRunes 锁定 api.md 7.2 / data-model.md 第九节规则 3 约定的长度上限。
func TestMaxNameRunes(t *testing.T) {
	if MaxNameRunes != 32 {
		t.Fatalf("MaxNameRunes = %d，文档约定为 32", MaxNameRunes)
	}
	// v4 起放宽到 256：icon 可以存上传图片的相对路径（docs/v4/backend/data-model.md 第一节）
	if MaxIconRunes != 256 {
		t.Fatalf("MaxIconRunes = %d，文档约定为 256", MaxIconRunes)
	}
}
