// Package uploads 实现图片上传与静态托管（docs/v4/api.md）。
//
// 图片存磁盘，数据库只存相对 URL：文件不是真值源，`/uploads/...` 这段路径才是。
// 只接受 png / jpeg / gif / webp，拒绝 SVG（可以带脚本，同域托管有 XSS 风险）。
package uploads

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/auth"
	"github.com/kairo/haven/internal/httpx"
)

// MaxUploadBytes 是单个文件的大小上限（docs/v4/conventions.md 第一节第 6 条）。
const MaxUploadBytes = 10 << 20 // 10 MiB

// 领域错误，由 handler 映射成状态码。
var (
	// ErrEmptyFile 上传的文件为空（422）。
	ErrEmptyFile = errors.New("文件为空")
	// ErrTooLarge 超过大小上限（413）。
	ErrTooLarge = errors.New("文件超过 10 MiB")
	// ErrUnsupportedType 类型不在允许列表（415）。
	ErrUnsupportedType = errors.New("只支持 png / jpeg / gif / webp 图片")
	// ErrInvalidKind 用途参数不合法（422）。
	ErrInvalidKind = errors.New("kind 只能是 note 或 icon")
)

// 上传用途：决定文件落在哪个子目录（docs/v4/api.md 3.1）。
const (
	// KindNote 是笔记正文里的插图，存到 notes/ 下。
	KindNote = "note"
	// KindIcon 是文件夹图标，存到 icons/ 下。
	KindIcon = "icon"
)

// kindDirs 把用途映射到子目录名。
var kindDirs = map[string]string{
	KindNote: "notes",
	KindIcon: "icons",
}

// normalizeKind 校验用途，空值按笔记插图处理。
func normalizeKind(kind string) (string, error) {
	if kind == "" {
		return KindNote, nil
	}
	if _, ok := kindDirs[kind]; !ok {
		return "", ErrInvalidKind
	}
	return kind, nil
}

// allowedTypes 把 MIME 映射到保存用的扩展名。
//
// 扩展名由服务端按 MIME 决定，不采信客户端文件名（docs/v4/api.md 3.1）。
var allowedTypes = map[string]string{
	"image/png":  ".png",
	"image/jpeg": ".jpg",
	"image/gif":  ".gif",
	"image/webp": ".webp",
}

// Service 负责把上传的文件落到磁盘。
type Service struct {
	root string
	now  func() time.Time
}

// NewService 构造 Service，并确保根目录存在。
//
// 目录创建失败直接返回错误，由调用方拒绝启动——静默降级会让上传在运行时才失败。
func NewService(root string) (*Service, error) {
	abs, err := filepath.Abs(root)
	if err != nil {
		return nil, fmt.Errorf("解析上传目录失败: %w", err)
	}
	if err := os.MkdirAll(abs, 0o755); err != nil {
		return nil, fmt.Errorf("创建上传目录 %s 失败: %w", abs, err)
	}
	return &Service{root: abs, now: time.Now}, nil
}

// Root 返回上传目录的绝对路径，供静态托管使用。
func (s *Service) Root() string { return s.root }

// Result 是一次上传的结果（docs/v4/api.md 3.1）。
type Result struct {
	URL  string `json:"url"`
	Name string `json:"name"`
	Size int64  `json:"size"`
	Mime string `json:"mime"`
}

// Save 把 r 中的图片写入磁盘，返回可放进 Markdown 的相对 URL。
//
// kind 决定落在 notes/ 还是 icons/ 下（docs/v4/api.md 3.1）；
// originalName 只用于回显，不参与存储路径。
func (s *Service) Save(r io.Reader, originalName, mime, kind string) (Result, error) {
	ext, ok := allowedTypes[mime]
	if !ok {
		return Result{}, ErrUnsupportedType
	}

	kind, err := normalizeKind(kind)
	if err != nil {
		return Result{}, err
	}

	now := s.now()
	// 按 用途/年/月 分目录：笔记插图与图标互不干扰，也避免单目录堆积过多文件
	dir := filepath.Join(
		kindDirs[kind],
		fmt.Sprintf("%04d", now.Year()),
		fmt.Sprintf("%02d", int(now.Month())),
	)
	if err := os.MkdirAll(filepath.Join(s.root, dir), 0o755); err != nil {
		return Result{}, fmt.Errorf("创建上传子目录失败: %w", err)
	}

	name, err := randomName(ext)
	if err != nil {
		return Result{}, err
	}

	// 先写临时文件再改名：中途失败不会留下半个文件被静态托管读到
	full := filepath.Join(s.root, dir, name)
	tmp := full + ".part"

	f, err := os.OpenFile(tmp, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o644)
	if err != nil {
		return Result{}, fmt.Errorf("创建上传文件失败: %w", err)
	}

	written, copyErr := io.Copy(f, io.LimitReader(r, MaxUploadBytes+1))
	closeErr := f.Close()
	if copyErr != nil {
		os.Remove(tmp)
		return Result{}, fmt.Errorf("写入上传文件失败: %w", copyErr)
	}
	if closeErr != nil {
		os.Remove(tmp)
		return Result{}, fmt.Errorf("关闭上传文件失败: %w", closeErr)
	}
	if written > MaxUploadBytes {
		os.Remove(tmp)
		return Result{}, ErrTooLarge
	}
	if written == 0 {
		os.Remove(tmp)
		return Result{}, ErrEmptyFile
	}

	if err := os.Rename(tmp, full); err != nil {
		os.Remove(tmp)
		return Result{}, fmt.Errorf("保存上传文件失败: %w", err)
	}

	return Result{
		URL:  "/uploads/" + filepath.ToSlash(filepath.Join(dir, name)),
		Name: originalName,
		Size: written,
		Mime: mime,
	}, nil
}

// randomName 生成 16 字节随机十六进制文件名。
//
// 文件名由服务端生成，不接受客户端提供，避免路径穿越（docs/v4/conventions.md 第一节第 3 条）。
func randomName(ext string) (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("生成文件名失败: %w", err)
	}
	return hex.EncodeToString(buf) + ext, nil
}

// File 是已上传图片的摘要（docs/v4/api.md 4.1）。
type File struct {
	URL       string    `json:"url"`
	Size      int64     `json:"size"`
	CreatedAt time.Time `json:"created_at"`
}

// allowedExts 是允许列出的扩展名，与 allowedTypes 的取值一致。
var allowedExts = map[string]bool{
	".png":  true,
	".jpg":  true,
	".gif":  true,
	".webp": true,
}

// List 返回 icons/ 下的图片，按修改时间倒序（最近上传的在前）。
//
// 只列图标：笔记正文的插图不进图标选择列表（docs/v4/api.md 4.1）。
// limit <= 0 时用默认值，超过上限会被截断。
func (s *Service) List(limit int) ([]File, int, error) {
	if limit <= 0 {
		limit = 60
	}
	if limit > 200 {
		limit = 200
	}

	iconRoot := filepath.Join(s.root, kindDirs[KindIcon])
	// 还没上传过图标时目录不存在，直接返回空列表
	if _, err := os.Stat(iconRoot); errors.Is(err, os.ErrNotExist) {
		return []File{}, 0, nil
	}

	var all []File
	err := filepath.WalkDir(iconRoot, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			// 单个子目录读不到不影响其它文件
			return nil
		}
		if d.IsDir() {
			return nil
		}
		ext := strings.ToLower(filepath.Ext(d.Name()))
		if !allowedExts[ext] {
			return nil
		}
		info, err := d.Info()
		if err != nil {
			return nil
		}
		rel, err := filepath.Rel(s.root, path)
		if err != nil {
			return nil
		}
		all = append(all, File{
			URL:       "/uploads/" + filepath.ToSlash(rel),
			Size:      info.Size(),
			CreatedAt: info.ModTime(),
		})
		return nil
	})
	if err != nil {
		return nil, 0, fmt.Errorf("扫描上传目录失败: %w", err)
	}

	// 最近上传的在前；同一时间的按路径排，保证顺序稳定
	sort.Slice(all, func(i, j int) bool {
		if !all[i].CreatedAt.Equal(all[j].CreatedAt) {
			return all[i].CreatedAt.After(all[j].CreatedAt)
		}
		return all[i].URL < all[j].URL
	})

	total := len(all)
	if total > limit {
		all = all[:limit]
	}
	return all, total, nil
}

// Handler 承载上传接口与静态托管。
type Handler struct {
	svc *Service
}

// NewHandler 构造 Handler。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// Create 实现 POST /api/uploads（docs/v4/api.md 3.1）。
func (h *Handler) Create(c *gin.Context) {
	// 请求体上限比文件上限略大，留出 multipart 头部的开销
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, MaxUploadBytes+1<<20)

	header, err := c.FormFile("file")
	if err != nil {
		if strings.Contains(err.Error(), "request body too large") {
			httpx.FailTooLarge(c, ErrTooLarge.Error())
			return
		}
		httpx.FailBadRequest(c, fmt.Errorf("缺少 file 字段"))
		return
	}

	f, err := header.Open()
	if err != nil {
		httpx.FailBadRequest(c, fmt.Errorf("读取上传文件失败"))
		return
	}
	defer f.Close()

	res, err := h.svc.Save(f, header.Filename, header.Header.Get("Content-Type"), c.Query("kind"))
	switch {
	case err == nil:
		c.JSON(http.StatusCreated, res)
	case errors.Is(err, ErrTooLarge):
		httpx.FailTooLarge(c, err.Error())
	case errors.Is(err, ErrUnsupportedType):
		httpx.FailUnsupportedMedia(c, err.Error())
	case errors.Is(err, ErrEmptyFile):
		httpx.FailValidation(c, map[string]string{"file": err.Error()})
	case errors.Is(err, ErrInvalidKind):
		httpx.FailValidation(c, map[string]string{"kind": err.Error()})
	default:
		httpx.FailInternal(c, err)
	}
}

// List 实现 GET /api/uploads（docs/v4/api.md 4.1）。
func (h *Handler) List(c *gin.Context) {
	page, err := httpx.ParsePagination(c)
	if err != nil {
		httpx.FailValidation(c, map[string]string{"limit": err.Error()})
		return
	}

	files, total, err := h.svc.List(page.Limit)
	if err != nil {
		httpx.FailInternal(c, err)
		return
	}
	c.JSON(http.StatusOK, httpx.NewList(files, total))
}

// RegisterRoutes 挂载上传接口。
//
// 静态托管在 router 里单独处理：它要匿名可访问，且不存在 /api 前缀。
func RegisterRoutes(r gin.IRouter, h *Handler) {
	read := r.Group("/api/uploads", auth.RequireLogin())
	read.GET("", h.List)

	write := r.Group("/api/uploads", auth.RequireWrite())
	write.POST("", h.Create)
}
