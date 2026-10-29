package auth

import (
	"regexp"
	"strings"
	"testing"
)

// 32 字节 base64url 无填充后固定 43 个字符。
const b64Len = 43

func TestRandomTokenFormat(t *testing.T) {
	seen := make(map[string]bool, 100)
	for i := 0; i < 100; i++ {
		tok, err := randomToken()
		if err != nil {
			t.Fatalf("randomToken() 返回错误: %v", err)
		}
		if len(tok) != b64Len {
			t.Fatalf("base64url(32 字节) 长度应为 %d，实际 %d (%q)", b64Len, len(tok), tok)
		}
		if !regexp.MustCompile(`^[A-Za-z0-9_-]+$`).MatchString(tok) {
			t.Fatalf("token 含 base64url 之外的字符: %q", tok)
		}
		if seen[tok] {
			t.Fatalf("生成了重复 token: %q", tok)
		}
		seen[tok] = true
	}
}

func TestSessionAndDeviceTokenUnique(t *testing.T) {
	a, err := newSessionToken()
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(a, sessionTokenPrefix) {
		t.Errorf("会话 token 应以 %q 开头，实际 %q", sessionTokenPrefix, a)
	}

	b, err := newDeviceToken()
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(b, deviceTokenPrefix) {
		t.Errorf("设备 token 应以 %q 开头，实际 %q", deviceTokenPrefix, b)
	}

	if a == b {
		t.Error("两次生成的 token 不应相同")
	}
}

func TestPendingTokenTrustDevice(t *testing.T) {
	t.Run("不带授信标记", func(t *testing.T) {
		plain, err := newPendingToken(false)
		if err != nil {
			t.Fatal(err)
		}
		if strings.HasSuffix(plain, pendingTrustSuffixOn) {
			t.Fatalf("未请求授信时不应带后缀: %q", plain)
		}

		token, trust := splitPendingToken(plain)
		if trust {
			t.Error("splitPendingToken 应返回 trustDevice=false")
		}
		if token != plain {
			t.Errorf("无后缀时应原样返回，实际 %q", token)
		}
	})

	t.Run("带授信标记", func(t *testing.T) {
		plain, err := newPendingToken(true)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.HasSuffix(plain, pendingTrustSuffixOn) {
			t.Fatalf("请求授信时应带后缀: %q", plain)
		}

		token, trust := splitPendingToken(plain)
		if !trust {
			t.Error("splitPendingToken 应返回 trustDevice=true")
		}
		if strings.HasSuffix(token, pendingTrustSuffixOn) {
			t.Errorf("剥离后不应残留后缀: %q", token)
		}
		if len(token) != len(pendingTokenPrefix)+b64Len {
			t.Errorf("剥离后长度异常: %d", len(token))
		}
	})
}

func TestPendingTokenHashIgnoresSuffix(t *testing.T) {
	// 同一个 token 是否请求授信，剥离后缀后哈希必须一致；
	// 不剥离直接哈希则不同 —— 这正是「先剥离再哈希」不可省略的原因。
	plain, err := newPendingToken(true)
	if err != nil {
		t.Fatal(err)
	}
	base, trust := splitPendingToken(plain)
	if !trust {
		t.Fatal("splitPendingToken 应识别出授信标记")
	}

	if HashToken(plain) == HashToken(base) {
		t.Error("未剥离后缀时哈希应不同，说明剥离步骤不可省略")
	}

	rebuilt := base + pendingTrustSuffixOn
	if stripped, _ := splitPendingToken(rebuilt); HashToken(stripped) != HashToken(base) {
		t.Error("带后缀的值剥离后应与 base 哈希一致")
	}
}

func TestPendingTokenSuffixStrippedBeforeHash(t *testing.T) {
	// 直接对带后缀的明文哈希会查不到记录，这是调用方必须遵守的顺序。
	if HashToken("tok:1") == HashToken("tok") {
		t.Error("带后缀与不带后缀的哈希应不同")
	}
}

func TestAPIToken(t *testing.T) {
	t.Run("read", func(t *testing.T) {
		token, prefix, err := newAPIToken("read")
		if err != nil {
			t.Fatal(err)
		}
		if !strings.HasPrefix(token, apiTokenReadPrefix) {
			t.Errorf("read token 应以 %q 开头，实际 %q", apiTokenReadPrefix, token)
		}
		if len(prefix) != tokenPrefixLen {
			t.Errorf("token_prefix 长度应为 %d，实际 %d (%q)", tokenPrefixLen, len(prefix), prefix)
		}
		if !strings.HasPrefix(token, prefix) {
			t.Errorf("token_prefix 应是明文前缀: prefix=%q token=%q", prefix, token)
		}
	})

	t.Run("read_write", func(t *testing.T) {
		token, _, err := newAPIToken("read_write")
		if err != nil {
			t.Fatal(err)
		}
		if !strings.HasPrefix(token, apiTokenWritePrefix) {
			t.Errorf("read_write token 应以 %q 开头，实际 %q", apiTokenWritePrefix, token)
		}
	})

	t.Run("非法 scope", func(t *testing.T) {
		if _, _, err := newAPIToken("admin"); err == nil {
			t.Error("非法 scope 应返回错误")
		}
	})
}

func TestHashToken(t *testing.T) {
	got := HashToken("hello")
	// 固定向量，防止哈希实现被意外改动
	const want = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
	if got != want {
		t.Errorf("HashToken(\"hello\") = %q，期望 %q", got, want)
	}
	if len(got) != 64 {
		t.Errorf("SHA-256 十六进制长度应为 64，实际 %d", len(got))
	}
}

func TestSecureEqual(t *testing.T) {
	if !secureEqual("abc", "abc") {
		t.Error("相同字符串应返回 true")
	}
	if secureEqual("abc", "abd") {
		t.Error("不同字符串应返回 false")
	}
	if secureEqual("abc", "abcd") {
		t.Error("不同长度应返回 false")
	}
}
