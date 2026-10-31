package uploads

import (
	"bytes"
	"errors"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/textproto"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

// 图片上传（docs/v4/api.md 第三节）。

// pngBytes 生成一张 1x1 的合法 PNG。
func pngBytes(t *testing.T) []byte {
	t.Helper()
	img := image.NewRGBA(image.Rect(0, 0, 1, 1))
	img.Set(0, 0, color.RGBA{R: 255, A: 255})
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		t.Fatalf("生成测试图片失败: %v", err)
	}
	return buf.Bytes()
}

func newTestService(t *testing.T) *Service {
	t.Helper()
	svc, err := NewService(t.TempDir())
	if err != nil {
		t.Fatalf("构造 Service 失败: %v", err)
	}
	return svc
}

func TestNewServiceCreatesDir(t *testing.T) {
	root := filepath.Join(t.TempDir(), "nested", "uploads")
	svc, err := NewService(root)
	if err != nil {
		t.Fatalf("NewService 应创建目录，实际报错: %v", err)
	}
	info, err := os.Stat(svc.Root())
	if err != nil || !info.IsDir() {
		t.Fatalf("目录应存在，实际 err=%v", err)
	}
}

func TestSaveWritesFile(t *testing.T) {
	svc := newTestService(t)
	data := pngBytes(t)

	res, err := svc.Save(bytes.NewReader(data), "screenshot.png", "image/png", KindIcon)
	if err != nil {
		t.Fatalf("Save 失败: %v", err)
	}

	if !strings.HasPrefix(res.URL, "/uploads/") {
		t.Errorf("URL 应以 /uploads/ 开头，实际 %q", res.URL)
	}
	if !strings.HasSuffix(res.URL, ".png") {
		t.Errorf("扩展名应由 MIME 决定为 .png，实际 %q", res.URL)
	}
	if res.Size != int64(len(data)) {
		t.Errorf("Size = %d，期望 %d", res.Size, len(data))
	}
	if res.Name != "screenshot.png" {
		t.Errorf("Name 应回显原文件名，实际 %q", res.Name)
	}
	if res.Mime != "image/png" {
		t.Errorf("Mime = %q", res.Mime)
	}

	// 磁盘上确实写了文件，且内容一致
	rel := strings.TrimPrefix(res.URL, "/uploads/")
	got, err := os.ReadFile(filepath.Join(svc.Root(), rel))
	if err != nil {
		t.Fatalf("读取落盘文件失败: %v", err)
	}
	if !bytes.Equal(got, data) {
		t.Errorf("落盘内容与上传内容不一致")
	}

	// 不留下 .part 临时文件
	entries, err := os.ReadDir(filepath.Join(svc.Root(), filepath.Dir(rel)))
	if err != nil {
		t.Fatalf("读取目录失败: %v", err)
	}
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".part") {
			t.Errorf("不应残留临时文件: %s", e.Name())
		}
	}
}

func TestSaveRejectsUnsupportedType(t *testing.T) {
	svc := newTestService(t)

	for _, mime := range []string{"image/svg+xml", "application/pdf", "text/plain", ""} {
		if _, err := svc.Save(bytes.NewReader([]byte("x")), "a.txt", mime, KindIcon); !errors.Is(err, ErrUnsupportedType) {
			t.Errorf("MIME %q 应被拒绝，实际 err=%v", mime, err)
		}
	}
}

func TestSaveRejectsEmpty(t *testing.T) {
	svc := newTestService(t)
	if _, err := svc.Save(bytes.NewReader(nil), "a.png", "image/png", KindIcon); !errors.Is(err, ErrEmptyFile) {
		t.Errorf("空文件应返回 ErrEmptyFile，实际 %v", err)
	}
}

func TestSaveRejectsTooLarge(t *testing.T) {
	svc := newTestService(t)
	big := bytes.Repeat([]byte{0}, MaxUploadBytes+1)

	if _, err := svc.Save(bytes.NewReader(big), "a.png", "image/png", KindIcon); !errors.Is(err, ErrTooLarge) {
		t.Errorf("超大文件应返回 ErrTooLarge，实际 %v", err)
	}

	// 失败时不应留下文件
	var count int
	_ = filepath.Walk(svc.Root(), func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() {
			count++
		}
		return nil
	})
	if count != 0 {
		t.Errorf("超限失败后不应留下文件，实际 %d 个", count)
	}
}

func TestSaveUniqueNames(t *testing.T) {
	svc := newTestService(t)
	data := pngBytes(t)

	seen := make(map[string]bool, 5)
	for i := 0; i < 5; i++ {
		res, err := svc.Save(bytes.NewReader(data), "same.png", "image/png", KindIcon)
		if err != nil {
			t.Fatalf("Save 失败: %v", err)
		}
		if seen[res.URL] {
			t.Fatalf("文件名重复: %s", res.URL)
		}
		seen[res.URL] = true
	}
}

// TestSaveIgnoresClientFilename 覆盖：文件名由服务端生成，客户端传的路径不能穿越目录。
func TestSaveIgnoresClientFilename(t *testing.T) {
	svc := newTestService(t)
	data := pngBytes(t)

	res, err := svc.Save(bytes.NewReader(data), "../../etc/passwd.png", "image/png", KindIcon)
	if err != nil {
		t.Fatalf("Save 失败: %v", err)
	}
	if strings.Contains(res.URL, "..") {
		t.Errorf("URL 不应包含路径穿越: %s", res.URL)
	}

	abs := filepath.Join(svc.Root(), strings.TrimPrefix(res.URL, "/uploads/"))
	if rel, err := filepath.Rel(svc.Root(), abs); err != nil || strings.HasPrefix(rel, "..") {
		t.Errorf("文件应落在上传目录内，实际 %s", abs)
	}
}

// TestCreateHandler 覆盖 HTTP 层的状态码映射。
func TestCreateHandler(t *testing.T) {
	cases := []struct {
		name   string
		mime   string
		body   []byte
		status int
	}{
		{"正常 PNG", "image/png", pngBytes(t), http.StatusCreated},
		{"SVG 拒绝", "image/svg+xml", []byte("<svg/>"), http.StatusUnsupportedMediaType},
		{"空文件", "image/png", nil, http.StatusUnprocessableEntity},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			svc := newTestService(t)
			h := NewHandler(svc)

			rec := doUpload(t, h, "file", "a.png", tc.mime, tc.body)
			if rec.Code != tc.status {
				t.Errorf("状态码 = %d，期望 %d：%s", rec.Code, tc.status, rec.Body.String())
			}
		})
	}
}

func TestCreateHandlerMissingField(t *testing.T) {
	h := NewHandler(newTestService(t))
	rec := doUpload(t, h, "wrong", "a.png", "image/png", pngBytes(t))
	if rec.Code != http.StatusBadRequest {
		t.Errorf("缺少 file 字段应 400，实际 %d", rec.Code)
	}
}

// doUpload 构造一个 multipart 请求，经 gin 路由调用 handler。
func doUpload(t *testing.T, h *Handler, field, filename, mime string, body []byte) *httptest.ResponseRecorder {
	t.Helper()

	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	hdr := make(textproto.MIMEHeader)
	hdr.Set("Content-Disposition", fmt.Sprintf(`form-data; name="%s"; filename="%s"`, field, filename))
	hdr.Set("Content-Type", mime)
	part, err := mw.CreatePart(hdr)
	if err != nil {
		t.Fatalf("构造 multipart 失败: %v", err)
	}
	if _, err := part.Write(body); err != nil {
		t.Fatalf("写入 multipart 失败: %v", err)
	}
	if err := mw.Close(); err != nil {
		t.Fatalf("关闭 multipart 失败: %v", err)
	}

	// 用真实路由跑一遍：鉴权中间件以外的行为与生产一致
	gin.SetMode(gin.TestMode)
	r := gin.New()
	write := r.Group("/api/uploads")
	write.POST("", h.Create)

	req := httptest.NewRequest(http.MethodPost, "/api/uploads", &buf)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)
	return rec
}

// TestList 覆盖列出已上传图片（docs/v4/api.md 4.1）。
func TestList(t *testing.T) {
	svc := newTestService(t)
	data := pngBytes(t)

	// 目录为空时返回空列表，而不是 nil
	files, total, err := svc.List(0)
	if err != nil {
		t.Fatalf("List 失败: %v", err)
	}
	if total != 0 || len(files) != 0 {
		t.Errorf("空目录应返回 0 条，实际 total=%d len=%d", total, len(files))
	}

	// 上传三张
	for i := 0; i < 3; i++ {
		if _, err := svc.Save(bytes.NewReader(data), "a.png", "image/png", KindIcon); err != nil {
			t.Fatalf("Save 失败: %v", err)
		}
	}

	files, total, err = svc.List(0)
	if err != nil {
		t.Fatalf("List 失败: %v", err)
	}
	if total != 3 || len(files) != 3 {
		t.Fatalf("应返回 3 条，实际 total=%d len=%d", total, len(files))
	}
	for _, f := range files {
		if !strings.HasPrefix(f.URL, "/uploads/") {
			t.Errorf("URL 应以 /uploads/ 开头: %s", f.URL)
		}
		if f.Size <= 0 {
			t.Errorf("Size 应大于 0: %d", f.Size)
		}
		if f.CreatedAt.IsZero() {
			t.Errorf("CreatedAt 不应为零值")
		}
	}
}

// TestListIgnoresNonImages 覆盖：只列出允许的扩展名，忽略临时文件。
func TestListIgnoresNonImages(t *testing.T) {
	svc := newTestService(t)

	// 手动塞入不该被列出的文件
	dir := filepath.Join(svc.Root(), "icons", "2026", "01")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"a.png.part", "b.txt", "c.svg", "d.png"} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte("x"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	files, total, err := svc.List(0)
	if err != nil {
		t.Fatalf("List 失败: %v", err)
	}
	if total != 1 || len(files) != 1 {
		t.Fatalf("只应列出 d.png，实际 total=%d: %v", total, files)
	}
	if !strings.HasSuffix(files[0].URL, "d.png") {
		t.Errorf("URL 不对: %s", files[0].URL)
	}
}

// TestListLimit 覆盖 limit 截断。
func TestListLimit(t *testing.T) {
	svc := newTestService(t)
	data := pngBytes(t)
	for i := 0; i < 5; i++ {
		if _, err := svc.Save(bytes.NewReader(data), "a.png", "image/png", KindIcon); err != nil {
			t.Fatal(err)
		}
	}

	files, total, err := svc.List(2)
	if err != nil {
		t.Fatalf("List 失败: %v", err)
	}
	if total != 5 {
		t.Errorf("total 应是全部数量 5，实际 %d", total)
	}
	if len(files) != 2 {
		t.Errorf("limit=2 时应只返回 2 条，实际 %d", len(files))
	}
}

// TestSaveSplitsByKind 覆盖：笔记插图与文件夹图标落在不同子目录（docs/v4/api.md 3.1）。
func TestSaveSplitsByKind(t *testing.T) {
	svc := newTestService(t)
	data := pngBytes(t)

	noteRes, err := svc.Save(bytes.NewReader(data), "a.png", "image/png", KindNote)
	if err != nil {
		t.Fatalf("Save(note) 失败: %v", err)
	}
	iconRes, err := svc.Save(bytes.NewReader(data), "b.png", "image/png", KindIcon)
	if err != nil {
		t.Fatalf("Save(icon) 失败: %v", err)
	}

	if !strings.HasPrefix(noteRes.URL, "/uploads/notes/") {
		t.Errorf("笔记插图应落在 notes/ 下，实际 %s", noteRes.URL)
	}
	if !strings.HasPrefix(iconRes.URL, "/uploads/icons/") {
		t.Errorf("图标应落在 icons/ 下，实际 %s", iconRes.URL)
	}

	// 列表只列 icons/
	files, total, err := svc.List(0)
	if err != nil {
		t.Fatalf("List 失败: %v", err)
	}
	if total != 1 || len(files) != 1 {
		t.Fatalf("应只列出 1 张图标，实际 total=%d len=%d", total, len(files))
	}
	if files[0].URL != iconRes.URL {
		t.Errorf("列出的应是图标 %s，实际 %s", iconRes.URL, files[0].URL)
	}
}

// TestSaveDefaultsToNote 覆盖：不传 kind 时按笔记插图处理。
func TestSaveDefaultsToNote(t *testing.T) {
	svc := newTestService(t)
	res, err := svc.Save(bytes.NewReader(pngBytes(t)), "a.png", "image/png", "")
	if err != nil {
		t.Fatalf("Save 失败: %v", err)
	}
	if !strings.HasPrefix(res.URL, "/uploads/notes/") {
		t.Errorf("默认应落在 notes/ 下，实际 %s", res.URL)
	}
}

// TestSaveRejectsInvalidKind 覆盖：非法用途返回 ErrInvalidKind。
func TestSaveRejectsInvalidKind(t *testing.T) {
	svc := newTestService(t)
	if _, err := svc.Save(bytes.NewReader(pngBytes(t)), "a.png", "image/png", "avatar"); !errors.Is(err, ErrInvalidKind) {
		t.Errorf("非法 kind 应返回 ErrInvalidKind，实际 %v", err)
	}
}
