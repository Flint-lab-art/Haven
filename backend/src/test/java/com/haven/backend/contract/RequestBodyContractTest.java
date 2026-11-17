package com.haven.backend.contract;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.haven.backend.auth.dto.CreateTokenRequest;
import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.dto.LoginTotpRequest;
import com.haven.backend.auth.dto.PasswordChangeRequest;
import com.haven.backend.auth.dto.TotpDisableRequest;
import com.haven.backend.auth.dto.TotpVerifyRequest;
import com.haven.backend.issue.dto.CreateIssueRequest;
import com.haven.backend.issue.dto.UpdateIssueRequest;
import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.QuickCommitRequest;
import com.haven.backend.ledger.dto.QuickParseRequest;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import com.haven.backend.note.dto.CreateFolderRequest;
import com.haven.backend.note.dto.CreateNoteRequest;
import com.haven.backend.note.dto.CreateTagRequest;
import com.haven.backend.note.dto.UpdateFolderRequest;
import com.haven.backend.note.dto.UpdateNoteRequest;
import com.haven.backend.portfolio.dto.AddRepoRequest;
import com.haven.backend.portfolio.dto.CreatePortfolioItemRequest;
import com.haven.backend.portfolio.dto.UpdatePortfolioItemRequest;
import com.haven.backend.portfolio.dto.UpdateRepoRequest;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import tools.jackson.databind.ObjectMapper;

/**
 * 请求体契约测试：前端发出的 JSON 必须能被后端 DTO 正确绑定。
 *
 * <p>为什么单独做这一层：
 *
 * <p>项目使用 Jackson 3（{@code tools.jackson}），
 * {@code spring.jackson.property-naming-strategy=SNAKE_CASE} 在**反序列化时同样生效**——
 * DTO 只接受 {@code snake_case}，收到 {@code camelCase} 会被静默忽略。
 * 一旦前端做了键名转换，字段全部绑定成 {@code null}：
 * 必填字段报 400「不能为空」，可空字段静默变 null（更难发现）。
 *
 * <p>这类问题占位测试与类型检查都拦不住，只有"真实 JSON → 真实 ObjectMapper → DTO"
 * 才能复现。所以每个 {@code @RequestBody} DTO 都在这里固定一份**前端实际会发的 JSON**，
 * 并断言字段确实被绑上了值。
 *
 * <p>约束：这里的 ObjectMapper 必须来自 Spring 容器（带 {@code SNAKE_CASE} 配置），
 * 不要自己 new，否则测不到命名策略。
 */
@SpringBootTest
@ActiveProfiles("test")
class RequestBodyContractTest {

    private final ObjectMapper mapper;

    @Autowired
    RequestBodyContractTest(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    // -----------------------------------------------------------------------
    // 认证
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("登录请求：snake_case 能被绑定")
    void loginRequest() throws Exception {
        String json = """
                {"username":"alice","password":"secret","trust_device":true}
                """;

        LoginRequest req = mapper.readValue(json, LoginRequest.class);

        assertEquals("alice", req.username());
        assertEquals("secret", req.password());
        // 可空字段最容易静默丢失，必须单独断言
        assertEquals(Boolean.TRUE, req.trustDevice());
    }

    @Test
    @DisplayName("登录请求：camelCase 不应被绑定（记录 Jackson 3 的实际行为）")
    void loginRequestRejectsCamelCase() throws Exception {
        String json = """
                {"username":"alice","password":"secret","trustDevice":true}
                """;

        LoginRequest req = mapper.readValue(json, LoginRequest.class);

        assertEquals("alice", req.username());
        // 这一行是本测试的用意：camelCase 会被忽略，前端必须发 snake_case
        assertEquals(null, req.trustDevice());
    }

    @Test
    @DisplayName("TOTP 第二步：temp_token 能被绑定")
    void loginTotpRequest() throws Exception {
        String json = """
                {"temp_token":"abc123","code":"123456"}
                """;

        LoginTotpRequest req = mapper.readValue(json, LoginTotpRequest.class);

        assertEquals("abc123", req.tempToken());
        assertEquals("123456", req.code());
    }

    @Test
    @DisplayName("绑定 TOTP：secret 与 code")
    void totpVerifyRequest() throws Exception {
        TotpVerifyRequest req = mapper.readValue("""
                {"secret":"JBSWY3DPEHPK3PXP","code":"654321"}
                """, TotpVerifyRequest.class);

        assertEquals("JBSWY3DPEHPK3PXP", req.secret());
        assertEquals("654321", req.code());
    }

    @Test
    @DisplayName("关闭 TOTP：code")
    void totpDisableRequest() throws Exception {
        assertEquals("111111", mapper.readValue("""
                {"code":"111111"}
                """, TotpDisableRequest.class).code());
    }

    @Test
    @DisplayName("改密：old_password / new_password / totp_code")
    void passwordChangeRequest() throws Exception {
        PasswordChangeRequest req = mapper.readValue("""
                {"old_password":"old-secret","new_password":"new-secret-12","totp_code":"222222"}
                """, PasswordChangeRequest.class);

        assertEquals("old-secret", req.oldPassword());
        assertEquals("new-secret-12", req.newPassword());
        assertEquals("222222", req.totpCode());
    }

    @Test
    @DisplayName("创建 Token：expires_at")
    void createTokenRequest() throws Exception {
        CreateTokenRequest req = mapper.readValue("""
                {"name":"ci","scope":"read_write","expires_at":"2027-01-01T00:00:00Z"}
                """, CreateTokenRequest.class);

        assertEquals("ci", req.name());
        assertEquals("read_write", req.scope());
        assertNotNull(req.expiresAt());
    }

    // -----------------------------------------------------------------------
    // 笔记 / 文件夹 / 标签
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("创建笔记：tag_ids / folder_id")
    void createNoteRequest() throws Exception {
        String json = """
                {"title":"标题","content":"正文","tag_ids":["11111111-1111-1111-1111-111111111111"],"folder_id":"22222222-2222-2222-2222-222222222222"}
                """;

        CreateNoteRequest req = mapper.readValue(json, CreateNoteRequest.class);

        assertEquals("标题", req.title());
        assertEquals(1, req.tagIds().size());
        assertNotNull(req.folderId());
    }

    @Test
    @DisplayName("更新笔记：clear_folder / sort_order / tag_ids")
    void updateNoteRequest() throws Exception {
        String json = """
                {"clear_folder":true,"sort_order":3,"tag_ids":[]}
                """;

        UpdateNoteRequest req = mapper.readValue(json, UpdateNoteRequest.class);

        assertEquals(Boolean.TRUE, req.clearFolder());
        assertEquals(3, req.sortOrder());
        assertEquals(List.of(), req.tagIds());
    }

    @Test
    @DisplayName("创建文件夹：parent_id")
    void createFolderRequest() throws Exception {
        CreateFolderRequest req = mapper.readValue("""
                {"name":"工作","parent_id":"33333333-3333-3333-3333-333333333333"}
                """, CreateFolderRequest.class);

        assertEquals("工作", req.name());
        assertNotNull(req.parentId());
    }

    @Test
    @DisplayName("更新文件夹：clear_parent / sort_order")
    void updateFolderRequest() throws Exception {
        UpdateFolderRequest req = mapper.readValue("""
                {"clear_parent":true,"sort_order":2}
                """, UpdateFolderRequest.class);

        assertEquals(Boolean.TRUE, req.clearParent());
        assertEquals(2, req.sortOrder());
    }

    @Test
    @DisplayName("创建标签：name")
    void createTagRequest() throws Exception {
        assertEquals("读书", mapper.readValue("""
                {"name":"读书"}
                """, CreateTagRequest.class).name());
    }

    // -----------------------------------------------------------------------
    // 记账
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("快捷解析：text")
    void quickParseRequest() throws Exception {
        assertEquals("午饭 12", mapper.readValue("""
                {"text":"午饭 12"}
                """, QuickParseRequest.class).text());
    }

    @Test
    @DisplayName("快捷记账：batch_id / text")
    void quickCommitRequest() throws Exception {
        QuickCommitRequest req = mapper.readValue("""
                {"batch_id":"b-1","text":"午饭 12"}
                """, QuickCommitRequest.class);

        assertEquals("b-1", req.batchId());
        assertEquals("午饭 12", req.text());
    }

    @Test
    @DisplayName("批次写入：batch_id / raw_text / items[amount_cents]")
    void createLedgerBatchRequest() throws Exception {
        String json = """
                {
                  "batch_id":"b-2",
                  "raw_text":"午饭 12",
                  "items":[{"type":"expense","amount_cents":1200,"category":"餐饮","note":"午饭","occurred_at":"2026-01-02T03:00:00Z"}]
                }
                """;

        CreateLedgerBatchRequest req = mapper.readValue(json, CreateLedgerBatchRequest.class);

        assertEquals("b-2", req.batchId());
        assertEquals("午饭 12", req.rawText());
        assertEquals(1, req.items().size());

        CreateLedgerEntryRequest item = req.items().getFirst();
        assertEquals(1200L, item.amountCents());
        assertEquals("expense", item.type());
        assertNotNull(item.occurredAt());
    }

    @Test
    @DisplayName("修改条目：amount_cents / occurred_at / category")
    void updateLedgerEntryRequest() throws Exception {
        UpdateLedgerEntryRequest req = mapper.readValue("""
                {"amount_cents":2500,"occurred_at":"2026-01-03T00:00:00Z","category":"餐饮"}
                """, UpdateLedgerEntryRequest.class);

        assertEquals(2500L, req.amountCents());
        assertNotNull(req.occurredAt());
        assertEquals("餐饮", req.category());
    }

    @Test
    @DisplayName("别名：alias / category")
    void upsertLedgerAliasRequest() throws Exception {
        UpsertLedgerAliasRequest req = mapper.readValue("""
                {"alias":"午饭","category":"餐饮"}
                """, UpsertLedgerAliasRequest.class);

        assertEquals("午饭", req.alias());
        assertEquals("餐饮", req.category());
    }

    // -----------------------------------------------------------------------
    // Issue
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("创建 Issue：title / type / status / priority")
    void createIssueRequest() throws Exception {
        CreateIssueRequest req = mapper.readValue("""
                {"title":"登录失败","description":"复现步骤","type":"bug","status":"todo","priority":"high"}
                """, CreateIssueRequest.class);

        assertEquals("登录失败", req.title());
        assertEquals("bug", req.type());
        assertEquals("todo", req.status());
        assertEquals("high", req.priority());
    }

    @Test
    @DisplayName("更新 Issue：全部字段可选")
    void updateIssueRequest() throws Exception {
        UpdateIssueRequest req = mapper.readValue("""
                {"status":"done","priority":"low"}
                """, UpdateIssueRequest.class);

        assertEquals("done", req.status());
        assertEquals("low", req.priority());
        assertEquals(null, req.title());
    }

    // -----------------------------------------------------------------------
    // 作品集
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("创建作品：sort_order / is_public")
    void createPortfolioItemRequest() throws Exception {
        CreatePortfolioItemRequest req = mapper.readValue("""
                {"title":"Haven","description":"笔记","content":"正文","sort_order":1,"is_public":true}
                """, CreatePortfolioItemRequest.class);

        assertEquals("Haven", req.title());
        assertEquals(1, req.sortOrder());
        assertEquals(Boolean.TRUE, req.isPublic());
    }

    @Test
    @DisplayName("更新作品：is_public / sort_order")
    void updatePortfolioItemRequest() throws Exception {
        UpdatePortfolioItemRequest req = mapper.readValue("""
                {"is_public":false,"sort_order":9}
                """, UpdatePortfolioItemRequest.class);

        assertEquals(Boolean.FALSE, req.isPublic());
        assertEquals(9, req.sortOrder());
    }

    @Test
    @DisplayName("添加链接：url / is_primary")
    void addRepoRequest() throws Exception {
        AddRepoRequest req = mapper.readValue("""
                {"url":"https://github.com/x/y","title":"repo","is_primary":true}
                """, AddRepoRequest.class);

        assertEquals("https://github.com/x/y", req.url());
        assertEquals(Boolean.TRUE, req.isPrimary());
    }

    @Test
    @DisplayName("更新链接：is_primary")
    void updateRepoRequest() throws Exception {
        UpdateRepoRequest req = mapper.readValue("""
                {"is_primary":false}
                """, UpdateRepoRequest.class);

        assertEquals(Boolean.FALSE, req.isPrimary());
    }
}
