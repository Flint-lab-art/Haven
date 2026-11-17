package com.haven.backend.note.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.exception.BizException;
import com.haven.backend.exception.GlobalExceptionHandler;
import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.TagSummary;
import com.haven.backend.note.service.NotesService;
import com.haven.backend.note.service.TagsService;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

/**
 * Web 层契约测试：状态码、错误响应体与参数校验。
 * <p>
 * 用 {@code MockMvcBuilders.standaloneSetup} 只装配两个 Controller 与全局异常处理器，
 * 不启动 Spring 上下文，因此不依赖数据库、拦截器或 Sa-Token。
 * <p>
 * 身份用 {@link #user()} 写进请求属性 {@code auth_userId}，与真实拦截器的注入方式一致；
 * 真实的身份解析由 {@code AuthInterceptorTest} 覆盖。
 */
class NotesControllerWebTest {

    private static final String USER_ID = "11111111-1111-1111-1111-111111111111";

    private final NotesService notesService = Mockito.mock(NotesService.class);
    private final TagsService tagsService = Mockito.mock(TagsService.class);

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new NotesController(notesService), new TagsController(tagsService))
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("GET /api/notes 返回 200 与分页结构")
    void listReturnsPage() throws Exception {
        when(notesService.listNotes(any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new NotePage(List.of(), 0));

        mockMvc.perform(get("/api/notes").with(user()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(0))
                .andExpect(jsonPath("$.items").isArray());
    }

    @Test
    @DisplayName("非法 UUID 路径参数返回 400 而不是 500")
    void invalidUuidReturns400() throws Exception {
        mockMvc.perform(get("/api/notes/not-a-uuid").with(user()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("bad_request"));
    }

    @Test
    @DisplayName("标题超长时返回 400 且带 fields")
    void tooLongTitleReturns400() throws Exception {
        String body = "{\"title\":\"" + "a".repeat(201) + "\",\"content\":\"x\"}";

        mockMvc.perform(post("/api/notes")
                        .with(user())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("validation_failed"))
                .andExpect(jsonPath("$.fields.title").exists());
    }

    @Test
    @DisplayName("业务异常按 code 映射状态码（404）")
    void bizExceptionMapsStatus() throws Exception {
        when(notesService.getNote(any(), any())).thenThrow(BizException.notFound("笔记不存在"));

        mockMvc.perform(get("/api/notes/" + USER_ID).with(user()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("not_found"));
    }

    @Test
    @DisplayName("标签名超长返回 400")
    void tagNameTooLongReturns400() throws Exception {
        String body = "{\"name\":\"" + "a".repeat(65) + "\"}";

        mockMvc.perform(post("/api/tags")
                        .with(user())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields.name").exists());
    }

    @Test
    @DisplayName("GET /api/tags 正常返回标签列表")
    void listTagsReturnsItems() throws Exception {
        when(tagsService.listTags(any()))
                .thenReturn(List.of(new TagSummary(UUID.randomUUID(), "工作", 3, OffsetDateTime.now())));

        mockMvc.perform(get("/api/tags").with(user()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].name").value("工作"))
                .andExpect(jsonPath("$.total").value(1));
    }

    @Test
    @DisplayName("DELETE 笔记返回 204")
    void deleteReturns204() throws Exception {
        mockMvc.perform(delete("/api/notes/" + USER_ID).with(user())).andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("PATCH 请求体不是合法 JSON 时返回 400")
    void malformedPatchBodyReturns400() throws Exception {
        mockMvc.perform(patch("/api/notes/" + USER_ID)
                        .with(user())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{bad json}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("bad_request"));
    }

    @Test
    @DisplayName("没有身份上下文时返回 401")
    void missingIdentityReturns401() throws Exception {
        mockMvc.perform(get("/api/notes"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("unauthorized"));
    }

    @Test
    @DisplayName("分页参数为负数时不会 500")
    void negativeLimitIsClamped() throws Exception {
        when(notesService.listNotes(any(), anyInt(), any(), any(), any(), any(), any()))
                .thenReturn(new NotePage(List.of(), 0));

        mockMvc.perform(get("/api/notes?limit=-5&offset=-3").with(user())).andExpect(status().isOk());
    }

    /** 模拟拦截器注入的身份上下文。 */
    private static RequestPostProcessor user() {
        return request -> {
            ((MockHttpServletRequest) request).setAttribute(AuthInterceptor.ATTR_USER_ID, USER_ID);
            ((MockHttpServletRequest) request).setAttribute(AuthInterceptor.ATTR_SCOPE, "read_write");
            ((MockHttpServletRequest) request).setAttribute(AuthInterceptor.ATTR_AUTH_TYPE, "session");
            return request;
        };
    }
}
