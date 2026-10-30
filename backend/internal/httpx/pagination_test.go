package httpx

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func init() { gin.SetMode(gin.TestMode) }

func parseQuery(raw string) (Pagination, error) {
	c, _ := gin.CreateTestContext(httptest.NewRecorder())
	c.Request = httptest.NewRequest(http.MethodGet, "/?"+raw, nil)
	return ParsePagination(c)
}

func TestParsePaginationDefaults(t *testing.T) {
	p, err := parseQuery("")
	if err != nil {
		t.Fatalf("默认值不应报错: %v", err)
	}
	if p.Limit != DefaultLimit || p.Offset != 0 {
		t.Errorf("默认应为 limit=20 offset=0，实际 %+v", p)
	}
}

func TestParsePaginationValues(t *testing.T) {
	cases := []struct {
		query string
		want  Pagination
	}{
		{"limit=5&offset=10", Pagination{Limit: 5, Offset: 10}},
		{"limit=1", Pagination{Limit: 1, Offset: 0}},
		// 超过上限按上限截断（api.md 1.5）
		{"limit=500", Pagination{Limit: MaxLimit, Offset: 0}},
	}
	for _, tc := range cases {
		p, err := parseQuery(tc.query)
		if err != nil {
			t.Errorf("%s 不应报错: %v", tc.query, err)
			continue
		}
		if p != tc.want {
			t.Errorf("%s -> %+v，期望 %+v", tc.query, p, tc.want)
		}
	}
}

func TestParsePaginationInvalid(t *testing.T) {
	for _, q := range []string{"limit=0", "limit=-1", "limit=abc", "offset=-5", "offset=x"} {
		if _, err := parseQuery(q); err == nil {
			t.Errorf("%s 应返回错误", q)
		}
	}
}

func TestNewListEmptyIsArray(t *testing.T) {
	w := run(func(c *gin.Context) {
		c.JSON(http.StatusOK, NewList(nil, 0))
	})
	if body := w.Body.String(); body != `{"items":[],"total":0}` {
		t.Errorf("空列表应输出 []，实际 %s", body)
	}
}

func TestNewListWithItems(t *testing.T) {
	w := run(func(c *gin.Context) {
		c.JSON(http.StatusOK, NewList([]string{"a"}, 1))
	})
	if body := w.Body.String(); body != `{"items":["a"],"total":1}` {
		t.Errorf("列表响应异常: %s", body)
	}
}
