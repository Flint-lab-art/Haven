package portfolio

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

// 链接校验与标题抓取（docs/v3/api.md 第五节）。

func TestValidateURL(t *testing.T) {
	cases := []struct {
		name    string
		in      string
		want    string
		wantErr bool
	}{
		{"https 完整地址", "https://github.com/kairo/haven", "https://github.com/kairo/haven", false},
		{"http 完整地址", "http://example.com/a", "http://example.com/a", false},
		{"首尾空白被去掉", "  https://example.com  ", "https://example.com", false},
		{"相对路径拒绝", "kairo/haven", "", true},
		{"空串拒绝", "", "", true},
		{"非 http 协议拒绝", "ftp://example.com/a", "", true},
		{"缺少主机拒绝", "https://", "", true},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ValidateURL(tc.in)
			if tc.wantErr {
				if err == nil {
					t.Fatalf("ValidateURL(%q) 应报错，实际返回 %q", tc.in, got)
				}
				return
			}
			if err != nil {
				t.Fatalf("ValidateURL(%q) 意外错误: %v", tc.in, err)
			}
			if got != tc.want {
				t.Errorf("ValidateURL(%q) = %q，期望 %q", tc.in, got, tc.want)
			}
		})
	}
}

func TestFetchTitle(t *testing.T) {
	cases := []struct {
		name   string
		status int
		body   string
		want   string
	}{
		{"普通标题", 200, "<html><head><title>Hello World</title></head></html>", "Hello World"},
		{"带属性", 200, `<title lang="zh">中文标题</title>`, "中文标题"},
		{"大小写混合", 200, `<TITLE>Upper</TITLE>`, "Upper"},
		{"跨行标题", 200, "<title>\n  多行\n  标题  \n</title>", "多行 标题"},
		{"HTML 实体", 200, "<title>A &amp; B &lt;C&gt;</title>", "A & B <C>"},
		{"没有 title", 200, "<html><body>no title</body></html>", ""},
		{"404 不抓取", 404, "<title>Not Found</title>", ""},
		{"空响应", 200, "", ""},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				// 确认带了 UA，部分站点会拒绝无 UA 的请求
				if r.Header.Get("User-Agent") == "" {
					t.Error("抓取标题时应带 User-Agent")
				}
				w.WriteHeader(tc.status)
				_, _ = w.Write([]byte(tc.body))
			}))
			defer srv.Close()

			if got := FetchTitle(context.Background(), srv.URL); got != tc.want {
				t.Errorf("FetchTitle() = %q，期望 %q", got, tc.want)
			}
		})
	}
}

func TestFetchTitleTruncates(t *testing.T) {
	long := ""
	for i := 0; i < titleMaxRunes+50; i++ {
		long += "字"
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("<title>" + long + "</title>"))
	}))
	defer srv.Close()

	got := FetchTitle(context.Background(), srv.URL)
	if n := len([]rune(got)); n != titleMaxRunes {
		t.Errorf("超长标题应截断到 %d 个字符，实际 %d", titleMaxRunes, n)
	}
}

func TestRepoKind(t *testing.T) {
	svc := &Service{gogsBaseURL: "https://gogs.example.com"}

	cases := []struct {
		url  string
		want string
	}{
		{"https://github.com/kairo/haven", "github"},
		{"https://www.github.com/kairo/haven", "github"},
		{"https://gogs.example.com/kairo/haven", "gogs"},
		{"https://go.dev/blog/", "link"},
		{"https://github.io/something", "link"},
		{"", "link"},
	}

	for _, tc := range cases {
		if got := svc.RepoKind(tc.url); got != tc.want {
			t.Errorf("RepoKind(%q) = %q，期望 %q", tc.url, got, tc.want)
		}
	}
}
