/** 记账明细的分组与日期展示（纯函数，便于单测）。 */
import type { LedgerEntry } from '@/api/ledger'

/** 同一天的一组明细。 */
export interface DayGroup {
  /** 本地日期键，`YYYY-MM-DD`。 */
  date: string
  /** 分组标题，如「11月17日」。 */
  label: string
  /** 星期几，如「周一」。 */
  weekday: string
  /** 当天所有明细（按发生时间倒序）。 */
  items: LedgerEntry[]
  /** 当天支出合计（分）。 */
  expenseCents: number
  /** 当天收入合计（分）。 */
  incomeCents: number
}

const WEEKDAYS = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

function pad(n: number): string {
  return String(n).padStart(2, '0')
}

/**
 * 取条目发生时间在**本地时区**下的日期键。
 *
 * 不能用 `ISOString().slice(0, 10)`：那是 UTC 日期，
 * 东八区凌晨 0~8 点的记录会被分到前一天。
 */
export function localDateKey(value: string | Date): string {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

/** 分组标题：`11月17日`。 */
export function dayLabel(dateKey: string): string {
  const [, mon, day] = dateKey.split('-').map(Number)
  if (!mon || !day) return ''
  return `${mon}月${day}日`
}

/** 星期几：`周一`。 */
export function weekdayOf(dateKey: string): string {
  const [year, mon, day] = dateKey.split('-').map(Number)
  if (!year || !mon || !day) return ''
  // 用本地时间构造，避免 new Date('2026-11-17') 被当成 UTC
  const date = new Date(year, mon - 1, day)
  return WEEKDAYS[date.getDay()] ?? ''
}

/**
 * 把明细按天分组。
 *
 * - 分组键是本地日期；同一天内按 `occurred_at` 倒序（晚上记的在上面）
 * - 组之间按日期倒序，最新的在前
 * - 「今天」「昨天」这类相对标题由调用方决定要不要替换，这里只给绝对日期，
 *   保持纯函数、避免依赖当前时间导致测试不稳定
 */
export function groupByDay(entries: readonly LedgerEntry[]): DayGroup[] {
  const buckets = new Map<string, LedgerEntry[]>()

  for (const entry of entries) {
    const key = localDateKey(entry.occurred_at)
    if (!key) continue
    const list = buckets.get(key)
    if (list) list.push(entry)
    else buckets.set(key, [entry])
  }

  return [...buckets.entries()]
    .map(([date, items]) => {
      // 复制一份再排序，不修改入参
      const sorted = [...items].sort(
        (a, b) => new Date(b.occurred_at).getTime() - new Date(a.occurred_at).getTime(),
      )
      let expenseCents = 0
      let incomeCents = 0
      for (const item of sorted) {
        if (item.type === 'income') incomeCents += item.amount_cents
        else expenseCents += item.amount_cents
      }
      return {
        date,
        label: dayLabel(date),
        weekday: weekdayOf(date),
        items: sorted,
        expenseCents,
        incomeCents,
      }
    })
    .sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0))
}

/**
 * 把绝对日期换成「今天 / 昨天」，其余保持原样。
 *
 * 单独成函数是因为它依赖「现在」，与 {@link groupByDay} 分开后
 * 后者可以稳定地做单元测试。
 */
export function relativeDayLabel(label: string, dateKey: string, today = new Date()): string {
  const todayKey = localDateKey(today)
  if (dateKey === todayKey) return '今天'

  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)
  if (dateKey === localDateKey(yesterday)) return '昨天'

  return label
}
