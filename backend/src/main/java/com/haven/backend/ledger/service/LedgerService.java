package com.haven.backend.ledger.service;

import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerAliasDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerAliasPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerBatchDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerQuickCommitDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerSummaryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerTrendDto;
import com.haven.backend.ledger.dto.QuickCommitRequest;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 记账服务。
 * <p>
 * 所有返回值都是有名字的 DTO（见 {@code LedgerDtos}），不再使用 {@code Map<String,Object>}，
 * 让接口契约在编译期可校验、可演进。
 */
public interface LedgerService {

    /** 解析手机端输入，不落库。 */
    QuickParseResult quickParse(String userId, String text);

    /** 快捷指令一步记账：解析并直接写入；没有条目时不写库，只回传逐行 errors。 */
    LedgerQuickCommitDto quickCommit(String userId, QuickCommitRequest req);

    /** 幂等写入一个记账批次。 */
    LedgerBatchDto createBatch(String userId, CreateLedgerBatchRequest req);

    /** 查看批次及其条目。 */
    LedgerBatchDto getBatch(String userId, String batchId);

    /** 按条件分页查询条目。 */
    LedgerEntryPage listEntries(
            String userId, String type, String category, OffsetDateTime from, OffsetDateTime to, int limit, int offset);

    /** 条目详情。 */
    LedgerEntryDto getEntry(String userId, UUID entryId);

    /** 事后修正分类 / 金额 / 发生时间。 */
    LedgerEntryDto updateEntry(String userId, UUID entryId, UpdateLedgerEntryRequest req);

    /** 删除条目。 */
    void deleteEntry(String userId, UUID entryId);

    /** 最近录入的条目（按 created_at 倒序）。 */
    LedgerEntryPage recentEntries(String userId, int limit);

    /** 指定月份的总额、分类排行、按天走势与最近 3 笔。 */
    LedgerSummaryDto summary(String userId, String month);

    /** 最近 N 天的总额、分类排行与按天走势（仪表盘用）。 */
    LedgerTrendDto trend(String userId, int days);

    /** 别名列表。 */
    LedgerAliasPage listAliases(String userId);

    /** 新增或更新别名。 */
    LedgerAliasDto upsertAlias(String userId, UpsertLedgerAliasRequest req);

    /** 删除别名。 */
    void deleteAlias(String userId, String alias);

    /** 支持的分类。 */
    List<String> categories();
}
