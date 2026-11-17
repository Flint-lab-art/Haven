package com.haven.backend.ledger.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerAliasDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerAliasPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerBatchDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerQuickCommitDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerSummaryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerTrendDto;
import com.haven.backend.ledger.dto.ParsedLedgerItem;
import com.haven.backend.ledger.dto.QuickCommitRequest;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import com.haven.backend.ledger.entity.LedgerAliases;
import com.haven.backend.ledger.entity.LedgerBatches;
import com.haven.backend.ledger.entity.LedgerCategories;
import com.haven.backend.ledger.entity.LedgerEntries;
import com.haven.backend.ledger.entity.LedgerTypes;
import com.haven.backend.ledger.mapper.LedgerAliasesMapper;
import com.haven.backend.ledger.mapper.LedgerBatchesMapper;
import com.haven.backend.ledger.mapper.LedgerEntriesMapper;
import com.haven.backend.ledger.service.LedgerClassifier;
import com.haven.backend.ledger.service.LedgerService;
import com.haven.backend.ledger.service.LedgerStatsCalculator;
import com.haven.backend.ledger.service.LedgerTextParser;
import java.time.Clock;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 记账服务实现。
 * <p>
 * 只负责「编排」：数据库读写、事务边界、权限校验、参数收敛。
 * 具体职责拆到三个协作类：
 * <ul>
 *   <li>{@link LedgerTextParser}：快捷输入的语法解析（金额、日期），无数据库依赖；</li>
 *   <li>{@link LedgerClassifier}：分类 / 方向 / 备注的判定规则；</li>
 *   <li>{@link LedgerStatsCalculator}：总额、分类排行、按天走势的纯计算。</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class LedgerServiceImpl implements LedgerService {

    /** 列表接口的分页上限。 */
    private static final int MAX_PAGE_SIZE = 100;
    /** 最近条目默认条数。 */
    private static final int RECENT_LIMIT = 3;
    /** 趋势窗口上限（天）。 */
    private static final int MAX_TREND_DAYS = 90;
    /** 别名长度上限，超过则不参与学习。 */
    private static final int MAX_ALIAS_LENGTH = 64;

    private final LedgerBatchesMapper batchesMapper;
    private final LedgerEntriesMapper entriesMapper;
    private final LedgerAliasesMapper aliasesMapper;
    private final LedgerTextParser parser;
    private final LedgerClassifier classifier;
    private final LedgerStatsCalculator statsCalculator;
    private final Clock clock;

    // -----------------------------------------------------------------------
    // 快捷输入
    // -----------------------------------------------------------------------

    @Override
    public QuickParseResult quickParse(String userId, String text) {
        LedgerTextParser.Result result =
                parser.parse(text, loadAliases(UUID.fromString(userId)), OffsetDateTime.now(clock));
        return new QuickParseResult(result.items(), result.errors());
    }

    @Override
    @Transactional
    public LedgerQuickCommitDto quickCommit(String userId, QuickCommitRequest req) {
        QuickParseResult parsed = quickParse(userId, req.text());
        String batchId = hasText(req.batchId())
                ? req.batchId().trim()
                : UUID.randomUUID().toString();

        // 一行也没解析出来时不写空批次，只回传错误，方便快捷指令直接展示。
        if (parsed.items().isEmpty()) {
            LedgerBatchDto empty = new LedgerBatchDto(false, batchId, req.text(), null, List.of(), 0);
            return new LedgerQuickCommitDto(empty, parsed.errors());
        }

        List<CreateLedgerEntryRequest> items =
                parsed.items().stream().map(this::toCreateRequest).toList();
        LedgerBatchDto batch = createBatch(userId, new CreateLedgerBatchRequest(batchId, req.text(), items));
        return new LedgerQuickCommitDto(batch, parsed.errors());
    }

    private CreateLedgerEntryRequest toCreateRequest(ParsedLedgerItem p) {
        return new CreateLedgerEntryRequest(p.type(), p.amountCents(), p.category(), p.note(), p.occurredAt());
    }

    // -----------------------------------------------------------------------
    // 批次
    // -----------------------------------------------------------------------

    @Override
    @Transactional
    public LedgerBatchDto createBatch(String userId, CreateLedgerBatchRequest req) {
        UUID uid = UUID.fromString(userId);
        String batchId = req.batchId().trim();

        if (req.items() == null || req.items().isEmpty()) {
            throw BizException.validation("items 不能为空");
        }
        req.items().forEach(this::validateEntry);

        OffsetDateTime now = OffsetDateTime.now(clock);
        LedgerBatches batch = new LedgerBatches()
                .setUserId(uid)
                .setBatchId(batchId)
                .setRawText(req.rawText())
                .setCreatedAt(now);

        // 相同 user_id + batch_id 已存在时直接回放，不重复写入条目。
        if (batchesMapper.insertIfAbsent(batch) == 0) {
            return buildBatchDto(uid, batchId, false);
        }

        for (CreateLedgerEntryRequest item : req.items()) {
            entriesMapper.insert(new LedgerEntries()
                    .setId(UUID.randomUUID())
                    .setUserId(uid)
                    .setType(item.type())
                    .setAmountCents(item.amountCents())
                    .setCategory(item.category())
                    .setNote(item.note() != null ? item.note() : "")
                    .setOccurredAt(item.occurredAt() != null ? item.occurredAt() : now)
                    .setBatchId(batchId)
                    .setCreatedAt(now));
        }
        return buildBatchDto(uid, batchId, true);
    }

    @Override
    public LedgerBatchDto getBatch(String userId, String batchId) {
        return buildBatchDto(UUID.fromString(userId), batchId.trim(), null);
    }

    // -----------------------------------------------------------------------
    // 条目
    // -----------------------------------------------------------------------

    @Override
    public LedgerEntryPage listEntries(
            String userId,
            String type,
            String category,
            OffsetDateTime from,
            OffsetDateTime to,
            int limit,
            int offset) {
        UUID uid = UUID.fromString(userId);
        validateRange(from, to);

        LambdaQueryWrapper<LedgerEntries> wrapper = filtered(uid, type, category, from, to);
        long total = entriesMapper.selectCount(wrapper);

        wrapper.orderByDesc(LedgerEntries::getOccurredAt)
                .orderByDesc(LedgerEntries::getCreatedAt)
                .last("LIMIT " + clampLimit(limit) + " OFFSET " + Math.max(offset, 0));
        List<LedgerEntries> entries = entriesMapper.selectList(wrapper);

        return new LedgerEntryPage(entries.stream().map(this::toEntryDto).toList(), total);
    }

    @Override
    public LedgerEntryDto getEntry(String userId, UUID entryId) {
        return toEntryDto(getOwned(UUID.fromString(userId), entryId));
    }

    @Override
    @Transactional
    public LedgerEntryDto updateEntry(String userId, UUID entryId, UpdateLedgerEntryRequest req) {
        UUID uid = UUID.fromString(userId);
        LedgerEntries entry = getOwned(uid, entryId);

        if (req.category() != null) {
            validateCategory(req.category());
            entry.setCategory(req.category());
            // 人工归类时顺便把原词写入别名表，下次输入即可直接命中。
            learnAliasFromNote(uid, entry.getNote(), req.category());
        }
        if (req.amountCents() != null) {
            if (req.amountCents() <= 0) {
                throw BizException.validation("amount_cents 必须大于 0");
            }
            entry.setAmountCents(req.amountCents());
        }
        if (req.occurredAt() != null) {
            entry.setOccurredAt(req.occurredAt());
        }

        entriesMapper.updateById(entry);
        return toEntryDto(entry);
    }

    @Override
    @Transactional
    public void deleteEntry(String userId, UUID entryId) {
        getOwned(UUID.fromString(userId), entryId);
        entriesMapper.deleteById(entryId);
    }

    @Override
    public LedgerEntryPage recentEntries(String userId, int limit) {
        UUID uid = UUID.fromString(userId);
        List<LedgerEntries> entries = entriesMapper.selectList(new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getUserId, uid)
                .orderByDesc(LedgerEntries::getCreatedAt)
                .last("LIMIT " + clampLimit(limit)));

        List<LedgerEntryDto> items = entries.stream().map(this::toEntryDto).toList();
        return new LedgerEntryPage(items, items.size());
    }

    // -----------------------------------------------------------------------
    // 汇总
    // -----------------------------------------------------------------------

    @Override
    public LedgerSummaryDto summary(String userId, String month) {
        UUID uid = UUID.fromString(userId);
        YearMonth targetMonth = parseMonth(month);
        ZoneId zone = clock.getZone();

        OffsetDateTime from = targetMonth.atDay(1).atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to =
                targetMonth.plusMonths(1).atDay(1).atStartOfDay(zone).toOffsetDateTime();

        List<LedgerEntries> entries = entriesMapper.selectList(filtered(uid, null, null, from, to));

        List<LocalDate> dates = new ArrayList<>();
        for (int day = 1; day <= targetMonth.lengthOfMonth(); day++) {
            dates.add(targetMonth.atDay(day));
        }

        List<LedgerEntries> recent = entriesMapper.selectList(new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getUserId, uid)
                .orderByDesc(LedgerEntries::getCreatedAt)
                .last("LIMIT " + RECENT_LIMIT));

        LedgerStatsCalculator.WindowStats stats = statsCalculator.summarize(entries, dates, zone);
        return new LedgerSummaryDto(
                targetMonth.toString(),
                from,
                to,
                stats.totalExpenseCents(),
                stats.totalIncomeCents(),
                stats.totalCount(),
                stats.categoryRanking(),
                stats.incomeCategoryRanking(),
                stats.daily(),
                recent.stream().map(this::toEntryDto).toList());
    }

    @Override
    public LedgerTrendDto trend(String userId, int days) {
        UUID uid = UUID.fromString(userId);
        int span = Math.clamp(days, 1, MAX_TREND_DAYS);
        ZoneId zone = clock.getZone();

        LocalDate end = LocalDate.now(clock);
        LocalDate start = end.minusDays(span - 1L);
        OffsetDateTime from = start.atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = end.plusDays(1).atStartOfDay(zone).toOffsetDateTime();

        List<LedgerEntries> entries = entriesMapper.selectList(filtered(uid, null, null, from, to));
        List<LocalDate> dates = start.datesUntil(end.plusDays(1)).toList();

        LedgerStatsCalculator.WindowStats stats = statsCalculator.summarize(entries, dates, zone);
        return new LedgerTrendDto(
                span,
                from,
                to,
                stats.totalExpenseCents(),
                stats.totalIncomeCents(),
                stats.totalCount(),
                stats.categoryRanking(),
                stats.incomeCategoryRanking(),
                stats.daily());
    }

    // -----------------------------------------------------------------------
    // 别名
    // -----------------------------------------------------------------------

    @Override
    public LedgerAliasPage listAliases(String userId) {
        UUID uid = UUID.fromString(userId);
        List<LedgerAliasDto> items = aliasesMapper
                .selectList(new LambdaQueryWrapper<LedgerAliases>()
                        .eq(LedgerAliases::getUserId, uid)
                        .orderByAsc(LedgerAliases::getAlias))
                .stream()
                .map(a -> new LedgerAliasDto(a.getAlias(), a.getCategory()))
                .toList();
        return new LedgerAliasPage(items, items.size());
    }

    @Override
    @Transactional
    public LedgerAliasDto upsertAlias(String userId, UpsertLedgerAliasRequest req) {
        UUID uid = UUID.fromString(userId);
        String alias = req.alias().trim();
        validateCategory(req.category());
        aliasesMapper.upsert(uid, alias, req.category());
        return new LedgerAliasDto(alias, req.category());
    }

    @Override
    @Transactional
    public void deleteAlias(String userId, String alias) {
        UUID uid = UUID.fromString(userId);
        int deleted = aliasesMapper.delete(new LambdaQueryWrapper<LedgerAliases>()
                .eq(LedgerAliases::getUserId, uid)
                .eq(LedgerAliases::getAlias, alias.trim()));
        if (deleted == 0) {
            throw BizException.notFound("别名不存在");
        }
    }

    @Override
    public List<String> categories() {
        return LedgerCategories.ALL;
    }

    // -----------------------------------------------------------------------
    // 内部
    // -----------------------------------------------------------------------

    private Map<String, String> loadAliases(UUID userId) {
        return aliasesMapper
                .selectList(new LambdaQueryWrapper<LedgerAliases>().eq(LedgerAliases::getUserId, userId))
                .stream()
                .collect(java.util.stream.Collectors.toMap(
                        LedgerAliases::getAlias, LedgerAliases::getCategory, (first, second) -> second));
    }

    /**
     * 人工归类后学习别名。
     * <p>
     * 只在备注首个词不是内置分类、长度合理、且分类不是「未分类」时学习，
     * 避免把「午饭 食堂」里的无关词或超长备注写进别名表。
     */
    private void learnAliasFromNote(UUID userId, String note, String category) {
        if (!hasText(note) || LedgerTextParser.UNCATEGORIZED.equals(category)) {
            return;
        }
        String token = classifier.firstTokenOf(note);
        if (!hasText(token) || token.length() > MAX_ALIAS_LENGTH || LedgerCategories.ALL_SET.contains(token)) {
            return;
        }
        aliasesMapper.upsert(userId, token, category);
    }

    /** 构造查询条件：用户 + 可选方向 / 分类 / 时间区间。 */
    private LambdaQueryWrapper<LedgerEntries> filtered(
            UUID userId, String type, String category, OffsetDateTime from, OffsetDateTime to) {
        LambdaQueryWrapper<LedgerEntries> wrapper =
                new LambdaQueryWrapper<LedgerEntries>().eq(LedgerEntries::getUserId, userId);
        if (hasText(type)) {
            wrapper.eq(LedgerEntries::getType, type);
        }
        if (hasText(category)) {
            wrapper.eq(LedgerEntries::getCategory, category);
        }
        if (from != null) {
            wrapper.ge(LedgerEntries::getOccurredAt, from);
        }
        if (to != null) {
            wrapper.lt(LedgerEntries::getOccurredAt, to);
        }
        return wrapper;
    }

    private LedgerBatchDto buildBatchDto(UUID userId, String batchId, Boolean created) {
        LedgerBatches batch = batchesMapper.selectOne(new LambdaQueryWrapper<LedgerBatches>()
                .eq(LedgerBatches::getUserId, userId)
                .eq(LedgerBatches::getBatchId, batchId));
        if (batch == null) {
            throw BizException.notFound("记账批次不存在");
        }

        List<LedgerEntryDto> items = entriesMapper
                .selectList(new LambdaQueryWrapper<LedgerEntries>()
                        .eq(LedgerEntries::getUserId, userId)
                        .eq(LedgerEntries::getBatchId, batchId)
                        .orderByAsc(LedgerEntries::getCreatedAt))
                .stream()
                .map(this::toEntryDto)
                .toList();

        return new LedgerBatchDto(
                Boolean.TRUE.equals(created),
                batch.getBatchId(),
                batch.getRawText(),
                batch.getCreatedAt(),
                items,
                items.size());
    }

    private LedgerEntries getOwned(UUID userId, UUID entryId) {
        LedgerEntries entry = entriesMapper.selectById(entryId);
        if (entry == null || !entry.getUserId().equals(userId)) {
            throw BizException.notFound("记账条目不存在");
        }
        return entry;
    }

    private void validateEntry(CreateLedgerEntryRequest item) {
        if (!LedgerTypes.ALL.contains(item.type())) {
            throw BizException.validation("type 只能是 expense 或 income");
        }
        if (item.amountCents() == null || item.amountCents() <= 0) {
            throw BizException.validation("amount_cents 必须大于 0");
        }
        validateCategory(item.category());
    }

    private void validateCategory(String category) {
        if (!LedgerCategories.ALL_SET.contains(category)) {
            throw BizException.validation("不支持的分类：" + category);
        }
    }

    private void validateRange(OffsetDateTime from, OffsetDateTime to) {
        if (from != null && to != null && !to.isAfter(from)) {
            throw BizException.validation("to 必须晚于 from");
        }
    }

    private LedgerEntryDto toEntryDto(LedgerEntries entry) {
        return new LedgerEntryDto(
                entry.getId(),
                entry.getType(),
                entry.getAmountCents(),
                entry.getCategory(),
                entry.getNote(),
                entry.getOccurredAt(),
                entry.getBatchId(),
                entry.getCreatedAt());
    }

    private YearMonth parseMonth(String month) {
        if (!hasText(month)) {
            return YearMonth.now(clock);
        }
        try {
            return YearMonth.parse(month.trim());
        } catch (DateTimeParseException e) {
            throw BizException.validation("month 格式必须为 YYYY-MM");
        }
    }

    private static int clampLimit(int limit) {
        return Math.clamp(limit, 1, MAX_PAGE_SIZE);
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
