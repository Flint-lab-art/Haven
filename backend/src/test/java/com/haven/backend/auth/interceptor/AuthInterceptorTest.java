package com.haven.backend.auth.interceptor;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.haven.backend.auth.entity.Tokens;
import com.haven.backend.auth.mapper.TokensMapper;
import com.haven.backend.auth.util.ApiTokenUtil;
import com.haven.backend.exception.BizException;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.method.HandlerMethod;

/**
 * 拦截器错误契约与权限声明测试：认证失败必须抛出 BizException（交给全局处理器输出 {@code {error,message}}），
 * 只读 Token 的边界由端点声明的 {@link RequiredAccess} 决定，而不是只看 HTTP 方法。
 */
@ExtendWith(MockitoExtension.class)
class AuthInterceptorTest {

    private static final String RAW_TOKEN = "raw-token-value";
    /** 固定时钟：Token 过期与 last_used_at 节流判定不依赖真实时间。 */
    private static final java.time.Clock FIXED_CLOCK =
            java.time.Clock.fixed(java.time.Instant.parse("2026-01-02T03:04:05Z"), java.time.ZoneOffset.UTC);

    @Mock
    private TokensMapper tokensMapper;

    private AuthInterceptor interceptor;

    @BeforeEach
    void setUp() {
        interceptor = new AuthInterceptor(tokensMapper, FIXED_CLOCK);
    }

    @Test
    @DisplayName("未知 Token 抛出 401 业务异常")
    void unknownTokenIsUnauthorized() {
        when(tokensMapper.selectOne(any())).thenReturn(null);

        BizException ex = assertThrows(
                BizException.class,
                () -> interceptor.preHandle(request("GET", "/api/notes"), new MockHttpServletResponse(), new Object()));

        assertEquals(401, ex.getCode());
    }

    @Test
    @DisplayName("过期 Token 抛出 401 业务异常")
    void expiredTokenIsUnauthorized() {
        Tokens token = token("read_write");
        token.setExpiresAt(OffsetDateTime.now(FIXED_CLOCK).minusMinutes(1));
        when(tokensMapper.selectOne(any())).thenReturn(token);

        BizException ex = assertThrows(
                BizException.class,
                () -> interceptor.preHandle(request("GET", "/api/notes"), new MockHttpServletResponse(), new Object()));

        assertEquals(401, ex.getCode());
    }

    @Test
    @DisplayName("只读 Token 执行写操作抛出 403")
    void readOnlyTokenCannotWrite() {
        when(tokensMapper.selectOne(any())).thenReturn(token("read_only"));

        BizException ex = assertThrows(
                BizException.class,
                () -> interceptor.preHandle(
                        request("POST", "/api/notes"), new MockHttpServletResponse(), new Object()));

        assertEquals(403, ex.getCode());
    }

    @Test
    @DisplayName("只读 Token 可以读")
    void readOnlyTokenCanRead() {
        when(tokensMapper.selectOne(any())).thenReturn(token("read"));

        assertTrue(interceptor.preHandle(request("GET", "/api/notes"), new MockHttpServletResponse(), new Object()));
    }

    @Test
    @DisplayName("GET 端点显式声明 WRITE 时，只读 Token 被拒绝")
    void readOnlyTokenCannotCallWriteAnnotatedGet() throws Exception {
        when(tokensMapper.selectOne(any())).thenReturn(token("read"));

        BizException ex = assertThrows(
                BizException.class,
                () -> interceptor.preHandle(
                        request("GET", "/api/notes"),
                        new MockHttpServletResponse(),
                        handlerMethod("writeAnnotatedGet")));

        assertEquals(403, ex.getCode());
    }

    @Test
    @DisplayName("read_write Token 可以调用显式声明 WRITE 的 GET 端点")
    void writeTokenCanCallWriteAnnotatedGet() throws Exception {
        when(tokensMapper.selectOne(any())).thenReturn(token("read_write"));

        assertTrue(interceptor.preHandle(
                request("GET", "/api/notes"), new MockHttpServletResponse(), handlerMethod("writeAnnotatedGet")));
    }

    @Test
    @DisplayName("会话端点拒绝 API Token（即使 read_write）")
    void tokenCannotAccessSessionEndpoint() throws Exception {
        when(tokensMapper.selectOne(any())).thenReturn(token("read_write"));

        BizException ex = assertThrows(
                BizException.class,
                () -> interceptor.preHandle(
                        request("GET", "/api/sessions"), new MockHttpServletResponse(), handlerMethod("sessionOnly")));

        assertEquals(403, ex.getCode());
    }

    @Test
    @DisplayName("有效 Token 注入身份与 auth_type")
    void validTokenInjectsIdentity() {
        Tokens token = token("read_write");
        when(tokensMapper.selectOne(any())).thenReturn(token);
        MockHttpServletRequest request = request("GET", "/api/notes");

        boolean allowed = interceptor.preHandle(request, new MockHttpServletResponse(), new Object());

        assertTrue(allowed);
        assertEquals(token.getUserId().toString(), AuthInterceptor.getUserId(request));
        assertEquals("token", AuthInterceptor.getAuthType(request));
    }

    @Test
    @DisplayName("last_used_at 在 5 分钟节流窗口内不重复写库")
    void lastUsedAtIsThrottled() {
        Tokens token = token("read_write");
        token.setLastUsedAt(OffsetDateTime.now(FIXED_CLOCK).minusMinutes(1));
        when(tokensMapper.selectOne(any())).thenReturn(token);

        interceptor.preHandle(request("GET", "/api/notes"), new MockHttpServletResponse(), new Object());

        verify(tokensMapper, never()).updateById(any(Tokens.class));
    }

    @Test
    @DisplayName("last_used_at 超过节流窗口时才写库")
    void lastUsedAtWrittenAfterWindow() {
        Tokens token = token("read_write");
        token.setLastUsedAt(OffsetDateTime.now(FIXED_CLOCK).minusMinutes(10));
        when(tokensMapper.selectOne(any())).thenReturn(token);
        when(tokensMapper.updateById(any(Tokens.class))).thenReturn(1);

        interceptor.preHandle(request("GET", "/api/notes"), new MockHttpServletResponse(), new Object());

        verify(tokensMapper).updateById(any(Tokens.class));
    }

    @Test
    @DisplayName("/api/me 携带无效 Token 时按匿名处理，不返回 401")
    void mePathTreatsInvalidTokenAsAnonymous() {
        when(tokensMapper.selectOne(any())).thenReturn(null);
        MockHttpServletRequest request = request("GET", "/api/me");
        request.setRequestURI("/api/me");

        boolean allowed =
                assertDoesNotThrow(() -> interceptor.preHandle(request, new MockHttpServletResponse(), new Object()));

        assertTrue(allowed);
        assertNull(AuthInterceptor.getUserId(request));
        assertNull(AuthInterceptor.getAuthType(request));
    }

    private HandlerMethod handlerMethod(String name) throws NoSuchMethodException {
        return new HandlerMethod(new AnnotatedHandlers(), AnnotatedHandlers.class.getMethod(name));
    }

    /** 模拟端点声明：GET 但要求写权限、以及仅会话可用。 */
    static class AnnotatedHandlers {

        @RequireAccess(RequiredAccess.WRITE)
        public void writeAnnotatedGet() {}

        @RequireAccess(RequiredAccess.SESSION)
        public void sessionOnly() {}
    }

    private MockHttpServletRequest request(String method, String uri) {
        MockHttpServletRequest request = new MockHttpServletRequest(method, uri);
        request.addHeader("Authorization", "Bearer " + RAW_TOKEN);
        return request;
    }

    private Tokens token(String scope) {
        Tokens token = new Tokens();
        token.setId(UUID.randomUUID());
        token.setUserId(UUID.randomUUID());
        token.setTokenHash(ApiTokenUtil.hash(RAW_TOKEN));
        token.setScope(scope);
        return token;
    }
}
