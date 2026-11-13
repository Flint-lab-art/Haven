/** 记账模块的展示映射与时间工具（纯函数，便于单测）。 */
import type { LedgerCategory } from '@/api/ledger'

/** 支出大类。 */
export const EXPENSE_CATEGORIES: LedgerCategory[] = [
  '餐饮',
  '购物',
  '交通',
  '居家',
  '娱乐',
  '医疗',
  '未分类',
]

/** 收入大类；方向仍由 type 表达，category 只是单层分类。 */
export const INCOME_CATEGORIES: LedgerCategory[] = [
  '工资',
  '奖金',
  '报销',
  '退款',
  '红包',
  '其他收入',
]

/** 所有分类，用于筛选等不分方向的场景。 */
export const LEDGER_CATEGORIES: LedgerCategory[] = [
  ...EXPENSE_CATEGORIES,
  ...INCOME_CATEGORIES,
]

/**
 * 某一笔记录可选的分类。
 *
 * 老数据里可能存着与 type 不匹配的分类，编辑时把它补在末尾，
 * 避免下拉框显示为空后一保存就被改掉。
 */
export function categoriesForType(type: string, current?: string): LedgerCategory[] {
  const base = type === 'income' ? INCOME_CATEGORIES : EXPENSE_CATEGORIES
  if (current && !base.includes(current as LedgerCategory)) {
    return [...base, current as LedgerCategory]
  }
  return base
}

/** 分类对应的色阶 class，用于列表与排行的小圆点 / 标签。 */
const CATEGORY_TONE: Record<LedgerCategory, string> = {
  餐饮: 'food',
  购物: 'shop',
  交通: 'transit',
  居家: 'home',
  娱乐: 'fun',
  医疗: 'health',
  未分类: 'other',
  工资: 'salary',
  奖金: 'bonus',
  报销: 'reimburse',
  退款: 'refund',
  红包: 'redpacket',
  其他收入: 'other-income',
}

export function categoryTone(category: string): string {
  return CATEGORY_TONE[category as LedgerCategory] ?? 'other'
}

/**
 * 图表用的分类颜色。
 *
 * 与 `.ledger-dot--*` 的色阶保持同一套值，SVG 里直接当 fill / stroke 使用。
 * 用 CSS 变量而非硬编码，深浅色主题切换时图表会一起变。
 */
const CATEGORY_COLOR: Record<LedgerCategory, string> = {
  餐饮: 'var(--warning)',
  购物: 'var(--accent)',
  交通: '#32ade6',
  居家: 'var(--success)',
  娱乐: '#af52de',
  医疗: 'var(--danger)',
  未分类: 'var(--label-3)',
  工资: 'var(--success)',
  奖金: '#ffb020',
  报销: 'var(--accent)',
  退款: '#32ade6',
  红包: 'var(--danger)',
  其他收入: 'var(--label-3)',
}

export function categoryColor(category: string): string {
  return CATEGORY_COLOR[category as LedgerCategory] ?? 'var(--label-3)'
}

/**
 * 分 → 展示金额。
 *
 * 整数元不显示小数（¥1,286），有角分时最多两位（¥12.34）。
 */
export function formatYuan(cents: number): string {
  const value = (cents || 0) / 100
  const text = value.toLocaleString('zh-CN', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })
  return `¥${text}`
}

/** 带方向的金额：支出 -，收入 +。 */
export function formatSignedYuan(type: string, cents: number): string {
  return `${type === 'income' ? '+' : '-'}${formatYuan(cents)}`
}

/** 把用户输入的人民币金额转成分；非法输入返回 null。 */
export function parseYuanToCents(input: string): number | null {
  const match = /^[¥￥]?\s*(\d+(?:\.\d{1,2})?)\s*(?:元|块)?$/.exec(input.trim())
  if (!match) return null
  return Math.round(Number(match[1]) * 100)
}

/** 当前月份，格式 YYYY-MM。 */
export function currentMonth(now = new Date()): string {
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}`
}

/** 月份加减，delta 为月数。 */
export function shiftMonth(month: string, delta: number): string {
  const [year, mon] = month.split('-').map(Number)
  const date = new Date(year, mon - 1 + delta, 1)
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}`
}

/**
 * 某个月的本地时间区间 `[from, to)`，带时区偏移。
 *
 * 后端按 OffsetDateTime 比较 occurred_at，这里显式带 `+08:00` 之类的偏移，
 * 避免用 UTC 边界导致月初 / 月末错位。
 */
export function monthRange(month: string): { from: string; to: string } {
  const [year, mon] = month.split('-').map(Number)
  return {
    from: toLocalIso(new Date(year, mon - 1, 1, 0, 0, 0, 0)),
    to: toLocalIso(new Date(year, mon, 1, 0, 0, 0, 0)),
  }
}

/** Date → datetime-local 输入框需要的 `YYYY-MM-DDTHH:mm`。 */
export function toLocalDateTimeInput(value: string | Date): string {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

/** datetime-local 的值 → 带本地时区偏移的 ISO，如 2026-11-13T12:30:00+08:00。 */
export function fromLocalDateTimeInput(value: string): string | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?$/.exec(value)
  if (!match) return null
  const [, year, mon, day, hour, minute, second] = match
  const date = new Date(
    Number(year),
    Number(mon) - 1,
    Number(day),
    Number(hour),
    Number(minute),
    Number(second ?? 0),
    0,
  )
  if (Number.isNaN(date.getTime())) return null
  return toLocalIso(date)
}

function toLocalIso(date: Date): string {
  const offsetMinutes = -date.getTimezoneOffset()
  const sign = offsetMinutes >= 0 ? '+' : '-'
  const abs = Math.abs(offsetMinutes)
  return (
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}` +
    `${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`
  )
}

function pad(value: number): string {
  return String(value).padStart(2, '0')
}