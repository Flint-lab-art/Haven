package com.haven.backend.ledger.service;

import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface LedgerService {

    /** 解析手机端输入，不落库。 */
    QuickParseResult quickParse(String userId, String text);

    /** 幂等写入一个记账批次。 */
    Map<String, Object> createBatch(String userId, CreateLedgerBatchRequest req);

    /** 查看批次及其条目。 */
    Map<String, Object> getBatch(String userId, String batchId);

    /** 按条件分页查询条目。 */
    Map<String, Object> listEntries(String userId, String type, String category,
            OffsetDateTime from, OffsetDateTime to, int limit, int offset);

    /** 条目详情。 */
    Map<String, Object> getEntry(String userId, UUID entryId);

    /** 事后修正分类 / 金额 / 发生时间。 */
    Map<String, Object> updateEntry(String userId, UUID entryId, UpdateLedgerEntryRequest req);

    /** 删除条目。 */
    void deleteEntry(String userId, UUID entryId);

    /** 最近录入的条目（按 created_at 倒序）。 */
    Map<String, Object> recentEntries(String userId, int limit);

    /** 指定月份的总额、分类排行、按天走势与最近 3 笔。 */
    Map<String, Object> summary(String userId, String month);

    /** 最近 N 天的总额、分类排行与按天走势（仪表盘用）。 */
    Map<String, Object> trend(String userId, int days);

    /** 别名列表。 */
    Map<String, Object> listAliases(String userId);

    /** 新增或更新别名。 */
    Map<String, Object> upsertAlias(String userId, UpsertLedgerAliasRequest req);

    /** 删除别名。 */
    void deleteAlias(String userId, String alias);

    /** 支持的分类。 */
    List<String> categories();
}
