/**
 * 记账页的月度数据加载（PC 与移动端共用）。
 *
 * 负责「按月份 + 收支方向 + 分类筛选」拉汇总与明细，并处理两个容易出错的点：
 *
 * - **竞态**：快速切月份时，旧请求可能晚于新请求返回，用请求序号丢弃过期响应
 * - **非法月份**：手动输入了 `abc` 这类值时直接跳过，不发请求
 */
import { ref, type Ref } from 'vue'
import {
  getSummary,
  listEntries,
  type EntryType,
  type LedgerEntry,
  type LedgerSummary,
} from '@/api/ledger'

/** 明细一次取多少条。 */
const PAGE_SIZE = 100

export interface LedgerDataOptions {
  /** 当前月份，格式 `YYYY-MM`。 */
  month: Ref<string>
  /** 收支筛选；空串表示不限方向。 */
  typeFilter: Ref<'' | EntryType>
  /** 分类筛选；null 表示不筛。 */
  categoryId: Ref<number | null>
  /** 账户筛选；null 表示不筛。 */
  accountId: Ref<string | null>
  /** 把异常转成提示文案。 */
  messageOf: (err: unknown, fallback: string) => string
  /** 错误提示的写入目标。 */
  error: Ref<string>
}

export interface LedgerData {
  summary: Ref<LedgerSummary | null>
  entries: Ref<LedgerEntry[]>
  total: Ref<number>
  loadingSummary: Ref<boolean>
  loadingEntries: Ref<boolean>
  loadSummary: () => Promise<void>
  loadEntries: () => Promise<void>
  reload: () => Promise<void>
  /** 就地替换一条明细（编辑后免整页刷新）；不在列表里则忽略。 */
  applyEntry: (updated: LedgerEntry) => void
  /** 就地移除一条明细。 */
  removeEntry: (id: string) => void
}

/** 月份格式校验；非法值直接跳过请求，避免后端 422。 */
export function isValidMonth(value: string): boolean {
  return /^\d{4}-\d{2}$/.test(value)
}

/** 某个月的第一天与下个月第一天（本地时区 ISO）。 */
export function monthRange(month: string): { from: string; to: string } {
  const [y, m] = month.split('-').map(Number)
  const from = new Date(y, m - 1, 1, 0, 0, 0, 0)
  const to = new Date(y, m, 1, 0, 0, 0, 0)
  return { from: from.toISOString(), to: to.toISOString() }
}

export function useLedgerData(options: LedgerDataOptions): LedgerData {
  const { month, typeFilter, categoryId, accountId, error } = options

  const summary = ref<LedgerSummary | null>(null)
  const entries = ref<LedgerEntry[]>([])
  const total = ref(0)
  const loadingSummary = ref(false)
  const loadingEntries = ref(false)

  let summarySeq = 0
  let entriesSeq = 0

  async function loadSummary(): Promise<void> {
    if (!isValidMonth(month.value)) return
    const seq = ++summarySeq
    loadingSummary.value = true
    try {
      const data = await getSummary(month.value)
      if (seq === summarySeq) summary.value = data
    } catch (err) {
      if (seq === summarySeq) error.value = options.messageOf(err, '汇总加载失败')
    } finally {
      if (seq === summarySeq) loadingSummary.value = false
    }
  }

  async function loadEntries(): Promise<void> {
    if (!isValidMonth(month.value)) return
    const seq = ++entriesSeq
    loadingEntries.value = true
    const { from, to } = monthRange(month.value)
    try {
      const page = await listEntries({
        from,
        to,
        limit: PAGE_SIZE,
        offset: 0,
        type: typeFilter.value || undefined,
        category_id: categoryId.value ?? undefined,
        account_id: accountId.value ?? undefined,
      })
      if (seq === entriesSeq) {
        entries.value = page.items
        total.value = page.total
      }
    } catch (err) {
      if (seq === entriesSeq) error.value = options.messageOf(err, '明细加载失败')
    } finally {
      if (seq === entriesSeq) loadingEntries.value = false
    }
  }

  async function reload(): Promise<void> {
    await Promise.all([loadSummary(), loadEntries()])
  }

  function applyEntry(updated: LedgerEntry): void {
    entries.value = entries.value.map((e) => (e.id === updated.id ? updated : e))
  }

  function removeEntry(id: string): void {
    entries.value = entries.value.filter((e) => e.id !== id)
    total.value = Math.max(0, total.value - 1)
  }

  return {
    summary,
    entries,
    total,
    loadingSummary,
    loadingEntries,
    loadSummary,
    loadEntries,
    reload,
    applyEntry,
    removeEntry,
  }
}
