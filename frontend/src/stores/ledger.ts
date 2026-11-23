/**
 * 记账页的共享状态（PC 三栏布局用）。
 *
 * 为什么需要 store：明细在中间栏、汇总与账户在右侧详情区，
 * 两个组件都要读同一份「月份 / 筛选 / 数据」，还要一起刷新。
 * 放页面局部 ref 会变成层层 props/emit，不如 store 直接。
 *
 * 移动端不用这个 store：它的数据都在一个页面里，局部 ref 更简单。
 */
import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { ApiError } from '@/api/client'
import {
  deleteEntry,
  getBudget,
  listAccounts,
  listCategories,
  type Account,
  type Budget,
  type Category,
  type LedgerEntry,
} from '@/api/ledger'
import { toast } from '@/composables/useToast'
import { useLedgerData } from '@/composables/useLedgerData'
import { currentMonth } from '@/utils/ledger'

export const useLedgerStore = defineStore('ledger', () => {
  // ── 筛选条件 ──
  const month = ref(currentMonth())
  const typeFilter = ref<'' | 'expense' | 'income' | 'transfer'>('')
  const categoryId = ref<number | null>(null)
  const accountId = ref<string | null>(null)

  // ── 基础数据 ──
  const accounts = ref<Account[]>([])
  const categories = ref<Category[]>([])
  const budget = ref<Budget | null>(null)

  const error = ref('')
  const initialized = ref(false)

  /** 右侧正在编辑的流水 id；null 表示没开对话框。 */
  const editingId = ref<string | null>(null)
  /** 对话框开关（新建时为 true 且 editingId 为 null）。 */
  const dialogOpen = ref(false)

  const data = useLedgerData({
    month,
    typeFilter,
    categoryId,
    accountId,
    error,
    messageOf: (err, fallback) => (err instanceof ApiError ? err.message : fallback),
  })

  /** 分类 id → { 图标, 名称 }。 */
  const categoryMeta = computed(() => {
    const map = new Map<number, { icon: string; name: string }>()
    for (const root of categories.value) {
      map.set(root.id, { icon: root.icon, name: root.name })
      for (const child of root.children) {
        map.set(child.id, { icon: child.icon, name: child.name })
      }
    }
    return map
  })

  /** 未归档账户。 */
  const activeAccounts = computed(() => accounts.value.filter((a) => !a.archived))

  /** 预算进度百分比。 */
  const budgetPercent = computed(() => {
    const b = budget.value
    if (!b || b.total_budget_cents <= 0) return 0
    return Math.min(100, Math.round((b.total_spent_cents / b.total_budget_cents) * 100))
  })

  const budgetOver = computed(
    () => !!budget.value && budget.value.total_spent_cents > budget.value.total_budget_cents,
  )

  // ── 加载 ──

  async function loadAccounts(): Promise<void> {
    try {
      accounts.value = await listAccounts()
    } catch (err) {
      error.value = err instanceof ApiError ? err.message : '账户加载失败'
    }
  }

  async function loadCategories(): Promise<void> {
    try {
      categories.value = await listCategories()
    } catch (err) {
      error.value = err instanceof ApiError ? err.message : '分类加载失败'
    }
  }

  async function loadBudget(): Promise<void> {
    try {
      budget.value = await getBudget(month.value)
    } catch {
      // 预算加载失败不影响主流程
      budget.value = null
    }
  }

  /** 首屏加载：分类只拉一次。 */
  async function init(): Promise<void> {
    if (initialized.value) {
      await refresh()
      return
    }
    await Promise.all([loadCategories(), refresh()])
    initialized.value = true
  }

  /** 刷新账户、明细、汇总、预算。 */
  async function refresh(): Promise<void> {
    await Promise.all([loadAccounts(), data.reload(), loadBudget()])
  }

  /** 切月份后重新拉数据。 */
  async function setMonth(next: string): Promise<void> {
    month.value = next
    await refresh()
  }

  /** 改筛选条件后只重拉明细与汇总。 */
  async function applyFilters(): Promise<void> {
    await data.reload()
  }

  /** 删除一条流水。 */
  async function remove(entry: LedgerEntry): Promise<void> {
    error.value = ''
    try {
      await deleteEntry(entry.id)
      data.removeEntry(entry.id)
      toast.success('已删除')
      await refresh()
    } catch (err) {
      error.value = err instanceof ApiError ? err.message : '删除失败'
    }
  }

  /** 短暂的成功提示：走全局 toast，不再自己维护定时器。 */
  function flash(message: string): void {
    toast.success(message)
  }

  return {
    month,
    typeFilter,
    categoryId,
    accountId,
    accounts,
    categories,
    budget,
    error,
    editingId,
    dialogOpen,
    categoryMeta,
    activeAccounts,
    budgetPercent,
    budgetOver,
    summary: data.summary,
    entries: data.entries,
    total: data.total,
    loadingSummary: data.loadingSummary,
    loadingEntries: data.loadingEntries,
    init,
    refresh,
    setMonth,
    applyFilters,
    remove,
    flash,
  }
})
