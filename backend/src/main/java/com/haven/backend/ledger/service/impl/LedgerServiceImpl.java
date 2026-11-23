package com.haven.backend.ledger.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.ledger.dto.AccountRequest;
import com.haven.backend.ledger.dto.CreateLedgerEntryRequest;
import com.haven.backend.ledger.dto.LedgerDtos.AccountDto;
import com.haven.backend.ledger.dto.LedgerDtos.BudgetDto;
import com.haven.backend.ledger.dto.LedgerDtos.BudgetItemDto;
import com.haven.backend.ledger.dto.LedgerDtos.CategoryDto;
import com.haven.backend.ledger.dto.LedgerDtos.CategorySpend;
import com.haven.backend.ledger.dto.LedgerDtos.DailyPoint;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerEntryPage;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerRangeStatsDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerSummaryDto;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerTrendDto;
import com.haven.backend.ledger.dto.UpdateLedgerEntryRequest;
import com.haven.backend.ledger.dto.UpsertBudgetRequest;
import com.haven.backend.ledger.entity.AccountTypes;
import com.haven.backend.ledger.entity.LedgerAccounts;
import com.haven.backend.ledger.entity.LedgerBudgets;
import com.haven.backend.ledger.entity.LedgerCategories;
import com.haven.backend.ledger.entity.LedgerEntries;
import com.haven.backend.ledger.entity.LedgerTypes;
import com.haven.backend.ledger.mapper.LedgerAccountsMapper;
import com.haven.backend.ledger.mapper.LedgerBudgetsMapper;
import com.haven.backend.ledger.mapper.LedgerCategoriesMapper;
import com.haven.backend.ledger.mapper.LedgerEntriesMapper;
import com.haven.backend.ledger.service.LedgerService;
import java.time.Clock;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LedgerServiceImpl implements LedgerService {

    private final LedgerAccountsMapper accountsMapper;
    private final LedgerCategoriesMapper categoriesMapper;
    private final LedgerEntriesMapper entriesMapper;
    private final LedgerBudgetsMapper budgetsMapper;
    private final Clock clock;

    // ── 账户 ──────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<AccountDto> listAccounts(String userId) {
        UUID uid = UUID.fromString(userId);
        Map<UUID, Long> balances = entriesMapper.accountBalances(uid).stream()
                .collect(Collectors.toMap(
                        LedgerEntriesMapper.AccountBalance::id, b -> b.balanceCents() != null ? b.balanceCents() : 0L));

        return accountsMapper
                .selectList(new LambdaQueryWrapper<LedgerAccounts>()
                        .eq(LedgerAccounts::getUserId, uid)
                        .orderByAsc(LedgerAccounts::getSortOrder)
                        .orderByAsc(LedgerAccounts::getName))
                .stream()
                .map(a -> toAccountDto(a, balances.getOrDefault(a.getId(), a.getInitialBalanceCents())))
                .toList();
    }

    @Override
    @Transactional
    public AccountDto createAccount(String userId, AccountRequest req) {
        UUID uid = UUID.fromString(userId);
        requireValidType(req.type());
        requireUniqueName(uid, req.name(), null);

        LedgerAccounts account = new LedgerAccounts()
                .setId(UUID.randomUUID())
                .setUserId(uid)
                .setName(req.name().trim())
                .setIcon(req.icon() != null ? req.icon() : "")
                .setType(req.type())
                .setInitialBalanceCents(req.initialBalanceCents() != null ? req.initialBalanceCents() : 0L)
                .setSortOrder(req.sortOrder() != null ? req.sortOrder() : nextSortOrder(uid))
                .setArchived(false)
                .setCreatedAt(OffsetDateTime.now(clock))
                .setUpdatedAt(OffsetDateTime.now(clock));
        accountsMapper.insert(account);

        // 新账户还没有流水，余额就是期初
        return toAccountDto(account, account.getInitialBalanceCents());
    }

    @Override
    @Transactional
    public AccountDto updateAccount(String userId, UUID accountId, AccountRequest req) {
        UUID uid = UUID.fromString(userId);
        LedgerAccounts existing = requireAccount(uid, accountId);
        requireValidType(req.type());
        requireUniqueName(uid, req.name(), accountId);

        accountsMapper.update(
                null,
                new LambdaUpdateWrapper<LedgerAccounts>()
                        .eq(LedgerAccounts::getId, accountId)
                        .eq(LedgerAccounts::getUserId, uid)
                        .set(LedgerAccounts::getName, req.name().trim())
                        .set(LedgerAccounts::getIcon, req.icon() != null ? req.icon() : "")
                        .set(LedgerAccounts::getType, req.type())
                        .set(
                                LedgerAccounts::getInitialBalanceCents,
                                req.initialBalanceCents() != null
                                        ? req.initialBalanceCents()
                                        : existing.getInitialBalanceCents())
                        .set(
                                LedgerAccounts::getSortOrder,
                                req.sortOrder() != null ? req.sortOrder() : existing.getSortOrder())
                        .set(
                                LedgerAccounts::getArchived,
                                req.archived() != null ? req.archived() : existing.getArchived())
                        .set(LedgerAccounts::getUpdatedAt, OffsetDateTime.now(clock)));

        LedgerAccounts updated = requireAccount(uid, accountId);
        long balance = entriesMapper.accountBalances(uid).stream()
                .filter(b -> b.id().equals(accountId))
                .map(b -> b.balanceCents() != null ? b.balanceCents() : 0L)
                .findFirst()
                .orElse(updated.getInitialBalanceCents());
        return toAccountDto(updated, balance);
    }

    @Override
    @Transactional
    public void deleteAccount(String userId, UUID accountId) {
        UUID uid = UUID.fromString(userId);
        requireAccount(uid, accountId);

        long used = entriesMapper.selectCount(new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getUserId, uid)
                .and(w -> w.eq(LedgerEntries::getAccountId, accountId)
                        .or()
                        .eq(LedgerEntries::getToAccountId, accountId)));
        if (used > 0) {
            throw BizException.conflict("该账户已有 " + used + " 条流水，请改为归档");
        }
        accountsMapper.deleteById(accountId);
    }

    // ── 分类 ──────────────────────────────────────────

    @Override
    public List<CategoryDto> categoryTree() {
        List<LedgerCategories> all = categoriesMapper.selectList(new LambdaQueryWrapper<LedgerCategories>()
                .eq(LedgerCategories::getEnabled, true)
                .orderByAsc(LedgerCategories::getSortOrder)
                .orderByAsc(LedgerCategories::getId));

        Map<Short, List<LedgerCategories>> byParent = all.stream()
                .filter(c -> c.getParentId() != null)
                .collect(Collectors.groupingBy(LedgerCategories::getParentId, LinkedHashMap::new, Collectors.toList()));

        List<CategoryDto> roots = new ArrayList<>();
        for (LedgerCategories root : all) {
            if (root.getParentId() != null) {
                continue;
            }
            List<CategoryDto> children = byParent.getOrDefault(root.getId(), List.of()).stream()
                    .map(c -> new CategoryDto(
                            c.getId(),
                            c.getParentId(),
                            c.getName(),
                            c.getIcon() != null ? c.getIcon() : "",
                            c.getKind(),
                            c.getSortOrder(),
                            List.of()))
                    .toList();
            roots.add(new CategoryDto(
                    root.getId(),
                    null,
                    root.getName(),
                    root.getIcon() != null ? root.getIcon() : "",
                    root.getKind(),
                    root.getSortOrder(),
                    children));
        }
        return roots;
    }

    // ── 流水 ──────────────────────────────────────────

    @Override
    @Transactional
    public LedgerEntryDto createEntry(String userId, CreateLedgerEntryRequest req) {
        UUID uid = UUID.fromString(userId);
        OffsetDateTime now = OffsetDateTime.now(clock);

        LedgerEntries entry = new LedgerEntries()
                .setId(UUID.randomUUID())
                .setUserId(uid)
                .setType(req.type())
                .setAmountCents(req.amountCents())
                .setNote(req.note())
                .setOccurredAt(req.occurredAt() != null ? req.occurredAt() : now)
                .setCreatedAt(now)
                .setUpdatedAt(now);

        if (LedgerTypes.isTransfer(req.type())) {
            if (req.toAccountId() == null) {
                throw BizException.validation("转账必须指定转入账户");
            }
            if (req.toAccountId().equals(req.accountId())) {
                throw BizException.validation("转出与转入账户不能相同");
            }
            if (req.categoryId() != null) {
                throw BizException.validation("转账不能指定分类");
            }
            entry.setAccountId(requireAccountId(uid, req.accountId(), "转出账户"));
            entry.setToAccountId(requireAccountId(uid, req.toAccountId(), "转入账户"));
        } else {
            if (req.toAccountId() != null) {
                throw BizException.validation("只有转账才能指定转入账户");
            }
            if (req.categoryId() == null) {
                throw BizException.validation("支出 / 收入必须指定分类");
            }
            requireCategoryKind(req.categoryId(), req.type());
            entry.setCategoryId(req.categoryId());
            entry.setAccountId(requireAccountId(uid, req.accountId(), "账户"));
        }

        entriesMapper.insert(entry);
        return toEntryDto(entry);
    }

    @Override
    @Transactional(readOnly = true)
    public LedgerEntryPage listEntries(
            String userId,
            String type,
            Short categoryId,
            UUID accountId,
            OffsetDateTime from,
            OffsetDateTime to,
            int limit,
            int offset) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.clamp(limit, 1, 200);
        int off = Math.max(offset, 0);

        LambdaQueryWrapper<LedgerEntries> wrapper =
                new LambdaQueryWrapper<LedgerEntries>().eq(LedgerEntries::getUserId, uid);
        if (type != null && !type.isBlank()) {
            wrapper.eq(LedgerEntries::getType, type);
        }
        if (categoryId != null) {
            // 选一级分类时要把它的二级也带上
            List<Short> ids = new ArrayList<>();
            ids.add(categoryId);
            categoriesMapper
                    .selectList(
                            new LambdaQueryWrapper<LedgerCategories>().eq(LedgerCategories::getParentId, categoryId))
                    .forEach(c -> ids.add(c.getId()));
            wrapper.in(LedgerEntries::getCategoryId, ids);
        }
        if (accountId != null) {
            wrapper.and(w ->
                    w.eq(LedgerEntries::getAccountId, accountId).or().eq(LedgerEntries::getToAccountId, accountId));
        }
        if (from != null) {
            wrapper.ge(LedgerEntries::getOccurredAt, from);
        }
        if (to != null) {
            wrapper.lt(LedgerEntries::getOccurredAt, to);
        }

        long total = entriesMapper.selectCount(wrapper);
        List<LedgerEntries> rows = entriesMapper.selectList(wrapper.orderByDesc(LedgerEntries::getOccurredAt)
                .orderByDesc(LedgerEntries::getCreatedAt)
                .last("LIMIT " + lim + " OFFSET " + off));

        return new LedgerEntryPage(rows.stream().map(this::toEntryDto).toList(), total);
    }

    @Override
    @Transactional(readOnly = true)
    public LedgerEntryDto getEntry(String userId, UUID entryId) {
        return toEntryDto(requireEntry(UUID.fromString(userId), entryId));
    }

    @Override
    @Transactional
    public LedgerEntryDto updateEntry(String userId, UUID entryId, UpdateLedgerEntryRequest req) {
        UUID uid = UUID.fromString(userId);
        LedgerEntries existing = requireEntry(uid, entryId);

        String type = req.type() != null ? req.type() : existing.getType();
        long amount = req.amountCents() != null ? req.amountCents() : existing.getAmountCents();
        OffsetDateTime occurredAt = req.occurredAt() != null ? req.occurredAt() : existing.getOccurredAt();
        UUID accountId = req.accountId() != null ? req.accountId() : existing.getAccountId();
        String note = req.note() != null ? req.note() : existing.getNote();

        var update = new LambdaUpdateWrapper<LedgerEntries>()
                .eq(LedgerEntries::getId, entryId)
                .eq(LedgerEntries::getUserId, uid)
                .set(LedgerEntries::getType, type)
                .set(LedgerEntries::getAmountCents, amount)
                .set(LedgerEntries::getOccurredAt, occurredAt)
                .set(LedgerEntries::getNote, note)
                .set(LedgerEntries::getUpdatedAt, OffsetDateTime.now(clock));

        if (LedgerTypes.isTransfer(type)) {
            UUID toAccountId = req.toAccountId() != null ? req.toAccountId() : existing.getToAccountId();
            if (toAccountId == null) {
                throw BizException.validation("转账必须指定转入账户");
            }
            if (toAccountId.equals(accountId)) {
                throw BizException.validation("转出与转入账户不能相同");
            }
            update.set(LedgerEntries::getAccountId, requireAccountId(uid, accountId, "转出账户"))
                    .set(LedgerEntries::getToAccountId, requireAccountId(uid, toAccountId, "转入账户"))
                    // 转账没有分类，必须显式清空，否则 outline 里留着旧值
                    .set(LedgerEntries::getCategoryId, null);
        } else {
            Short categoryId = req.categoryId() != null ? req.categoryId() : existing.getCategoryId();
            if (categoryId == null) {
                throw BizException.validation("支出 / 收入必须指定分类");
            }
            requireCategoryKind(categoryId, type);
            update.set(LedgerEntries::getCategoryId, categoryId)
                    .set(LedgerEntries::getAccountId, requireAccountId(uid, accountId, "账户"))
                    // 改回支出 / 收入时清掉转入账户
                    .set(LedgerEntries::getToAccountId, null);
        }

        entriesMapper.update(null, update);
        return toEntryDto(requireEntry(uid, entryId));
    }

    @Override
    @Transactional
    public void deleteEntry(String userId, UUID entryId) {
        UUID uid = UUID.fromString(userId);
        requireEntry(uid, entryId);
        entriesMapper.deleteById(entryId);
    }

    // ── 统计 ──────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public LedgerSummaryDto summary(String userId, String month) {
        UUID uid = UUID.fromString(userId);
        YearMonth ym = parseMonth(month);
        ZoneId zone = clock.getZone();
        OffsetDateTime from = ym.atDay(1).atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = ym.plusMonths(1).atDay(1).atStartOfDay(zone).toOffsetDateTime();

        Map<Short, String> names = rootCategoryNames();

        List<LedgerEntries> rows = entriesMapper.selectList(new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getUserId, uid)
                .ge(LedgerEntries::getOccurredAt, from)
                .lt(LedgerEntries::getOccurredAt, to));

        long expense = rows.stream()
                .filter(e -> LedgerTypes.EXPENSE.equals(e.getType()))
                .mapToLong(LedgerEntries::getAmountCents)
                .sum();
        long income = rows.stream()
                .filter(e -> LedgerTypes.INCOME.equals(e.getType()))
                .mapToLong(LedgerEntries::getAmountCents)
                .sum();
        long count =
                rows.stream().filter(e -> !LedgerTypes.isTransfer(e.getType())).count();
        long transfers =
                rows.stream().filter(e -> LedgerTypes.isTransfer(e.getType())).count();

        return new LedgerSummaryDto(
                ym.toString(),
                from,
                to,
                expense,
                income,
                count,
                transfers,
                spendsOf(uid, LedgerTypes.EXPENSE, from, to, names),
                spendsOf(uid, LedgerTypes.INCOME, from, to, names));
    }

    @Override
    @Transactional(readOnly = true)
    public LedgerRangeStatsDto rangeStats(String userId, OffsetDateTime from, OffsetDateTime to) {
        UUID uid = UUID.fromString(userId);
        if (from == null || to == null || !from.isBefore(to)) {
            throw BizException.validation("from 必须早于 to");
        }

        Map<Short, String> names = rootCategoryNames();
        ZoneId zone = clock.getZone();

        List<LedgerEntries> rows = entriesMapper.selectList(new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getUserId, uid)
                .ge(LedgerEntries::getOccurredAt, from)
                .lt(LedgerEntries::getOccurredAt, to));

        long expense = rows.stream()
                .filter(e -> LedgerTypes.EXPENSE.equals(e.getType()))
                .mapToLong(LedgerEntries::getAmountCents)
                .sum();
        long income = rows.stream()
                .filter(e -> LedgerTypes.INCOME.equals(e.getType()))
                .mapToLong(LedgerEntries::getAmountCents)
                .sum();
        long count =
                rows.stream().filter(e -> !LedgerTypes.isTransfer(e.getType())).count();
        long transfers =
                rows.stream().filter(e -> LedgerTypes.isTransfer(e.getType())).count();

        return new LedgerRangeStatsDto(
                from,
                to,
                expense,
                income,
                count,
                transfers,
                spendsOf(uid, LedgerTypes.EXPENSE, from, to, names),
                spendsOf(uid, LedgerTypes.INCOME, from, to, names),
                dailyBuckets(rows, from, to, zone));
    }

    /**
     * 把区间内的流水按天补零切桶。
     *
     * 只出「天」这一层：周视图直接用它，月/季/年由前端把天合并成月，
     * 避免后端维护两套分桶、也避免「季度的日」这种没意义的数据量。
     */
    private List<DailyPoint> dailyBuckets(
            List<LedgerEntries> rows, OffsetDateTime from, OffsetDateTime to, ZoneId zone) {
        LocalDate start = from.atZoneSameInstant(zone).toLocalDate();
        LocalDate end = to.atZoneSameInstant(zone).toLocalDate();
        /*
         * to 是开区间：若它正好落在某天 0 点，那天不该算进来。
         *
         * 必须用 isEqual 而不是 equals——OffsetDateTime.equals 还比较偏移量，
         * 前端传的是 UTC（Z）而这里构造的是 +08:00，同一瞬间也不相等，
         * 结果多出一格（一周变 8 天、一季度变 4 个月）。
         */
        if (to.isEqual(end.atStartOfDay(zone).toOffsetDateTime())) {
            end = end.minusDays(1);
        }

        Map<LocalDate, long[]> perDay = new LinkedHashMap<>();
        for (LocalDate d = start; !d.isAfter(end); d = d.plusDays(1)) {
            perDay.put(d, new long[] {0, 0, 0});
        }
        for (LedgerEntries e : rows) {
            if (LedgerTypes.isTransfer(e.getType())) {
                continue;
            }
            LocalDate day = e.getOccurredAt().atZoneSameInstant(zone).toLocalDate();
            long[] acc = perDay.get(day);
            if (acc == null) {
                continue;
            }
            if (LedgerTypes.EXPENSE.equals(e.getType())) {
                acc[0] += e.getAmountCents();
            } else {
                acc[1] += e.getAmountCents();
            }
            acc[2] += 1;
        }
        return perDay.entrySet().stream()
                .map(kv -> new DailyPoint(kv.getKey().toString(), kv.getValue()[0], kv.getValue()[1], kv.getValue()[2]))
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public LedgerTrendDto trend(String userId, int days) {
        UUID uid = UUID.fromString(userId);
        int n = Math.clamp(days, 1, 90);
        ZoneId zone = clock.getZone();
        LocalDate today = LocalDate.now(clock.withZone(zone));
        LocalDate start = today.minusDays(n - 1L);

        OffsetDateTime from = start.atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = today.plusDays(1).atStartOfDay(zone).toOffsetDateTime();

        List<LedgerEntries> rows = entriesMapper.selectList(new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getUserId, uid)
                .ge(LedgerEntries::getOccurredAt, from)
                .lt(LedgerEntries::getOccurredAt, to));

        Map<LocalDate, long[]> perDay = new LinkedHashMap<>();
        for (int i = 0; i < n; i++) {
            perDay.put(start.plusDays(i), new long[] {0, 0, 0});
        }
        for (LedgerEntries e : rows) {
            if (LedgerTypes.isTransfer(e.getType())) {
                continue;
            }
            LocalDate day = e.getOccurredAt().atZoneSameInstant(zone).toLocalDate();
            long[] acc = perDay.get(day);
            if (acc == null) {
                continue;
            }
            if (LedgerTypes.EXPENSE.equals(e.getType())) {
                acc[0] += e.getAmountCents();
            } else {
                acc[1] += e.getAmountCents();
            }
            acc[2] += 1;
        }

        List<DailyPoint> daily = perDay.entrySet().stream()
                .map(kv -> new DailyPoint(kv.getKey().toString(), kv.getValue()[0], kv.getValue()[1], kv.getValue()[2]))
                .toList();

        long expense = daily.stream().mapToLong(DailyPoint::expenseCents).sum();
        long income = daily.stream().mapToLong(DailyPoint::incomeCents).sum();

        return new LedgerTrendDto(
                n,
                from,
                to,
                expense,
                income,
                daily.stream().mapToLong(DailyPoint::count).sum(),
                daily);
    }

    // ── 预算 ──────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public BudgetDto budget(String userId, String month) {
        UUID uid = UUID.fromString(userId);
        YearMonth ym = parseMonth(month);
        ZoneId zone = clock.getZone();
        OffsetDateTime from = ym.atDay(1).atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = ym.plusMonths(1).atDay(1).atStartOfDay(zone).toOffsetDateTime();

        Map<Short, String> names = rootCategoryNames();
        Map<Short, Long> spent = spendsOf(uid, LedgerTypes.EXPENSE, from, to, names).stream()
                .collect(Collectors.toMap(CategorySpend::categoryId, CategorySpend::spentCents));

        List<LedgerBudgets> rows = budgetsMapper.selectList(new LambdaQueryWrapper<LedgerBudgets>()
                .eq(LedgerBudgets::getUserId, uid)
                .eq(LedgerBudgets::getMonth, ym.toString())
                .orderByAsc(LedgerBudgets::getCategoryId));

        List<BudgetItemDto> items = rows.stream()
                .map(b -> {
                    long used = spent.getOrDefault(b.getCategoryId(), 0L);
                    return new BudgetItemDto(
                            b.getCategoryId(),
                            names.getOrDefault(b.getCategoryId(), ""),
                            b.getAmountCents(),
                            used,
                            b.getAmountCents() - used);
                })
                .toList();

        return new BudgetDto(
                ym.toString(),
                items.stream().mapToLong(BudgetItemDto::amountCents).sum(),
                items.stream().mapToLong(BudgetItemDto::spentCents).sum(),
                items);
    }

    @Override
    @Transactional
    public BudgetDto upsertBudget(String userId, UpsertBudgetRequest req) {
        UUID uid = UUID.fromString(userId);
        YearMonth ym = YearMonth.parse(req.month());
        LedgerCategories category = categoriesMapper.selectById(req.categoryId());
        if (category == null || !Boolean.TRUE.equals(category.getEnabled())) {
            throw BizException.validation("分类不存在");
        }
        if (category.getParentId() != null) {
            throw BizException.validation("预算只能绑在一级分类上");
        }
        if (!LedgerTypes.EXPENSE.equals(category.getKind())) {
            throw BizException.validation("只能为支出分类设置预算");
        }

        OffsetDateTime now = OffsetDateTime.now(clock);
        LedgerBudgets existing = budgetsMapper.selectOne(new LambdaQueryWrapper<LedgerBudgets>()
                .eq(LedgerBudgets::getUserId, uid)
                .eq(LedgerBudgets::getCategoryId, req.categoryId())
                .eq(LedgerBudgets::getMonth, ym.toString()));

        if (existing == null) {
            budgetsMapper.insert(new LedgerBudgets()
                    .setId(UUID.randomUUID())
                    .setUserId(uid)
                    .setCategoryId(req.categoryId())
                    .setMonth(ym.toString())
                    .setAmountCents(req.amountCents())
                    .setCreatedAt(now)
                    .setUpdatedAt(now));
        } else {
            budgetsMapper.update(
                    null,
                    new LambdaUpdateWrapper<LedgerBudgets>()
                            .eq(LedgerBudgets::getId, existing.getId())
                            .set(LedgerBudgets::getAmountCents, req.amountCents())
                            .set(LedgerBudgets::getUpdatedAt, now));
        }
        return budget(userId, ym.toString());
    }

    @Override
    @Transactional
    public void deleteBudget(String userId, short categoryId, String month) {
        UUID uid = UUID.fromString(userId);
        budgetsMapper.delete(new LambdaQueryWrapper<LedgerBudgets>()
                .eq(LedgerBudgets::getUserId, uid)
                .eq(LedgerBudgets::getCategoryId, categoryId)
                .eq(LedgerBudgets::getMonth, parseMonth(month).toString()));
    }

    // ── 内部 ──────────────────────────────────────────

    private List<CategorySpend> spendsOf(
            UUID uid, String type, OffsetDateTime from, OffsetDateTime to, Map<Short, String> names) {
        return entriesMapper.totalsByRootCategory(uid, type, from, to).stream()
                .map(t -> new CategorySpend(t.categoryId(), names.getOrDefault(t.categoryId(), ""), t.amountCents()))
                .sorted((a, b) -> Long.compare(b.spentCents(), a.spentCents()))
                .toList();
    }

    /** 一级分类 id → 名称。 */
    private Map<Short, String> rootCategoryNames() {
        return categoriesMapper
                .selectList(new LambdaQueryWrapper<LedgerCategories>().isNull(LedgerCategories::getParentId))
                .stream()
                .collect(Collectors.toMap(LedgerCategories::getId, LedgerCategories::getName));
    }

    private void requireValidType(String type) {
        if (!AccountTypes.ALL.contains(type)) {
            throw BizException.validation("账户类型只能是 cash、bank、credit、ewallet");
        }
    }

    private void requireUniqueName(UUID uid, String name, UUID selfId) {
        LedgerAccounts other = accountsMapper.selectOne(new LambdaQueryWrapper<LedgerAccounts>()
                .eq(LedgerAccounts::getUserId, uid)
                .apply("lower(name) = lower({0})", name.trim()));
        if (other != null && !other.getId().equals(selfId)) {
            throw BizException.conflict("已存在同名账户");
        }
    }

    private int nextSortOrder(UUID uid) {
        Long count =
                accountsMapper.selectCount(new LambdaQueryWrapper<LedgerAccounts>().eq(LedgerAccounts::getUserId, uid));
        return count != null ? count.intValue() : 0;
    }

    private LedgerAccounts requireAccount(UUID uid, UUID accountId) {
        LedgerAccounts account = accountsMapper.selectOne(new LambdaQueryWrapper<LedgerAccounts>()
                .eq(LedgerAccounts::getId, accountId)
                .eq(LedgerAccounts::getUserId, uid));
        if (account == null) {
            throw BizException.notFound("账户不存在");
        }
        return account;
    }

    private UUID requireAccountId(UUID uid, UUID accountId, String label) {
        if (accountId == null) {
            throw BizException.validation(label + "不能为空");
        }
        requireAccount(uid, accountId);
        return accountId;
    }

    private LedgerEntries requireEntry(UUID uid, UUID entryId) {
        LedgerEntries entry = entriesMapper.selectOne(new LambdaQueryWrapper<LedgerEntries>()
                .eq(LedgerEntries::getId, entryId)
                .eq(LedgerEntries::getUserId, uid));
        if (entry == null) {
            throw BizException.notFound("流水不存在");
        }
        return entry;
    }

    /** 分类必须存在且 kind 与流水类型一致。 */
    private void requireCategoryKind(Short categoryId, String type) {
        LedgerCategories category = categoriesMapper.selectById(categoryId);
        if (category == null || !Boolean.TRUE.equals(category.getEnabled())) {
            throw BizException.validation("分类不存在");
        }
        if (!category.getKind().equals(type)) {
            throw BizException.validation("分类与流水类型不匹配");
        }
    }

    private YearMonth parseMonth(String month) {
        if (month == null || month.isBlank()) {
            return YearMonth.now(clock);
        }
        try {
            return YearMonth.parse(month.trim());
        } catch (RuntimeException e) {
            throw BizException.validation("month 格式必须是 YYYY-MM");
        }
    }

    private AccountDto toAccountDto(LedgerAccounts a, long balance) {
        return new AccountDto(
                a.getId(),
                a.getName(),
                a.getIcon() != null ? a.getIcon() : "",
                a.getType(),
                a.getInitialBalanceCents(),
                balance,
                a.getSortOrder(),
                Boolean.TRUE.equals(a.getArchived()));
    }

    private LedgerEntryDto toEntryDto(LedgerEntries e) {
        Map<Short, LedgerCategories> cache = new java.util.HashMap<>();
        Function<Short, LedgerCategories> load = id -> {
            if (id == null) {
                return null;
            }
            return cache.computeIfAbsent(id, categoriesMapper::selectById);
        };

        LedgerCategories cat = load.apply(e.getCategoryId());
        LedgerCategories root = cat != null && cat.getParentId() != null ? load.apply(cat.getParentId()) : cat;

        LedgerAccounts from = e.getAccountId() != null ? accountsMapper.selectById(e.getAccountId()) : null;
        LedgerAccounts to = e.getToAccountId() != null ? accountsMapper.selectById(e.getToAccountId()) : null;

        return new LedgerEntryDto(
                e.getId(),
                e.getType(),
                e.getAmountCents(),
                e.getCategoryId(),
                cat != null ? cat.getName() : null,
                root != null ? root.getName() : null,
                e.getAccountId(),
                from != null ? from.getName() : null,
                e.getToAccountId(),
                to != null ? to.getName() : null,
                e.getNote(),
                e.getOccurredAt(),
                e.getCreatedAt(),
                e.getUpdatedAt());
    }
}
