package com.haven.backend.ledger.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.auth.interceptor.RequireAccess;
import com.haven.backend.auth.interceptor.RequiredAccess;
import com.haven.backend.ledger.dto.AccountRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.LedgerDtos.AccountDto;
import com.haven.backend.ledger.dto.LedgerDtos.BudgetDto;
import com.haven.backend.ledger.dto.LedgerDtos.CategoryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerRangeStatsDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerSummaryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerTrendDto;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertBudgetRequest;
import com.haven.backend.ledger.service.LedgerService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * 记账接口：账户、分类、流水、统计、预算。
 */
@RestController
@RequestMapping("/api/ledger")
@RequiredArgsConstructor
public class LedgerController {

    private final LedgerService ledgerService;

    // ── 账户 ──────────────────────────────────────────

    @GetMapping("/accounts")
    @RequireAccess(RequiredAccess.READ)
    public List<AccountDto> listAccounts(HttpServletRequest request) {
        return ledgerService.listAccounts(AuthInterceptor.requireUserId(request));
    }

    @PostMapping("/accounts")
    @RequireAccess(RequiredAccess.WRITE)
    @ResponseStatus(HttpStatus.CREATED)
    public AccountDto createAccount(@Valid @RequestBody AccountRequest req, HttpServletRequest request) {
        return ledgerService.createAccount(AuthInterceptor.requireUserId(request), req);
    }

    @PutMapping("/accounts/{id}")
    @RequireAccess(RequiredAccess.WRITE)
    public AccountDto updateAccount(
            @PathVariable UUID id, @Valid @RequestBody AccountRequest req, HttpServletRequest request) {
        return ledgerService.updateAccount(AuthInterceptor.requireUserId(request), id, req);
    }

    @DeleteMapping("/accounts/{id}")
    @RequireAccess(RequiredAccess.WRITE)
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAccount(@PathVariable UUID id, HttpServletRequest request) {
        ledgerService.deleteAccount(AuthInterceptor.requireUserId(request), id);
    }

    // ── 分类 ──────────────────────────────────────────

    /** 分类树只跟系统数据走，与用户无关。 */
    @GetMapping("/categories")
    @RequireAccess(RequiredAccess.READ)
    public List<CategoryDto> categories() {
        return ledgerService.categoryTree();
    }

    // ── 流水 ──────────────────────────────────────────

    @PostMapping("/entries")
    @RequireAccess(RequiredAccess.WRITE)
    @ResponseStatus(HttpStatus.CREATED)
    public LedgerEntryDto createEntry(@Valid @RequestBody CreateLedgerEntryRequest req, HttpServletRequest request) {
        return ledgerService.createEntry(AuthInterceptor.requireUserId(request), req);
    }

    @GetMapping("/entries")
    @RequireAccess(RequiredAccess.READ)
    public LedgerEntryPage listEntries(
            @RequestParam(required = false) String type,
            @RequestParam(name = "category_id", required = false) Short categoryId,
            @RequestParam(name = "account_id", required = false) UUID accountId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {
        return ledgerService.listEntries(
                AuthInterceptor.requireUserId(request), type, categoryId, accountId, from, to, limit, offset);
    }

    @GetMapping("/entries/{id}")
    @RequireAccess(RequiredAccess.READ)
    public LedgerEntryDto getEntry(@PathVariable UUID id, HttpServletRequest request) {
        return ledgerService.getEntry(AuthInterceptor.requireUserId(request), id);
    }

    @PatchMapping("/entries/{id}")
    @RequireAccess(RequiredAccess.WRITE)
    public LedgerEntryDto updateEntry(
            @PathVariable UUID id, @Valid @RequestBody UpdateLedgerEntryRequest req, HttpServletRequest request) {
        return ledgerService.updateEntry(AuthInterceptor.requireUserId(request), id, req);
    }

    @DeleteMapping("/entries/{id}")
    @RequireAccess(RequiredAccess.WRITE)
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteEntry(@PathVariable UUID id, HttpServletRequest request) {
        ledgerService.deleteEntry(AuthInterceptor.requireUserId(request), id);
    }

    // ── 统计 ──────────────────────────────────────────

    @GetMapping("/summary")
    @RequireAccess(RequiredAccess.READ)
    public LedgerSummaryDto summary(@RequestParam(required = false) String month, HttpServletRequest request) {
        return ledgerService.summary(AuthInterceptor.requireUserId(request), month);
    }

    /**
     * 任意区间统计：周 / 月 / 季 / 年都由前端算好 from/to 后调用。
     *
     * 后端不认「周」「季度」这类语义，只做区间聚合——
     * 加新粒度不用改后端，也避免「本月」与「最近 30 天」两套边界各说各话。
     */
    @GetMapping("/stats")
    @RequireAccess(RequiredAccess.READ)
    public LedgerRangeStatsDto rangeStats(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
            HttpServletRequest request) {
        return ledgerService.rangeStats(AuthInterceptor.requireUserId(request), from, to);
    }

    @GetMapping("/trend")
    @RequireAccess(RequiredAccess.READ)
    public LedgerTrendDto trend(@RequestParam(defaultValue = "7") int days, HttpServletRequest request) {
        return ledgerService.trend(AuthInterceptor.requireUserId(request), days);
    }

    // ── 预算 ──────────────────────────────────────────

    @GetMapping("/budgets")
    @RequireAccess(RequiredAccess.READ)
    public BudgetDto budget(@RequestParam(required = false) String month, HttpServletRequest request) {
        return ledgerService.budget(AuthInterceptor.requireUserId(request), month);
    }

    @PutMapping("/budgets")
    @RequireAccess(RequiredAccess.WRITE)
    public BudgetDto upsertBudget(@Valid @RequestBody UpsertBudgetRequest req, HttpServletRequest request) {
        return ledgerService.upsertBudget(AuthInterceptor.requireUserId(request), req);
    }

    @DeleteMapping("/budgets/{categoryId}")
    @RequireAccess(RequiredAccess.WRITE)
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteBudget(@PathVariable short categoryId, @RequestParam String month, HttpServletRequest request) {
        ledgerService.deleteBudget(AuthInterceptor.requireUserId(request), categoryId, month);
    }
}
