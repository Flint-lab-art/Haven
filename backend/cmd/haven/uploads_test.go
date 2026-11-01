package main

import (
	"bytes"
	"image"
	"image/color"
	"image/png"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/textproto"
	"strings"
	"testing"
)

// TestE2EUploadAndServe 端到端：上传 → 返回 URL → 通过 /uploads 访问到同一份内容。
func TestE2EUploadAndServe(t *testing.T) {
	e, cookie := newUserEnv(t)

	// 造一张 PNG
	img := image.NewRGBA(image.Rect(0, 0, 2, 2))
	img.Set(0, 0, color.RGBA{B: 255, A: 255})
	var pngBuf bytes.Buffer
	if err := png.Encode(&pngBuf, img); err != nil {
		t.Fatal(err)
	}

	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	hdr := make(textproto.MIMEHeader)
	hdr.Set("Content-Disposition", `form-data; name="file"; filename="pic.png"`)
	hdr.Set("Content-Type", "image/png")
	part, _ := mw.CreatePart(hdr)
	part.Write(pngBuf.Bytes())
	mw.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/uploads", &body)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.AddCookie(cookie)
	rec := httptest.NewRecorder()
	e.router.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("上传应 201，实际 %d: %s", rec.Code, rec.Body.String())
	}
	url := jsonBody(t, rec.Body.Bytes())["url"].(string)
	if !strings.HasPrefix(url, "/uploads/") {
		t.Fatalf("URL 不对: %s", url)
	}

	// 匿名访问该 URL
	w := e.do(http.MethodGet, url, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("访问上传文件应 200，实际 %d", w.Code)
	}
	if w.Body.Len() != pngBuf.Len() {
		t.Errorf("返回内容长度 %d，期望 %d", w.Body.Len(), pngBuf.Len())
	}
	if cc := w.Header().Get("Cache-Control"); !strings.Contains(cc, "immutable") {
		t.Errorf("应带长缓存，实际 %q", cc)
	}

	// 不存在的文件：404，且不能是 HTML
	w = e.do(http.MethodGet, "/uploads/2026/01/nope.png", nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("不存在应 404，实际 %d", w.Code)
	}
	if strings.Contains(w.Body.String(), "<html") {
		t.Errorf("不应回退到 SPA：%s", w.Body.String())
	}

	_ = url
}

// TestFolderIconAcceptsUploadPath 覆盖 docs/v4/backend/data-model.md 第一节：
// folders.icon 放宽到 256 rune，可以存上传图片的相对路径。
func TestFolderIconAcceptsUploadPath(t *testing.T) {
	e, cookie := newUserEnv(t)
	inboxID := createInboxFolder(t, e)

	w := e.do(http.MethodPost, "/api/folders", map[string]any{"name": "带图标的目录"}, cookie)
	if w.Code != http.StatusCreated {
		t.Fatalf("创建文件夹失败: %d: %s", w.Code, w.Body.String())
	}
	folderID := jsonBody(t, w.Body.Bytes())["id"].(string)
	_ = inboxID

	// 上传一张图，把返回的 URL 直接当成 icon
	iconURL := uploadPNG(t, e, cookie)

	w = e.do(http.MethodPatch, "/api/folders/"+folderID, map[string]any{"icon": iconURL}, cookie)
	if w.Code != http.StatusOK {
		t.Fatalf("用上传路径做图标应 200，实际 %d: %s", w.Code, w.Body.String())
	}
	if got := jsonBody(t, w.Body.Bytes())["icon"]; got != iconURL {
		t.Errorf("icon 应保存为 %q，实际 %v", iconURL, got)
	}

	// 仍然拒绝超长内容（>256 rune）
	long := "/" + strings.Repeat("a", 300)
	if w := e.do(http.MethodPatch, "/api/folders/"+folderID, map[string]any{"icon": long}, cookie); w.Code != http.StatusUnprocessableEntity {
		t.Errorf("超过 256 rune 应 422，实际 %d", w.Code)
	}

	// Emoji 仍然可用（向后兼容）
	if w := e.do(http.MethodPatch, "/api/folders/"+folderID, map[string]any{"icon": "📚"}, cookie); w.Code != http.StatusOK {
		t.Errorf("Emoji 图标应仍然可用，实际 %d", w.Code)
	}
}

// uploadPNG 上传一张 1x1 PNG，返回 URL。
func uploadPNG(t *testing.T, e *testEnv, cookie *http.Cookie) string {
	t.Helper()

	img := image.NewRGBA(image.Rect(0, 0, 1, 1))
	img.Set(0, 0, color.RGBA{G: 255, A: 255})
	var pngBuf bytes.Buffer
	if err := png.Encode(&pngBuf, img); err != nil {
		t.Fatalf("生成图片失败: %v", err)
	}

	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	hdr := make(textproto.MIMEHeader)
	hdr.Set("Content-Disposition", `form-data; name="file"; filename="icon.png"`)
	hdr.Set("Content-Type", "image/png")
	part, _ := mw.CreatePart(hdr)
	_, _ = part.Write(pngBuf.Bytes())
	_ = mw.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/uploads", &body)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.AddCookie(cookie)
	rec := httptest.NewRecorder()
	e.router.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("上传失败: %d: %s", rec.Code, rec.Body.String())
	}
	return jsonBody(t, rec.Body.Bytes())["url"].(string)
}
