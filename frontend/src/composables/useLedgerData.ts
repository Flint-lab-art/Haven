/**
 * 记账页的月度数据加载。
 *
 * 负责「按月份 + 分类筛选」拉汇总与明细，并处理两个容易出错的点：
 *
 * - **竞态**：快速切月份时，旧请求可能晚于新请求返回，用请求序号丢弃过期响应
 * - **非法月份**：手动输入了 `abc` 这类值时直接跳过，不发请求
 */
import { ref, type Ref } from 'vue'
import {
  getLedgerSummary,
  listLedgerEntries,
  type LedgerCategory,
  type LedgerEntry,
  type LedgerSummary,
} from '@/api/ledger'
import { monthRange } from '@/utils/ledger'

/** 明细一次取多少条。 */
const PAGE_SIZE = 100

export interface LedgerDataOptions {
  /** 当前月份，格式 `YYYY-MM`。 */
  month: Ref<string>
  /** 分类筛选；空串表示不筛。 */
  categoryFilter: Ref<LedgerCategory | ''>
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
  /** 就地替换一条明细（改分类 / 保存后免整页刷新）。 */
  applyEntry: (updated: LedgerEntry) => void
}

/** 月份格式校验；非法值直接跳过请求，避免后端 422。 */
export function isValidMonth(value: string): boolean {
  return /^\d{4}-\d{2}$/.test(value)
}

export function useLedgerData(options: LedgerDataOptions): LedgerData {
  const { month, categoryFilter, error } = options

  const summary = ref<LedgerSummary | null>(null)
  const entries = ref<LedgerEntry[]>([])
  const total = ref(0)
  const loadingSummary = ref(false)
  const loadingEntries = ref(false)

  /** 明细请求序号：切月份/分类时丢弃过期响应。 */
  let entriesSeq = 0

  async function loadSummary(): Promise<void> {
    if (!isValidMonth(month.value)) return
    loadingSummary.value = true
    try {
      summary.value = await getLedgerSummary(month.value)
    } catch (err) {
      error.value = options.messageOf(err, '汇总加载失败')
    } finally {
      loadingSummary.value = false
    }
  }

  async function loadEntries(): Promise<void> {
    if (!isValidMonth(month.value)) return
    const seq = ++entriesSeq
    loadingEntries.value = true
    const { from, to } = monthRange(month.value)
    try {
      const result = await listLedgerEntries({
        from,
        to,
        category: categoryFilter.value || undefined,
        limit: PAGE_SIZE,
        offset: 0,
      })
      // 过期响应直接丢弃，否则快速切月份会看到上一个月的明细
      if (seq !== entriesSeq) return
      entries.value = result.items
      total.value = result.total
    } catch (err) {
      if (seq !== entriesSeq) return
      error.value = options.messageOf(err, '明细加载失败')
    } finally {
      if (seq === entriesSeq) loadingEntries.value = false
    }
  }

  async function reload(): Promise<void> {
    error.value = ''
    await Promise.all([loadSummary(), loadEntries()])
  }

  function applyEntry(updated: LedgerEntry): void {
    const index = entries.value.findIndex((item) => item.id === updated.id)
    if (index < 0) return
    const next = [...entries.value]
    next[index] = updated
    entries.value = next
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
  }
}
