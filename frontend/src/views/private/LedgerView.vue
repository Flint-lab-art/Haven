<script setup lang="ts">
/**
 * 记账页（PWA /ledger）。
 *
 * 三层信息：
 * 1. 月度汇总：本月支出、收入、分类排行；
 * 2. 快速记一笔：多行文本 → 解析预览 → 确认写入（batch_id 幂等）；
 * 3. 明细：按月 / 分类筛选，改分类即自动记忆别名，可改金额与时间、删除。
 */
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import ConfirmDialog from '@/components/common/ConfirmDialog.vue'
import LedgerEditDialog from '@/components/ledger/LedgerEditDialog.vue'
import LedgerQuickDialog from '@/components/ledger/LedgerQuickDialog.vue'
import LedgerShareChart from '@/components/ledger/LedgerShareChart.vue'
import LedgerTrendChart from '@/components/LedgerTrendChart.vue'
import { ApiError } from '@/api/client'
import { useLedgerData } from '@/composables/useLedgerData'
import {
  createLedgerBatch,
  deleteLedgerEntry,
  updateLedgerEntry,
  type CreateLedgerEntryInput,
  type LedgerCategory,
  type LedgerEntry,
  type QuickParseResult,
} from '@/api/ledger'
import { groupByDay, relativeDayLabel } from '@/utils/ledger-group'
import {
  EXPENSE_CATEGORIES,
  INCOME_CATEGORIES,
  LEDGER_CATEGORIES,
  categoriesForType,
  categoryTone,
  currentMonth,
  formatSignedYuan,
  formatYuan,
  shiftMonth,
} from '@/utils/ledger'

const month = ref(currentMonth())
const categoryFilter = ref<LedgerCategory | ''>('')
const rankType = ref<'expense' | 'income'>('expense')

const error = ref('')
const toast = ref('')

// 月度数据：汇总与明细，含请求竞态处理
const {
  summary,
  entries,
  total,
  loadingSummary,
  loadingEntries,
  loadSummary,
  loadEntries,
  reload,
  applyEntry,
} = useLedgerData({
  month,
  categoryFilter,
  error,
  messageOf: (err, fallback) => messageOf(err, fallback),
})

/** 明细按天分组；同一天内按时间倒序，带当日小计。 */
const dayGroups = computed(() => groupByDay(entries.value))

/** 明细行只显示时刻，日期已在分组标题里。 */
function timeOf(value: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
}

/** 快速记账弹窗开关。 */
const quickOpen = ref(false)

const editTarget = ref<LedgerEntry | null>(null)
/** 编辑弹窗是否打开；与 editTarget 分开，关闭时保留 target 避免退场动画期间内容闪空。 */
const editDialogOpen = ref(false)

const deleting = ref<LedgerEntry | null>(null)
const deletingBusy = ref(false)

let toastTimer: number | undefined

const ranking = computed(() =>
  rankType.value === 'income'
    ? (summary.value?.income_category_ranking ?? [])
    : (summary.value?.category_ranking ?? []),
)
/** 当月每日走势；后端已按天补零。 */
const dailyPoints = computed(() => summary.value?.daily ?? [])
const donutLabel = computed(() => (rankType.value === 'income' ? '收入' : '支出'))
const monthLabel = computed(() => {
  const [year, mon] = month.value.split('-')
  return `${year} 年 ${Number(mon)} 月`
})
const deleteMessage = computed(() => {
  const entry = deleting.value
  if (!entry) return ''
  const note = entry.note?.trim() || entry.category
  return `删除「${note}」这笔 ${formatYuan(entry.amount_cents)} 的记录？删除后无法恢复。`
})


function notify(message: string): void {
  toast.value = message
  if (toastTimer !== undefined) window.clearTimeout(toastTimer)
  toastTimer = window.setTimeout(() => {
    toast.value = ''
    toastTimer = undefined
  }, 2600)
}

function messageOf(err: unknown, fallback: string): string {
  if (err instanceof ApiError) {
    if (err.fields) return Object.values(err.fields).join('；')
    return err.message
  }
  return fallback
}

function changeMonth(delta: number): void {
  month.value = shiftMonth(month.value, delta)
}

/**
 * 弹窗确认写入。
 *
 * 写库留在页面里而不是弹窗内：只有页面知道当前月份、reload、toast 这些上下文。
 * 弹窗只负责收集输入与预览，通过 done(ok) 告诉它结果。
 */
async function onQuickCommit(items: QuickParseResult['items'], done: (ok: boolean) => void): Promise<void> {
  try {
    const payload: CreateLedgerEntryInput[] = items.map((item) => ({
      type: item.type,
      amount_cents: item.amount_cents,
      category: item.category,
      note: item.note,
      occurred_at: item.occurred_at,
    }))
    const batch = await createLedgerBatch({
      batch_id: newBatchId(),
      raw_text: items.map((item) => item.raw).join('\n'),
      items: payload,
    })
    // 记到了别的月份时提示一下，否则用户会以为「记了但没显示」
    const otherMonth = items.filter((item) => item.occurred_at.slice(0, 7) !== month.value).length
    notify(
      otherMonth > 0
        ? `已记录 ${batch.total} 笔，其中 ${otherMonth} 笔在其他月份`
        : `已记录 ${batch.total} 笔`,
    )
    await reload()
    done(true)
  } catch (err) {
    error.value = messageOf(err, '写入失败')
    done(false)
  }
}

/**
 * 设置收支方向（分段按钮点选）。
 *
 * 方向变了但分类还停在旧方向的白名单里（例如「餐饮」配 income），
 * 后端会拒绝保存，所以这里同时把分类切到新方向下的第一个可选值。
 */
async function setEntryType(entry: LedgerEntry, nextType: 'expense' | 'income'): Promise<void> {
  if (nextType === entry.type) return

  // 注意：不能用 categoriesForType(nextType, entry.category)，它会把当前分类
  // 当作「历史脏数据」补进列表末尾，导致「餐饮」在收入方向下仍是合法值。
  // 切换方向时必须是该方向的干净白名单。
  const allowed: LedgerCategory[] = nextType === 'income' ? INCOME_CATEGORIES : EXPENSE_CATEGORIES
  const nextCategory = allowed.includes(entry.category) ? entry.category : allowed[0]
  if (!nextCategory) return

  const previousType = entry.type
  const previousCategory = entry.category
  entry.type = nextType
  entry.category = nextCategory
  try {
    const updated = await updateLedgerEntry(entry.id, { type: nextType, category: nextCategory })
    applyEntry(updated)
    notify(nextType === 'income' ? '已改为收入' : '已改为支出')
    await loadSummary()
  } catch (err) {
    entry.type = previousType
    entry.category = previousCategory
    error.value = messageOf(err, '收支方向更新失败')
  }
}

async function onCategoryChange(entry: LedgerEntry, event: Event): Promise<void> {
  const select = event.target as HTMLSelectElement
  const next = select.value as LedgerCategory
  if (!next || next === entry.category) return

  const previous = entry.category
  entry.category = next
  try {
    const updated = await updateLedgerEntry(entry.id, { category: next })
    applyEntry(updated)
    notify('分类已更新，备注首词已记住')
    await loadSummary()
  } catch (err) {
    entry.category = previous
    select.value = previous
    error.value = messageOf(err, '分类更新失败')
  }
}

function openEdit(entry: LedgerEntry): void {
  editTarget.value = entry
  editDialogOpen.value = true
}

/** 弹窗保存成功：把服务端返回的新值同步进列表，再刷新汇总。 */
async function onEditSaved(updated: LedgerEntry): Promise<void> {
  applyEntry(updated)
  notify('已保存')
  await reload()
}

async function confirmDelete(): Promise<void> {
  const entry = deleting.value
  if (!entry || deletingBusy.value) return

  deletingBusy.value = true
  try {
    await deleteLedgerEntry(entry.id)
    entries.value = entries.value.filter((item) => item.id !== entry.id)
    total.value = Math.max(0, total.value - 1)
    deleting.value = null
    notify('已删除')
    await loadSummary()
  } catch (err) {
    error.value = messageOf(err, '删除失败')
  } finally {
    deletingBusy.value = false
  }
}

function newBatchId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
}

watch(month, () => void reload())
watch(categoryFilter, () => void loadEntries())

onMounted(() => void reload())
onBeforeUnmount(() => {
  if (toastTimer !== undefined) window.clearTimeout(toastTimer)
})
</script>

<template>
  <div class="ledger-page">
    <header class="ledger-header">
      <div>
        <h1 class="ledger-title">记账</h1>
        <p class="ledger-sub">一行一笔，确认后写入；分类随时可改。</p>
      </div>
      <div class="ledger-month">
        <button class="icon-btn" type="button" aria-label="上个月" @click="changeMonth(-1)">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="m15 6-6 6 6 6" />
          </svg>
        </button>
        <input v-model="month" class="input ledger-month__input" type="month" aria-label="选择月份" />
        <button class="icon-btn" type="button" aria-label="下个月" @click="changeMonth(1)">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="m9 6 6 6-6 6" />
          </svg>
        </button>
      </div>
    </header>

    <p v-if="error" class="notice notice--error ledger-notice">
      {{ error }}
      <span class="notice__actions">
        <button class="btn btn--sm" type="button" @click="reload">重试</button>
      </span>
    </p>
    <p v-if="toast" class="notice notice--success ledger-notice">{{ toast }}</p>

    <!--
      月度汇总只保留三个数字。
      分类排行原本也在这里，但它与下方「分类占比」展示的是同一份数据，
      重复且让首屏必须滚动才能看到明细，所以合并进占比卡片。
    -->
    <section class="ledger-summary" aria-label="月度汇总">
      <div class="ledger-stat">
        <span class="ledger-stat__label">{{ monthLabel }}支出</span>
        <span v-if="loadingSummary && !summary" class="skeleton skeleton--title ledger-stat__skeleton"></span>
        <span v-else class="ledger-stat__value">{{ formatYuan(summary?.total_expense_cents ?? 0) }}</span>
      </div>
      <div class="ledger-stat">
        <span class="ledger-stat__label">收入</span>
        <span v-if="loadingSummary && !summary" class="skeleton skeleton--title ledger-stat__skeleton"></span>
        <span v-else class="ledger-stat__value ledger-stat__value--income">
          {{ formatYuan(summary?.total_income_cents ?? 0) }}
        </span>
      </div>
      <div class="ledger-stat">
        <span class="ledger-stat__label">笔数</span>
        <span v-if="loadingSummary && !summary" class="skeleton skeleton--title ledger-stat__skeleton"></span>
        <span v-else class="ledger-stat__value">{{ summary?.total_count ?? 0 }}</span>
      </div>
    </section>

    <!-- 统计图表：与上方汇总共用同一份数据，不再额外请求 -->
    <section class="ledger-charts" aria-label="记账统计">
      <div class="ledger-card">
        <div class="ledger-card-head">
          <h2 class="ledger-card__title">每日走势</h2>
          <span class="muted">{{ monthLabel }}</span>
        </div>
        <p v-if="!dailyPoints.length" class="ledger-muted">这个月还没有记录。</p>
        <LedgerTrendChart v-else :points="dailyPoints" />
      </div>

      <div class="ledger-card">
        <div class="ledger-card-head">
          <h2 class="ledger-card__title">分类占比</h2>
          <div class="ledger-rank-toggle" role="tablist" aria-label="占比方向">
            <button
              type="button"
              class="ledger-rank-toggle__btn"
              :class="{ 'is-active': rankType === 'expense' }"
              role="tab"
              :aria-selected="rankType === 'expense'"
              @click="rankType = 'expense'"
            >
              支出
            </button>
            <button
              type="button"
              class="ledger-rank-toggle__btn"
              :class="{ 'is-active': rankType === 'income' }"
              role="tab"
              :aria-selected="rankType === 'income'"
              @click="rankType = 'income'"
            >
              收入
            </button>
          </div>
        </div>
        <LedgerShareChart :items="ranking" :label="donutLabel" />
      </div>
    </section>

    <section class="ledger-entries" aria-label="记账明细">
      <div class="ledger-card-head ledger-entries__head">
        <div>
          <h2 class="ledger-card__title">明细</h2>
          <p class="field__hint">{{ monthLabel }} · 共 {{ total }} 笔</p>
        </div>
        <label class="ledger-filter">
          <select v-model="categoryFilter" class="select ledger-filter__select" aria-label="按分类筛选">
            <option value="">全部分类</option>
            <option v-for="category in LEDGER_CATEGORIES" :key="category" :value="category">
              {{ category }}
            </option>
          </select>
        </label>
      </div>

      <div v-if="loadingEntries && entries.length === 0" class="ledger-day-list" aria-busy="true">
        <div v-for="i in 3" :key="i" class="ledger-day">
          <div class="ledger-day__head">
            <span class="skeleton skeleton--title" style="width: 96px"></span>
          </div>
          <div v-for="j in 2" :key="j" class="ledger-entry">
            <span class="skeleton" style="width: 46px; height: 14px"></span>
            <span class="skeleton" style="width: 64px; height: 24px"></span>
            <span class="skeleton" style="width: 34%; height: 14px"></span>
            <span class="skeleton" style="width: 56px; height: 14px"></span>
          </div>
        </div>
      </div>

      <div v-else-if="dayGroups.length === 0" class="ledger-empty">
        <p class="ledger-empty__title">这个月还没有记录</p>
        <p class="ledger-empty__text">
          {{ categoryFilter ? '换个分类看看，或者点右下角记一笔。' : '点右下角的按钮，输入「午饭12」试试。' }}
        </p>
      </div>

      <!-- 按天分组：同一天的小计让「这天花了多少」一眼可见 -->
      <div v-else class="ledger-day-list">
        <section v-for="group in dayGroups" :key="group.date" class="ledger-day">
          <header class="ledger-day__head">
            <span class="ledger-day__date">{{ relativeDayLabel(group.label, group.date) }}</span>
            <span class="ledger-day__weekday">{{ group.weekday }}</span>
            <span class="ledger-day__sum">
              <span v-if="group.expenseCents" class="ledger-day__sum-item">
                支出 <strong>{{ formatYuan(group.expenseCents) }}</strong>
              </span>
              <span v-if="group.incomeCents" class="ledger-day__sum-item ledger-day__sum-item--income">
                收入 <strong>{{ formatYuan(group.incomeCents) }}</strong>
              </span>
            </span>
          </header>

          <div class="ledger-entry-list">
            <div v-for="entry in group.items" :key="entry.id" class="ledger-entry">
              <span class="ledger-entry__time">{{ timeOf(entry.occurred_at) }}</span>
              <!--
                两级选择：先定收支方向（分段按钮），再在该方向下选具体分类。
                方向做成按钮而不是下拉，是因为「支出/收入」只有两个取值，
                下拉要多点一次，且和右侧的分类下拉长得一样、看不出主次。
              -->
              <span class="ledger-entry__picker">
                <span
                  class="ledger-entry__type"
                  :class="{ 'is-income': entry.type === 'income' }"
                  role="group"
                  :aria-label="`收支方向：${entry.note || entry.category}`"
                >
                  <button
                    type="button"
                    class="ledger-entry__type-btn"
                    :class="{ 'is-active': entry.type === 'expense' }"
                    :aria-pressed="entry.type === 'expense'"
                    @click="setEntryType(entry, 'expense')"
                  >
                    支
                  </button>
                  <button
                    type="button"
                    class="ledger-entry__type-btn"
                    :class="{ 'is-active': entry.type === 'income' }"
                    :aria-pressed="entry.type === 'income'"
                    @click="setEntryType(entry, 'income')"
                  >
                    收
                  </button>
                </span>
                <select
                  class="select ledger-entry__cat"
                  :class="`ledger-entry__cat--${categoryTone(entry.category)}`"
                  :value="entry.category"
                  :aria-label="`修改分类：${entry.note || entry.category}`"
                  @change="onCategoryChange(entry, $event)"
                >
                  <option
                    v-for="category in categoriesForType(entry.type, entry.category)"
                    :key="category"
                    :value="category"
                  >
                    {{ category }}
                  </option>
                </select>
              </span>
              <span class="ledger-entry__note" :title="entry.note">{{ entry.note || '—' }}</span>
              <span class="ledger-entry__amount" :class="{ 'is-income': entry.type === 'income' }">
                {{ formatSignedYuan(entry.type, entry.amount_cents) }}
              </span>
              <button class="icon-btn ledger-entry__action" type="button" aria-label="编辑金额与时间" @click="openEdit(entry)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <path d="M4 20h4L19 9l-4-4L4 16z" />
                  <path d="m13 7 4 4" />
                </svg>
              </button>
              <button
                class="icon-btn ledger-entry__action ledger-entry__action--danger"
                type="button"
                aria-label="删除这笔记录"
                @click="deleting = entry"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13M10 11v6M14 11v6" />
                </svg>
              </button>
            </div>
          </div>
        </section>
      </div>
    </section>

    <!-- 记账是低频动作，收进悬浮按钮，把版面留给明细 -->
    <button
      class="ledger-fab"
      type="button"
      aria-label="快速记一笔"
      @click="quickOpen = true"
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
        <path d="M12 5v14M5 12h14" />
      </svg>
      <span>记一笔</span>
    </button>

    <LedgerQuickDialog
      v-model:open="quickOpen"
      @commit="onQuickCommit"
    />

    <LedgerEditDialog
      v-model:open="editDialogOpen"
      :entry="editTarget"
      @saved="onEditSaved"
    />

    <ConfirmDialog
      :open="deleting !== null"
      title="删除这笔记录？"
      :message="deleteMessage"
      :busy="deletingBusy"
      @cancel="deleting = null"
      @confirm="confirmDelete"
    />
  </div>
</template>