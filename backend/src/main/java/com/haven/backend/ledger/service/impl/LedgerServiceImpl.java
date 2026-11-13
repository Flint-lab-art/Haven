package com.haven.backend.ledger.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.ledger.dto.CreateLedgerBatchRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.LedgerParseError;
import com.haven.backend.ledger.dto.ParsedLedgerItem;
import com.haven.backend.ledger.dto.QuickCommitRequest;
import com.haven.backend.ledger.dto.QuickParseResult;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertLedgerAliasRequest;
import com.haven.backend.ledger.entity.LedgerAliases;
import com.haven.backend.ledger.entity.LedgerBatches;
import com.haven.backend.ledger.entity.LedgerEntries;
import com.haven.backend.ledger.mapper.LedgerAliasesMapper;
import com.haven.backend.ledger.mapper.LedgerBatchesMapper;
import com.haven.backend.ledger.mapper.LedgerEntriesMapper;
import com.haven.backend.ledger.service.LedgerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LedgerServiceImpl implements LedgerService {

    /** 支出大类。 */
    public static final List<String> EXPENSE_CATEGORIES = List.of(
            "餐饮", "购物", "交通", "居家", "娱乐", "医疗", "未分类");

    /** 收入大类：与支出共用单层 category 字段，用 type 区分方向。 */
    public static final List<String> INCOME_CATEGORIES = List.of(
            "工资", "奖金", "报销", "退款", "红包", "其他收入");

    /** 所有允许的分类（支出 + 收入）。 */
    public static final List<String> CATEGORIES = List.of(
            "餐饮", "购物", "交通", "居家", "娱乐", "医疗", "未分类",
            "工资", "奖金", "报销", "退款", "红包", "其他收入");

    public static final List<String> TYPES = List.of("expense", "income");

    private static final Set<String> CATEGORY_SET = Set.copyOf(CATEGORIES);
    private static final Set<String> INCOME_CATEGORY_SET = Set.copyOf(INCOME_CATEGORIES);

    /**
     * 未命中别名、但文本里出现这些词时也判为收入。
     * 覆盖「工资到账 10000」「公司报销 320」这类备注写法。
     */
    private static final Set<String> INCOME_KEYWORDS = Set.of(
            "工资", "薪水", "薪资", "月薪", "发工资",
            "奖金", "年终奖", "提成", "绩效",
            "报销", "报账",
            "退款", "退钱", "退费", "退回",
            "红包", "压岁钱", "礼金", "收礼",
            "利息", "分红", "理财收益", "兼职", "外快", "卖二手",
            "收入");

    /** 行末阿拉伯数字金额：12 / 12.5 / 32元 / ¥32。 */
    private static final Pattern ARABIC_AMOUNT = Pattern.compile(
            "(?<![\\d.])(?:[¥￥]\\s*)?(\\d+(?:\\.\\d{1,2})?)\\s*(?:元|块|圆|人民币)?\\s*$");

    /** 行末中文数字金额：二十五块 / 十二点五元。 */
    private static final Pattern CHINESE_AMOUNT = Pattern.compile(
            "([零〇一二两三四五六七八九十百千万亿]+(?:点[零〇一二两三四五六七八九]+)?)"
                    + "\\s*(?:元|块|圆|人民币)?\\s*$");

    private static final Map<Character, Integer> CN_DIGITS = Map.ofEntries(
            Map.entry('零', 0), Map.entry('〇', 0),
            Map.entry('一', 1), Map.entry('二', 2), Map.entry('两', 2),
            Map.entry('三', 3), Map.entry('四', 4), Map.entry('五', 5),
            Map.entry('六', 6), Map.entry('七', 7), Map.entry('八', 8),
            Map.entry('九', 9));

    private static final Map<Character, Integer> CN_UNITS = Map.of(
            '十', 10, '百', 100, '千', 1_000, '万', 10_000, '亿', 100_000_000);

    private final LedgerBatchesMapper batchesMapper;
    private final LedgerEntriesMapper entriesMapper;
    private final LedgerAliasesMapper aliasesMapper;

    // -----------------------------------------------------------------------
    // 快捷输入解析
    // -----------------------------------------------------------------------

    @Override
    public QuickParseResult quickParse(String userId, String text) {
        UUID uid = UUID.fromString(userId);
        Map<String, String> aliases = loadAliases(uid);
        OffsetDateTime now = OffsetDateTime.now();

        List<ParsedLedgerItem> items = new ArrayList<>();
        List<LedgerParseError> errors = new ArrayList<>();
        String[] lines = text.split("\\R", -1);

        for (int i = 0; i < lines.length; i++) {
            String raw = lines[i].trim();
            if (raw.isEmpty()) {
                continue;
            }

            int lineNo = i + 1;
            AmountMatch match;
            try {
                match = extractAmount(raw);
            } catch (IllegalArgumentException e) {
                errors.add(new LedgerParseError(lineNo, raw, e.getMessage()));
                continue;
            }

            if (match == null) {
                errors.add(new LedgerParseError(lineNo, raw, "未找到金额"));
                continue;
            }
            if (match.amountCents() <= 0) {
                errors.add(new LedgerParseError(lineNo, raw, "金额必须大于 0"));
                continue;
            }

            items.add(buildItem(raw, lineNo, match.remaining(), match.amountCents(), aliases, now));
        }

        return new QuickParseResult(items, errors);
    }

    private ParsedLedgerItem buildItem(String raw, int line, String remaining, long amountCents,
            Map<String, String> aliases, OffsetDateTime now) {
        String categoryToken;
        String rest;
        int split = firstWhitespace(remaining);
        if (split >= 0) {
            categoryToken = remaining.substring(0, split).trim();
            rest = remaining.substring(split + 1).trim();
        } else {
            categoryToken = remaining.trim();
            rest = "";
        }

        String category;
        String note;
        String aliasCategory = aliases.get(categoryToken);
        if (aliasCategory != null) {
            // 别名命中：原词并入备注，category 使用翻译后的大类。
            category = aliasCategory;
            note = join(categoryToken, rest);
        } else if (CATEGORY_SET.contains(categoryToken)) {
            category = categoryToken;
            note = rest;
        } else {
            // 未知词：落入未分类，原词保留在备注中，方便之后人工归类。
            category = "未分类";
            note = join(categoryToken, rest);
        }

        String type = INCOME_CATEGORY_SET.contains(category) || containsIncomeKeyword(remaining)
                ? "income"
                : "expense";
        return new ParsedLedgerItem(line, raw, type, amountCents, category, note, now);
    }

    private AmountMatch extractAmount(String line) {
        Matcher arabic = ARABIC_AMOUNT.matcher(line);
        if (arabic.find()) {
            return new AmountMatch(parseArabicCents(arabic.group(1)),
                    line.substring(0, arabic.start()).trim());
        }

        Matcher chinese = CHINESE_AMOUNT.matcher(line);
        if (chinese.find()) {
            return new AmountMatch(parseChineseCents(chinese.group(1)),
                    line.substring(0, chinese.start()).trim());
        }
        return null;
    }

    private long parseArabicCents(String value) {
        try {
            return toCents(new BigDecimal(value));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("金额格式不正确");
        }
    }

    private long parseChineseCents(String value) {
        String[] parts = value.split("点", 2);
        long integer = parseChineseInteger(parts[0]);

        BigDecimal amount = BigDecimal.valueOf(integer);
        if (parts.length == 2) {
            StringBuilder decimals = new StringBuilder();
            for (char c : parts[1].toCharArray()) {
                Integer digit = CN_DIGITS.get(c);
                if (digit == null) {
                    throw new IllegalArgumentException("金额格式不正确");
                }
                decimals.append(digit);
            }
            if (decimals.isEmpty()) {
                throw new IllegalArgumentException("金额格式不正确");
            }
            amount = amount.add(new BigDecimal("0." + decimals));
        }
        return toCents(amount);
    }

    private long parseChineseInteger(String value) {
        long total = 0;
        long section = 0;
        long number = 0;

        for (char c : value.toCharArray()) {
            Integer digit = CN_DIGITS.get(c);
            if (digit != null) {
                number = digit;
                continue;
            }

            Integer unit = CN_UNITS.get(c);
            if (unit == null) {
                throw new IllegalArgumentException("金额格式不正确");
            }

            if (unit >= 10_000) {
                section += number;
                if (section == 0) {
                    section = 1;
                }
                total += section * unit;
                section = 0;
                number = 0;
            } else {
                if (number == 0) {
                    number = 1;
                }
                section += number * unit;
                number = 0;
            }
        }
        return total + section + number;
    }

    private long toCents(BigDecimal value) {
        try {
            return value.movePointRight(2)
                    .setScale(0, RoundingMode.UNNECESSARY)
                    .longValueExact();
        } catch (ArithmeticException e) {
            throw new IllegalArgumentException("金额最多保留两位小数");
        }
    }

    // -----------------------------------------------------------------------
    // 批次与条目
    // -----------------------------------------------------------------------

    @Override
    @Transactional
    public Map<String, Object> createBatch(String userId, CreateLedgerBatchRequest req) {
        UUID uid = UUID.fromString(userId);
        String batchId = req.batchId().trim();

        if (req.items() == null || req.items().isEmpty()) {
            throw BizException.validation("items 不能为空");
        }
        req.items().forEach(this::validateEntry);

        LedgerBatches batch = new LedgerBatches()
                .setUserId(uid)
                .setBatchId(batchId)
                .setRawText(req.rawText())
                .setCreatedAt(OffsetDateTime.now());

        // 相同 user_id + batch_id 已存在时直接回放，不重复写入条目。
        if (batchesMapper.insertIfAbsent(batch) == 0) {
            return buildBatchResult(uid, batchId, false);
        }

        OffsetDateTime now = OffsetDateTime.now();
        for (CreateLedgerEntryRequest item : req.items()) {
            LedgerEntries entry = new LedgerEntries()
                    .setId(UUID.randomUUID())
                    .setUserId(uid)
                    .setType(item.type())
                    .setAmountCents(item.amountCents())
                    .setCategory(item.category())
                    .setNote(item.note() != null ? item.note() : "")
                    .setOccurredAt(item.occurredAt() != null ? item.occurredAt() : now)
                    .setBatchId(batchId)
                    .setCreatedAt(now);
            entriesMapper.insert(entry);
        }

        return buildBatchResult(uid, batchId, true);
    }

    @Override
    @Transactional
    public Map<String, Object> quickCommit(String userId, QuickCommitRequest req) {
        QuickParseResult parsed = quickParse(userId, req.text());
        String batchId = hasText(req.batchId())
                ? req.batchId().trim()
                : UUID.randomUUID().toString();

        // 一行也没解析出来时不写空批次，只回传错误，方便快捷指令直接展示。
        if (parsed.items().isEmpty()) {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("created", false);
            result.put("batch_id", batchId);
            result.put("raw_text", req.text());
            result.put("items", List.of());
            result.put("total", 0);
            result.put("errors", parsed.errors());
            return result;
        }

        List<CreateLedgerEntryRequest> items = parsed.items().stream()
                .map(p -> new CreateLedgerEntryRequest(
                        p.type(), p.amountCents(), p.category(), p.note(), p.occurredAt()))
                .toList();

        Map<String, Object> result = createBatch(userId,
                new CreateLedgerBatchRequest(batchId, req.text(), items));
        result.put("errors", parsed.errors());
        return result;
    }

    @Override
    public Map<String, Object> getBatch(String userId, String batchId) {
        UUID uid = UUID.fromString(userId);
        return buildBatchResult(uid, batchId.trim(), null);
    }

    @Override
    public Map<String, Object> listEntries(String userId, String type, String category,
            OffsetDateTime from, OffsetDateTime to, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        validateRange(from, to);

        int lim = Math.min(Math.max(limit, 1), 100);
        int off = Math.max(offset, 0);

        LambdaQueryWrapper<LedgerEntries> wrapper = filtered(uid, type, category, from, to);
        long total = entriesMapper.selectCount(wrapper);

        wrapper.orderByDesc(LedgerEntries::getOccurredAt)
                .orderByDesc(LedgerEntries::getCreatedAt)
                .last("LIMIT " + lim + " OFFSET " + off);
        List<LedgerEntries> entries = entriesMapper.selectList(wrapper);

        List<Map<String, Object>> items = entries.stream().map(this::toEntryMap).toList();
        return Map.of("items", items, "total", total);
    }

    @Override
    public Map<String, Object> getEntry(String userId, UUID entryId) {
        return toEntryMap(getOwned(UUID.fromString(userId), entryId));
    }

    @Override
    @Transactional
    public Map<String, Object> updateEntry(String userId, UUID entryId, UpdateLedgerEntryRequest req) {
        UUID uid = UUID.fromString(userId);
        LedgerEntries entry = getOwned(uid, entryId);

        if (req.category() != null) {
            validateCategory(req.category());
            entry.setCategory(req.category());
            // 人工归类时顺便把原词写入别名表，下次输入即可直接命中。
            upsertAliasFromNote(uid, entry.getNote(), req.category());
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
        return toEntryMap(entry);
    }

    @Override
    @Transactional
    public void deleteEntry(String userId, UUID entryId) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, entryId);
        entriesMapper.deleteById(entryId);
    }

    @Override
    public Map<String, Object> recentEntries(String userId, int limit) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.min(Math.max(limit, 1), 100);

        List<LedgerEntries> entries = entriesMapper.selectList(
                new LambdaQueryWrapper<LedgerEntries>()
                        .eq(LedgerEntries::getUserId, uid)
                        .orderByDesc(LedgerEntries::getCreatedAt)
                        .last("LIMIT " + lim));

        List<Map<String, Object>> items = entries.stream().map(this::toEntryMap).toList();
        return Map.of("items", items, "total", items.size());
    }

    // -----------------------------------------------------------------------
    // 汇总
    // -----------------------------------------------------------------------

    @Override
    public Map<String, Object> summary(String userId, String month) {
        UUID uid = UUID.fromString(userId);
        YearMonth targetMonth = parseMonth(month);
        ZoneId zone = ZoneId.systemDefault();

        OffsetDateTime from = targetMonth.atDay(1).atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = targetMonth.plusMonths(1).atDay(1).atStartOfDay(zone).toOffsetDateTime();

        List<LedgerEntries> entries = entriesMapper.selectList(
                filtered(uid, null, null, from, to));

        List<LocalDate> dates = new ArrayList<>();
        for (int day = 1; day <= targetMonth.lengthOfMonth(); day++) {
            dates.add(targetMonth.atDay(day));
        }

        List<LedgerEntries> recent = entriesMapper.selectList(
                new LambdaQueryWrapper<LedgerEntries>()
                        .eq(LedgerEntries::getUserId, uid)
                        .orderByDesc(LedgerEntries::getCreatedAt)
                        .last("LIMIT 3"));

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("month", targetMonth.toString());
        result.put("from", from);
        result.put("to", to);
        result.putAll(windowStats(entries, dates, zone));
        result.put("recent", recent.stream().map(this::toEntryMap).toList());
        return result;
    }

    @Override
    public Map<String, Object> trend(String userId, int days) {
        UUID uid = UUID.fromString(userId);
        int span = Math.min(Math.max(days, 1), 90);
        ZoneId zone = ZoneId.systemDefault();

        LocalDate end = LocalDate.now(zone);
        LocalDate start = end.minusDays(span - 1L);
        OffsetDateTime from = start.atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = end.plusDays(1).atStartOfDay(zone).toOffsetDateTime();

        List<LedgerEntries> entries = entriesMapper.selectList(
                filtered(uid, null, null, from, to));

        List<LocalDate> dates = start.datesUntil(end.plusDays(1)).toList();

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("days", span);
        result.put("from", from);
        result.put("to", to);
        result.putAll(windowStats(entries, dates, zone));
        return result;
    }

    /**
     * 一个时间窗口内的统计：总额、支出 / 收入分类排行、按天走势。
     * <p>
     * {@code dates} 决定按天序列的范围，并负责补零；窗口外（理论上不会出现）的条目只计入总额。
     */
    private Map<String, Object> windowStats(List<LedgerEntries> entries, List<LocalDate> dates,
            ZoneId zone) {
        long totalExpense = 0;
        long totalIncome = 0;
        Map<String, long[]> expenseRanking = new LinkedHashMap<>();
        Map<String, long[]> incomeRanking = new LinkedHashMap<>();

        Map<LocalDate, long[]> daily = new LinkedHashMap<>();
        for (LocalDate date : dates) {
            daily.put(date, new long[3]); // [支出, 收入, 笔数]
        }

        for (LedgerEntries entry : entries) {
            long cents = entry.getAmountCents() == null ? 0 : entry.getAmountCents();
            boolean income = "income".equals(entry.getType());

            if (income) {
                totalIncome += cents;
                accumulate(incomeRanking, entry);
            } else {
                totalExpense += cents;
                accumulate(expenseRanking, entry);
            }

            if (entry.getOccurredAt() == null) {
                continue;
            }
            long[] bucket = daily.get(entry.getOccurredAt().atZoneSameInstant(zone).toLocalDate());
            if (bucket == null) {
                continue;
            }
            if (income) {
                bucket[1] += cents;
            } else {
                bucket[0] += cents;
            }
            bucket[2]++;
        }

        List<Map<String, Object>> points = daily.entrySet().stream().map(e -> {
            Map<String, Object> point = new LinkedHashMap<>();
            point.put("date", e.getKey().toString());
            point.put("expense_cents", e.getValue()[0]);
            point.put("income_cents", e.getValue()[1]);
            point.put("count", e.getValue()[2]);
            return point;
        }).toList();

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("total_expense_cents", totalExpense);
        stats.put("total_income_cents", totalIncome);
        stats.put("total_count", entries.size());
        stats.put("category_ranking", toRanking(expenseRanking));
        stats.put("income_category_ranking", toRanking(incomeRanking));
        stats.put("daily", points);
        return stats;
    }

    private void accumulate(Map<String, long[]> ranking, LedgerEntries entry) {
        long[] bucket = ranking.computeIfAbsent(entry.getCategory(), k -> new long[2]);
        bucket[0] += entry.getAmountCents();
        bucket[1]++;
    }

    private List<Map<String, Object>> toRanking(Map<String, long[]> ranking) {
        return ranking.entrySet().stream()
                .sorted((a, b) -> {
                    int byAmount = Long.compare(b.getValue()[0], a.getValue()[0]);
                    return byAmount != 0 ? byAmount : a.getKey().compareTo(b.getKey());
                })
                .map(e -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("category", e.getKey());
                    item.put("amount_cents", e.getValue()[0]);
                    item.put("count", e.getValue()[1]);
                    return item;
                })
                .toList();
    }

    private YearMonth parseMonth(String month) {
        if (!hasText(month)) {
            return YearMonth.now();
        }
        try {
            return YearMonth.parse(month.trim());
        } catch (DateTimeParseException e) {
            throw BizException.validation("month 格式必须为 YYYY-MM");
        }
    }

    // -----------------------------------------------------------------------
    // 别名
    // -----------------------------------------------------------------------

    @Override
    public Map<String, Object> listAliases(String userId) {
        UUID uid = UUID.fromString(userId);
        List<LedgerAliases> aliases = aliasesMapper.selectList(
                new LambdaQueryWrapper<LedgerAliases>()
                        .eq(LedgerAliases::getUserId, uid)
                        .orderByAsc(LedgerAliases::getAlias));

        List<Map<String, Object>> items = aliases.stream().map(a -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("alias", a.getAlias());
            item.put("category", a.getCategory());
            return item;
        }).toList();
        return Map.of("items", items, "total", items.size());
    }

    @Override
    public Map<String, Object> upsertAlias(String userId, UpsertLedgerAliasRequest req) {
        UUID uid = UUID.fromString(userId);
        String alias = req.alias().trim();
        validateCategory(req.category());
        aliasesMapper.upsert(uid, alias, req.category());
        return Map.of("alias", alias, "category", req.category());
    }

    @Override
    @Transactional
    public void deleteAlias(String userId, String alias) {
        UUID uid = UUID.fromString(userId);
        String value = alias.trim();
        int deleted = aliasesMapper.delete(
                new LambdaQueryWrapper<LedgerAliases>()
                        .eq(LedgerAliases::getUserId, uid)
                        .eq(LedgerAliases::getAlias, value));
        if (deleted == 0) {
            throw BizException.notFound("别名不存在");
        }
    }

    @Override
    public List<String> categories() {
        return CATEGORIES;
    }

    // -----------------------------------------------------------------------
    // 内部工具
    // -----------------------------------------------------------------------

    private Map<String, String> loadAliases(UUID userId) {
        return aliasesMapper.selectList(
                new LambdaQueryWrapper<LedgerAliases>()
                        .eq(LedgerAliases::getUserId, userId))
                .stream()
                .collect(Collectors.toMap(
                        LedgerAliases::getAlias,
                        LedgerAliases::getCategory,
                        (first, second) -> second));
    }

    private void upsertAliasFromNote(UUID userId, String note, String category) {
        if (!hasText(note) || "未分类".equals(category)) {
            return;
        }
        String token = firstToken(note);
        if (!hasText(token) || token.length() > 64 || CATEGORY_SET.contains(token)) {
            return;
        }
        aliasesMapper.upsert(userId, token, category);
    }

    private LambdaQueryWrapper<LedgerEntries> filtered(UUID userId, String type, String category,
            OffsetDateTime from, OffsetDateTime to) {
        LambdaQueryWrapper<LedgerEntries> wrapper = new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getUserId, userId);
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

    private Map<String, Object> buildBatchResult(UUID userId, String batchId, Boolean created) {
        LedgerBatches batch = batchesMapper.selectOne(
                new LambdaQueryWrapper<LedgerBatches>()
                        .eq(LedgerBatches::getUserId, userId)
                        .eq(LedgerBatches::getBatchId, batchId));
        if (batch == null) {
            throw BizException.notFound("记账批次不存在");
        }

        List<LedgerEntries> entries = entriesMapper.selectList(
                new LambdaQueryWrapper<LedgerEntries>()
                        .eq(LedgerEntries::getUserId, userId)
                        .eq(LedgerEntries::getBatchId, batchId)
                        .orderByAsc(LedgerEntries::getCreatedAt));

        List<Map<String, Object>> items = entries.stream().map(this::toEntryMap).toList();

        Map<String, Object> result = new LinkedHashMap<>();
        if (created != null) {
            result.put("created", created);
        }
        result.put("batch_id", batch.getBatchId());
        result.put("raw_text", batch.getRawText());
        result.put("created_at", batch.getCreatedAt());
        result.put("items", items);
        result.put("total", items.size());
        return result;
    }

    private LedgerEntries getOwned(UUID userId, UUID entryId) {
        LedgerEntries entry = entriesMapper.selectById(entryId);
        if (entry == null || !entry.getUserId().equals(userId)) {
            throw BizException.notFound("记账条目不存在");
        }
        return entry;
    }

    private void validateEntry(CreateLedgerEntryRequest item) {
        if (!TYPES.contains(item.type())) {
            throw BizException.validation("type 只能是 expense 或 income");
        }
        if (item.amountCents() == null || item.amountCents() <= 0) {
            throw BizException.validation("amount_cents 必须大于 0");
        }
        validateCategory(item.category());
    }

    private void validateCategory(String category) {
        if (!CATEGORY_SET.contains(category)) {
            throw BizException.validation("不支持的分类：" + category);
        }
    }

    private void validateRange(OffsetDateTime from, OffsetDateTime to) {
        if (from != null && to != null && !to.isAfter(from)) {
            throw BizException.validation("to 必须晚于 from");
        }
    }

    private Map<String, Object> toEntryMap(LedgerEntries entry) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", entry.getId().toString());
        item.put("type", entry.getType());
        item.put("amount_cents", entry.getAmountCents());
        item.put("category", entry.getCategory());
        item.put("note", entry.getNote());
        item.put("occurred_at", entry.getOccurredAt());
        item.put("batch_id", entry.getBatchId());
        item.put("created_at", entry.getCreatedAt());
        return item;
    }

    private boolean containsIncomeKeyword(String text) {
        return INCOME_KEYWORDS.stream().anyMatch(text::contains);
    }

    private int firstWhitespace(String value) {
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            if (Character.isWhitespace(c) || c == '\u3000') {
                return i;
            }
        }
        return -1;
    }

    private String firstToken(String value) {
        int split = firstWhitespace(value);
        return split >= 0 ? value.substring(0, split) : value;
    }

    private String join(String first, String second) {
        if (!hasText(second)) {
            return first;
        }
        return first + " " + second;
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private record AmountMatch(long amountCents, String remaining) {
    }
}
