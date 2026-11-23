package com.haven.backend.ledger.service;

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
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 记账服务。
 * <p>
 * 所有返回值都是有名字的 DTO（见 {@code LedgerDtos}），让接口契约在编译期可校验。
 */
public interface LedgerService {

    // ── 账户 ──────────────────────────────────────────

    List<AccountDto> listAccounts(String userId);

    AccountDto createAccount(String userId, AccountRequest req);

    AccountDto updateAccount(String userId, UUID accountId, AccountRequest req);

    /** 删除账户；已有流水的账户不能删，只能归档。 */
    void deleteAccount(String userId, UUID accountId);

    // ── 分类 ──────────────────────────────────────────

    /** 全部分类（两级树，只含 enabled）。 */
    List<CategoryDto> categoryTree();

    // ── 流水 ──────────────────────────────────────────

    LedgerEntryDto createEntry(String userId, CreateLedgerEntryRequest req);

    LedgerEntryPage listEntries(
            String userId,
            String type,
            Short categoryId,
            UUID accountId,
            OffsetDateTime from,
            OffsetDateTime to,
            int limit,
            int offset);

    LedgerEntryDto getEntry(String userId, UUID entryId);

    LedgerEntryDto updateEntry(String userId, UUID entryId, UpdateLedgerEntryRequest req);

    void deleteEntry(String userId, UUID entryId);

    // ── 统计 ──────────────────────────────────────────

    /** 指定月份的收支合计与按一级分类的拆分。转账不计入。 */
    LedgerSummaryDto summary(String userId, String month);

    /**
     * 任意区间的统计（周 / 月 / 季 / 年均走这里）。
     *
     * 区间由调用方按业务时区算好，后端只做区间聚合。
     */
    LedgerRangeStatsDto rangeStats(String userId, OffsetDateTime from, OffsetDateTime to);

    /** 最近 N 天的收支与按天走势。转账不计入。 */
    LedgerTrendDto trend(String userId, int days);

    // ── 预算 ──────────────────────────────────────────

    BudgetDto budget(String userId, String month);

    BudgetDto upsertBudget(String userId, UpsertBudgetRequest req);

    void deleteBudget(String userId, short categoryId, String month);
}
