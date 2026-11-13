package com.haven.backend.ledger.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.QuickParseRequest;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import com.haven.backend.ledger.service.LedgerService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

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
    public QuickParseResult quick(@Valid @RequestBody QuickParseRequest req,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.quickParse(userId, req.text());
    }

    /**
     * 确认写入。重复提交相同 batch_id 时返回已有结果，并带 {@code created=false}。
     */
    @PostMapping({"/entries/batch", "/batches"})
    public ResponseEntity<Map<String, Object>> createBatch(
            @Valid @RequestBody CreateLedgerBatchRequest req,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        Map<String, Object> result = ledgerService.createBatch(userId, req);
        boolean created = Boolean.TRUE.equals(result.get("created"));
        return ResponseEntity.status(created ? HttpStatus.CREATED : HttpStatus.OK).body(result);
    }

    @GetMapping("/batches/{batchId}")
    public Map<String, Object> getBatch(@PathVariable String batchId, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.getBatch(userId, batchId);
    }

    // ---- 明细 ----

    @GetMapping("/entries")
    public Map<String, Object> listEntries(
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
    public Map<String, Object> getEntry(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.getEntry(userId, UUID.fromString(id));
    }

    @PatchMapping("/entries/{id}")
    public Map<String, Object> updateEntry(
            @PathVariable String id,
            @Valid @RequestBody UpdateLedgerEntryRequest req,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.updateEntry(userId, UUID.fromString(id), req);
    }

    @DeleteMapping("/entries/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteEntry(@PathVariable String id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        ledgerService.deleteEntry(userId, UUID.fromString(id));
    }

    @GetMapping("/recent")
    public Map<String, Object> recentEntries(
            @RequestParam(defaultValue = "3") int limit,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.recentEntries(userId, limit);
    }

    // ---- 汇总 ----

    /**
     * 月度汇总：总额 + 分类排行 + 按天走势 + 最近 3 笔。
     * 手机端“汇总”快捷指令直接使用该接口。
     */
    @GetMapping("/summary")
    public Map<String, Object> summary(
            @RequestParam(required = false) String month,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.summary(userId, month);
    }

    /**
     * 最近 N 天的统计与按天走势，默认 7 天，最多 90 天；仪表盘使用。
     */
    @GetMapping("/trend")
    public Map<String, Object> trend(
            @RequestParam(defaultValue = "7") int days,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.trend(userId, days);
    }

    @GetMapping("/categories")
    public Map<String, Object> categories() {
        List<String> categories = ledgerService.categories();
        return Map.of("items", categories, "total", categories.size());
    }

    // ---- 别名维护 ----

    @GetMapping("/aliases")
    public Map<String, Object> listAliases(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return ledgerService.listAliases(userId);
    }

    @PostMapping("/aliases")
    public Map<String, Object> upsertAlias(
            @Valid @RequestBody UpsertLedgerAliasRequest req,
            HttpServletRequest request) {
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
