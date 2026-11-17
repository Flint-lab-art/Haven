package com.haven.backend.ledger.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerAliasDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerAliasPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerBatchDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerCategoriesDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerQuickCommitDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerSummaryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerTrendDto;
import com.haven.backend.ledger.dto.QuickCommitRequest;
import com.haven.backend.ledger.dto.QuickParseRequest;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import com.haven.backend.ledger.service.LedgerService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * 记账接口。
 * <p>
 * 全部位于 /api/**，需要登录；API Token 的写权限由 AuthInterceptor 统一校验。
 * 不接入公开域，也不参与公开搜索与公开统计。
 */
@RestController
@RequestMapping("/api/ledger")
@RequiredArgsConstructor
public class LedgerController {

    private final LedgerService ledgerService;

    /**
     * 手机端快捷记账：只解析不落库。
     * <p>
     * 一行一条，例如 {@code 午饭12}、{@code 网购 零食 100}，支持一次提交多行。
     */
    @PostMapping("/quick")
    public QuickParseResult quick(@Valid @RequestBody QuickParseRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.quickParse(userId, req.text());
    }

    /**
     * 快捷指令一步记账：解析并直接写入。
     * <p>
     * 与「先 quick 预览、再 batch 确认」等价；没有解析出内容时返回 200，
     * 并在 {@code errors} 里给出逐行原因。
     */
    @PostMapping("/entries/quick")
    public ResponseEntity<LedgerQuickCommitDto> quickCommit(
            @Valid @RequestBody QuickCommitRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        LedgerQuickCommitDto result = ledgerService.quickCommit(userId, req);
        return ResponseEntity.status(result.batch().created() ? HttpStatus.CREATED : HttpStatus.OK)
                .body(result);
    }

    /**
     * 确认写入。重复提交相同 batch_id 时返回已有结果，并带 {@code created=false}。
     */
    @PostMapping({"/entries/batch", "/batches"})
    public ResponseEntity<LedgerBatchDto> createBatch(
            @Valid @RequestBody CreateLedgerBatchRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        LedgerBatchDto result = ledgerService.createBatch(userId, req);
        return ResponseEntity.status(result.created() ? HttpStatus.CREATED : HttpStatus.OK)
                .body(result);
    }

    @GetMapping("/batches/{batchId}")
    public LedgerBatchDto getBatch(@PathVariable String batchId, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.getBatch(userId, batchId);
    }

    // ---- 明细 ----

    @GetMapping("/entries")
    public LedgerEntryPage listEntries(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) OffsetDateTime from,
            @RequestParam(required = false) OffsetDateTime to,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.listEntries(userId, type, category, from, to, limit, offset);
    }

    @GetMapping("/entries/{id}")
    public LedgerEntryDto getEntry(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.getEntry(userId, id);
    }

    @PatchMapping("/entries/{id}")
    public LedgerEntryDto updateEntry(
            @PathVariable UUID id, @Valid @RequestBody UpdateLedgerEntryRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.updateEntry(userId, id, req);
    }

    @DeleteMapping("/entries/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteEntry(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        ledgerService.deleteEntry(userId, id);
    }

    @GetMapping("/recent")
    public LedgerEntryPage recentEntries(@RequestParam(defaultValue = "3") int limit, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.recentEntries(userId, limit);
    }

    // ---- 汇总 ----

    /**
     * 月度汇总：总额 + 分类排行 + 按天走势 + 最近 3 笔。
     * 手机端“汇总”快捷指令直接使用该接口。
     */
    @GetMapping("/summary")
    public LedgerSummaryDto summary(@RequestParam(required = false) String month, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.summary(userId, month);
    }

    /**
     * 最近 N 天的统计与按天走势，默认 7 天，最多 90 天；仪表盘使用。
     */
    @GetMapping("/trend")
    public LedgerTrendDto trend(@RequestParam(defaultValue = "7") int days, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.trend(userId, days);
    }

    @GetMapping("/categories")
    public LedgerCategoriesDto categories() {
        List<String> categories = ledgerService.categories();
        return new LedgerCategoriesDto(categories, categories.size());
    }

    // ---- 别名维护 ----

    @GetMapping("/aliases")
    public LedgerAliasPage listAliases(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.listAliases(userId);
    }

    @PostMapping("/aliases")
    public LedgerAliasDto upsertAlias(@Valid @RequestBody UpsertLedgerAliasRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.upsertAlias(userId, req);
    }

    @DeleteMapping("/aliases/{alias}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAlias(@PathVariable String alias, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        ledgerService.deleteAlias(userId, alias);
    }
}
