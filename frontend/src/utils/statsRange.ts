/**
 * 统计页的时间区间计算（周 / 月 / 季 / 年）。
 *
 * 四种粒度共用一套 `{ from, to }`，后端只认区间；
 * 但**锚点**不同：周看哪天花得多、月看花在哪、季度看三个月对比、年看全年走势，
 * 所以这里同时给出「上一格 / 下一格」的位移方式和标题。
 *
 * 一律按本地时区，且**不越过今天**——记账没有还没发生的月份。
 */

export type StatsGranularity = 'week' | 'month' | 'quarter' | 'year'

export interface RangeInfo {
  /** 起始边界（含），ISO。 */
  from: string
  /** 结束边界（不含），ISO；到今天为止时是「明天 0 点」。 */
  to: string
  /** 标题，如「11 月第 4 周」「2026 年 11 月」「2026 Q4」「2026 年」。 */
  label: string
  /** 是否已经是包含今天的那一格（不能再往后翻）。 */
  isCurrent: boolean
}

function pad(n: number): string {
  return String(n).padStart(2, '0')
}

/** 本地日期 → 当天 0 点。 */
function startOfDay(y: number, m: number, d: number): Date {
  return new Date(y, m - 1, d, 0, 0, 0, 0)
}

/** 某月的天数。 */
function daysInMonth(y: number, m: number): number {
  return new Date(y, m, 0).getDate()
}

/** 周一为一周起点（国内习惯）。 */
function mondayOf(date: Date): Date {
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  const weekday = (d.getDay() + 6) % 7 // 周一 = 0
  d.setDate(d.getDate() - weekday)
  return d
}

/**
 * 计算某一格的区间。
 *
 * @param granularity 粒度
 * @param offset 相对当前格子的位移，0 = 当前格，-1 = 上一格
 */
export function rangeOf(granularity: StatsGranularity, offset = 0, today = new Date()): RangeInfo {
  const y = today.getFullYear()
  const m = today.getMonth() + 1

  if (granularity === 'week') {
    const anchor = mondayOf(today)
    anchor.setDate(anchor.getDate() + offset * 7)
    const start = new Date(anchor)
    const end = new Date(anchor)
    end.setDate(end.getDate() + 7)

    const sy = start.getFullYear()
    const sm = start.getMonth() + 1
    const sd = start.getDate()
    // 第几周：按「本月第一个周一」推算，月份边界不清时退回日期范围写法
    const weekNo = Math.ceil(sd / 7)
    return {
      from: startOfDay(sy, sm, sd).toISOString(),
      to: end.toISOString(),
      label: `${sm} 月第 ${weekNo} 周`,
      isCurrent: offset >= 0,
    }
  }

  if (granularity === 'month') {
    const anchor = new Date(y, m - 1 + offset, 1)
    const ay = anchor.getFullYear()
    const am = anchor.getMonth() + 1
    const end = new Date(ay, am, 1)
    return {
      from: startOfDay(ay, am, 1).toISOString(),
      to: end.toISOString(),
      label: `${ay} 年 ${am} 月`,
      isCurrent: offset >= 0,
    }
  }

  if (granularity === 'quarter') {
    const q = Math.floor((m - 1) / 3) + 1
    const anchorQ = q + offset
    // 跨年：把 anchorQ 折算成绝对月份
    const absoluteMonth = (y * 4) + (anchorQ - 1)
    const qy = Math.floor(absoluteMonth / 4)
    const qq = (absoluteMonth % 4) + 1
    const startMonth = (qq - 1) * 3 + 1
    const end = new Date(qy, startMonth + 2, 1)
    return {
      from: startOfDay(qy, startMonth, 1).toISOString(),
      to: end.toISOString(),
      label: `${qy} Q${qq}`,
      isCurrent: offset >= 0,
    }
  }

  // year
  const ay = y + offset
  return {
    from: startOfDay(ay, 1, 1).toISOString(),
    to: startOfDay(ay + 1, 1, 1).toISOString(),
    label: `${ay} 年`,
    isCurrent: offset >= 0,
  }
}

/** 粒度中文名。 */
export const GRANULARITY_LABEL: Record<StatsGranularity, string> = {
  week: '周',
  month: '月',
  quarter: '季',
  year: '年',
}

/**
 * 把按天的点合并成按月。
 * 季度 / 年视图用：12 个或 3 个柱子，比 365 个点有意义。
 */
export function mergeByMonth(points: { date: string; expense_cents: number; income_cents: number; count: number }[]) {
  const map = new Map<string, { month: string; expense_cents: number; income_cents: number; count: number }>()
  for (const p of points) {
    const month = p.date.slice(0, 7)
    const acc = map.get(month) ?? { month: `${Number(month.slice(5))} 月`, expense_cents: 0, income_cents: 0, count: 0 }
    acc.expense_cents += p.expense_cents
    acc.income_cents += p.income_cents
    acc.count += p.count
    map.set(month, acc)
  }
  return [...map.values()]
}

/**
 * 一个区间在各月份里各占几天。
 *
 * 周视图可能跨月（比如 11/24 那一周跨到 12/1），
 * 折算预算时要按「这一周有几天落在某月」来分摊，否则会整周都按一个月算。
 *
 * @returns `[{ month: '2026-11', days: 6 }, { month: '2026-12', days: 1 }]`
 */
export function monthDaysInRange(from: string, to: string): { month: string; days: number }[] {
  const start = new Date(from)
  const end = new Date(to)
  const counts = new Map<string, number>()

  const cursor = new Date(start.getFullYear(), start.getMonth(), start.getDate())
  while (cursor.getTime() < end.getTime()) {
    const key = `${cursor.getFullYear()}-${pad(cursor.getMonth() + 1)}`
    counts.set(key, (counts.get(key) ?? 0) + 1)
    cursor.setDate(cursor.getDate() + 1)
  }

  return [...counts.entries()].map(([month, days]) => ({ month, days }))
}

/**
 * 把按天的点按「自然周」分桶（周一到周日）。
 *
 * 月视图用：一个月 ≈ 4~5 个点，比 30 个点更容易看出节奏。
 * 分桶按日期所在的周一分组，所以月初那一周可能是「半个月」——
 * 这不是 bug，是自然周切分的必然结果。
 */
export function mergeByWeek(
  points: { date: string; expense_cents: number; income_cents: number; count: number }[],
) {
  const map = new Map<string, { week: string; label: string; expense_cents: number; income_cents: number; count: number }>()
  for (const p of points) {
    const [y, m, d] = p.date.split('-').map(Number)
    const date = new Date(y, m - 1, d)
    const monday = new Date(date)
    monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7))
    const key = `${monday.getFullYear()}-${pad(monday.getMonth() + 1)}-${pad(monday.getDate())}`

    const acc = map.get(key)
    if (acc) {
      acc.expense_cents += p.expense_cents
      acc.income_cents += p.income_cents
      acc.count += p.count
    } else {
      map.set(key, {
        week: key,
        // 标签用「该周第一天是几号」
        label: `${monday.getDate()}`,
        expense_cents: p.expense_cents,
        income_cents: p.income_cents,
        count: p.count,
      })
    }
  }
  return [...map.values()]
}

/** 结束边界是不是「未来」（用于只统计到今天）。 */
export function clampToToday(to: string, today = new Date()): string {
  const end = new Date(to)
  const tomorrow = startOfDay(today.getFullYear(), today.getMonth() + 1, today.getDate() + 1)
  return end.getTime() > tomorrow.getTime() ? tomorrow.toISOString() : to
}

export { daysInMonth, pad }
