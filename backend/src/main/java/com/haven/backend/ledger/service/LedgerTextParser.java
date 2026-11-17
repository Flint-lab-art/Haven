package com.haven.backend.ledger.service;

import com.haven.backend.ledger.dto.LedgerParseError;
import com.haven.backend.ledger.dto.ParsedLedgerItem;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;

/**
 * 快捷输入的纯文本解析器。
 * <p>
 * 这一层<b>没有任何数据库依赖</b>，输入「一行文本 + 别名表 + 当前时间」，
 * 输出「解析出的条目 / 逐行错误」。因此可以直接用单元测试覆盖各种写法，
 * 不需要起 Spring 上下文。
 * <p>
 * 支持的写法：
 * <ul>
 *   <li>金额：{@code 12} / {@code 12.5} / {@code 32元} / {@code ¥32} / {@code 二十五块} / {@code 十二点五元}</li>
 *   <li>日期：{@code 2026-11-16} / {@code 2026年11月16日} / {@code 11月16} / {@code 11-16} /
 *       {@code 16号} / {@code 今天 / 昨天 / 前天}</li>
 *   <li>分类：命中别名 → 用别名值；命中内置分类 → 直接用；否则归入「未分类」并把原词并入备注</li>
 * </ul>
 */
@Component
public class LedgerTextParser {

    /** 未分类的固定值，便于调用方判断"是否值得学习成别名"。 */
    public static final String UNCATEGORIZED = "未分类";

    /**
     * 未命中别名、但文本里出现这些词时也判为收入。
     * 覆盖「工资到账 10000」「公司报销 320」这类备注写法。
     */
    static final Set<String> INCOME_KEYWORDS = Set.of(
            "工资", "薪水", "薪资", "月薪", "发工资", "奖金", "年终奖", "提成", "绩效", "报销", "报账", "退款", "退钱", "退费", "退回", "红包", "压岁钱",
            "礼金", "收礼", "利息", "分红", "理财收益", "兼职", "外快", "卖二手", "收入");

    /** 行末阿拉伯数字金额：12 / 12.5 / 32元 / ¥32。 */
    private static final Pattern ARABIC_AMOUNT =
            Pattern.compile("(?<![\\d.])(?:[¥￥]\\s*)?(\\d+(?:\\.\\d{1,2})?)\\s*(?:元|块|圆|人民币)?\\s*$");

    /** 行末中文数字金额：二十五块 / 十二点五元。 */
    private static final Pattern CHINESE_AMOUNT =
            Pattern.compile("([零〇一二两三四五六七八九十百千万亿]+(?:点[零〇一二两三四五六七八九]+)?)\\s*(?:元|块|圆|人民币)?\\s*$");

    /** 行首完整日期：2026-11-16 / 2026/11/16 / 2026年11月16日。 */
    private static final Pattern FULL_DATE =
            Pattern.compile("^(\\d{4})\\s*[-/.年]\\s*(\\d{1,2})\\s*[-/.月]\\s*(\\d{1,2})\\s*[日号]?(?=\\s|$)");

    /** 行首月日：11月16 / 11-16 / 11/16，年份默认当前年。 */
    private static final Pattern MONTH_DAY = Pattern.compile("^(\\d{1,2})\\s*[-/.月]\\s*(\\d{1,2})\\s*[日号]?(?=\\s|$)");

    /** 行首单日：16号 / 16日，年月默认当前。 */
    private static final Pattern DAY_ONLY = Pattern.compile("^(\\d{1,2})\\s*[日号](?=\\s|$)");

    /** 相对日期：今天 / 昨天 / 前天。 */
    private static final Pattern RELATIVE_DATE = Pattern.compile("^(今天|昨天|前天)(?=\\s|$)");

    private static final Map<Character, Integer> CN_DIGITS = Map.ofEntries(
            Map.entry('零', 0),
            Map.entry('〇', 0),
            Map.entry('一', 1),
            Map.entry('二', 2),
            Map.entry('两', 2),
            Map.entry('三', 3),
            Map.entry('四', 4),
            Map.entry('五', 5),
            Map.entry('六', 6),
            Map.entry('七', 7),
            Map.entry('八', 8),
            Map.entry('九', 9));

    private static final Map<Character, Integer> CN_UNITS =
            Map.of('十', 10, '百', 100, '千', 1_000, '万', 10_000, '亿', 100_000_000);

    private final Clock clock;
    private final LedgerClassifier classifier;

    public LedgerTextParser(Clock clock, LedgerClassifier classifier) {
        this.clock = clock;
        this.classifier = classifier;
    }

    /**
     * 解析多行文本。
     *
     * @param text 原始输入，按行拆分
     * @param aliases 用户别名表（原词 → 分类）；空表表示没有别名
     * @param now 本次解析的时间基准（影响「今天/昨天」与缺省发生时间）
     */
    public Result parse(String text, Map<String, String> aliases, OffsetDateTime now) {
        List<ParsedLedgerItem> items = new ArrayList<>();
        List<LedgerParseError> errors = new ArrayList<>();
        String[] lines = text.split("\\R", -1);

        for (int i = 0; i < lines.length; i++) {
            String raw = lines[i].trim();
            if (raw.isEmpty()) {
                continue;
            }
            int lineNo = i + 1;
            try {
                ParsedLedgerItem item = parseLine(raw, lineNo, aliases, now);
                if (item == null) {
                    errors.add(new LedgerParseError(lineNo, raw, "未找到金额"));
                } else if (item.amountCents() <= 0) {
                    errors.add(new LedgerParseError(lineNo, raw, "金额必须大于 0"));
                } else {
                    items.add(item);
                }
            } catch (IllegalArgumentException e) {
                errors.add(new LedgerParseError(lineNo, raw, e.getMessage()));
            }
        }
        return new Result(items, errors);
    }

    /** 解析单行；没有金额时返回 {@code null}。 */
    ParsedLedgerItem parseLine(String raw, int line, Map<String, String> aliases, OffsetDateTime now) {
        AmountMatch match = extractAmount(raw);
        if (match == null) {
            return null;
        }
        DatePrefix dated = extractDatePrefix(match.remaining(), now);
        LedgerClassifier.Classification c = classifier.classify(dated.rest(), aliases);
        return classifier.toItem(line, raw, match.amountCents(), c, dated.occurredAt());
    }

    // -----------------------------------------------------------------------
    // 日期
    // -----------------------------------------------------------------------

    /**
     * 抽取行首日期，返回剩余文本与发生时间。
     * <p>
     * 没写日期时沿用传入的 {@code now}；月日与单日默认当前年份。
     */
    DatePrefix extractDatePrefix(String remaining, OffsetDateTime now) {
        Matcher full = FULL_DATE.matcher(remaining);
        if (full.find()) {
            OffsetDateTime at = resolveDate(
                    now,
                    Integer.parseInt(full.group(1)),
                    Integer.parseInt(full.group(2)),
                    Integer.parseInt(full.group(3)));
            if (at != null) {
                return new DatePrefix(remaining.substring(full.end()).trim(), at);
            }
        }

        Matcher monthDay = MONTH_DAY.matcher(remaining);
        if (monthDay.find()) {
            OffsetDateTime at = resolveDate(
                    now, now.getYear(), Integer.parseInt(monthDay.group(1)), Integer.parseInt(monthDay.group(2)));
            if (at != null) {
                return new DatePrefix(remaining.substring(monthDay.end()).trim(), at);
            }
        }

        Matcher dayOnly = DAY_ONLY.matcher(remaining);
        if (dayOnly.find()) {
            OffsetDateTime at =
                    resolveDate(now, now.getYear(), now.getMonthValue(), Integer.parseInt(dayOnly.group(1)));
            if (at != null) {
                return new DatePrefix(remaining.substring(dayOnly.end()).trim(), at);
            }
        }

        Matcher relative = RELATIVE_DATE.matcher(remaining);
        if (relative.find()) {
            int daysAgo = switch (relative.group(1)) {
                case "昨天" -> 1;
                case "前天" -> 2;
                default -> 0;
            };
            return new DatePrefix(remaining.substring(relative.end()).trim(), now.minusDays(daysAgo));
        }

        return new DatePrefix(remaining, now);
    }

    /** 校验年月日并保留当前时分秒；非法日期返回 null，交给后续规则处理。 */
    private OffsetDateTime resolveDate(OffsetDateTime now, int year, int month, int day) {
        if (year < 1970 || year > 2100 || month < 1 || month > 12) {
            return null;
        }
        if (day < 1 || day > YearMonth.of(year, month).lengthOfMonth()) {
            return null;
        }
        return LocalDate.of(year, month, day)
                .atTime(now.toLocalTime())
                .atZone(clock.getZone())
                .toOffsetDateTime();
    }

    // -----------------------------------------------------------------------
    // 金额
    // -----------------------------------------------------------------------

    AmountMatch extractAmount(String line) {
        Matcher arabic = ARABIC_AMOUNT.matcher(line);
        if (arabic.find()) {
            return new AmountMatch(
                    parseArabicCents(arabic.group(1)),
                    line.substring(0, arabic.start()).trim());
        }

        Matcher chinese = CHINESE_AMOUNT.matcher(line);
        if (chinese.find()) {
            return new AmountMatch(
                    parseChineseCents(chinese.group(1)),
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
            return value.movePointRight(2).setScale(0, RoundingMode.UNNECESSARY).longValueExact();
        } catch (ArithmeticException e) {
            throw new IllegalArgumentException("金额最多保留两位小数");
        }
    }

    /** 行首日期抽取结果。 */
    record DatePrefix(String rest, OffsetDateTime occurredAt) {}

    /** 行末金额抽取结果。 */
    record AmountMatch(long amountCents, String remaining) {}

    /** 一次解析的结果。 */
    public record Result(List<ParsedLedgerItem> items, List<LedgerParseError> errors) {}
}
