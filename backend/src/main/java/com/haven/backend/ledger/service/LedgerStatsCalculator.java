package com.haven.backend.ledger.service;

import com.haven.backend.ledger.dto.LedgerDtos.LedgerCategoryRank;
import com.haven.backend.ledger.dto.LedgerDtos.LedgerDailyPoint;
import com.haven.backend.ledger.entity.LedgerEntries;
import com.haven.backend.ledger.entity.LedgerTypes;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

/**
 * 记账统计的纯计算层。
 * <p>
 * 输入一批条目与日期序列，输出总额、分类排行、按天走势。
 * 不访问数据库，因此可以直接用单元测试覆盖补零、跨时区归属、排序等边界。
 */
@Component
public class LedgerStatsCalculator {

    /** 一个时间窗口的统计结果。 */
    public record WindowStats(
            long totalExpenseCents,
            long totalIncomeCents,
            long totalCount,
            List<LedgerCategoryRank> categoryRanking,
            List<LedgerCategoryRank> incomeCategoryRanking,
            List<LedgerDailyPoint> daily) {}

    /**
     * 计算一个时间窗口内的统计。
     *
     * @param entries 窗口内的条目（调用方已按时间过滤）
     * @param dates 按天序列的范围，负责补零
     * @param zone 业务时区，决定「发生在哪一天」
     */
    public WindowStats summarize(List<LedgerEntries> entries, List<LocalDate> dates, ZoneId zone) {
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
            boolean income = LedgerTypes.INCOME.equals(entry.getType());

            if (income) {
                totalIncome += cents;
                accumulate(incomeRanking, entry, cents);
            } else {
                totalExpense += cents;
                accumulate(expenseRanking, entry, cents);
            }

            if (entry.getOccurredAt() == null) {
                continue;
            }
            long[] bucket =
                    daily.get(entry.getOccurredAt().atZoneSameInstant(zone).toLocalDate());
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

        List<LedgerDailyPoint> points = daily.entrySet().stream()
                .map(e ->
                        new LedgerDailyPoint(e.getKey().toString(), e.getValue()[0], e.getValue()[1], e.getValue()[2]))
                .toList();

        return new WindowStats(
                totalExpense, totalIncome, entries.size(), toRanking(expenseRanking), toRanking(incomeRanking), points);
    }

    /** 累加一个分类的金额与笔数；{@code cents} 由调用方统一做过 null 处理。 */
    private void accumulate(Map<String, long[]> ranking, LedgerEntries entry, long cents) {
        long[] bucket = ranking.computeIfAbsent(entry.getCategory(), k -> new long[2]);
        bucket[0] += cents;
        bucket[1]++;
    }

    /** 金额降序，金额相同时按分类名升序，保证输出稳定。 */
    private List<LedgerCategoryRank> toRanking(Map<String, long[]> ranking) {
        return ranking.entrySet().stream()
                .sorted((a, b) -> {
                    int byAmount = Long.compare(b.getValue()[0], a.getValue()[0]);
                    return byAmount != 0 ? byAmount : a.getKey().compareTo(b.getKey());
                })
                .map(e -> new LedgerCategoryRank(e.getKey(), e.getValue()[0], e.getValue()[1]))
                .toList();
    }
}
