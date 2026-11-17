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
import LedgerDonutChart from '@/components/LedgerDonutChart.vue'
import LedgerTrendChart from '@/components/LedgerTrendChart.vue'
import { ApiError } from '@/api/client'
import { useLedgerData } from '@/composables/useLedgerData'
import {
  createLedgerBatch,
  deleteLedgerEntry,
  quickParse,
  updateLedgerEntry,
  type CreateLedgerEntryInput,
  type LedgerCategory,
  type LedgerEntry,
  type QuickParseResult,
} from '@/api/ledger'
import { formatDateTime, formatRelative } from '@/utils/format'
import {
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

const quickText = ref('')
const parsing = ref(false)
const saving = ref(false)
const parseResult = ref<QuickParseResult | null>(null)

const editTarget = ref<LedgerEntry | null>(null)
/** 编辑弹窗是否打开；与 editTarget 分开，关闭时保留 target 避免退场动画期间内容闪空。 */
const editDialogOpen = ref(false)

const deleting = ref<LedgerEntry | null>(null)
const deletingBusy = ref(false)

let toastTimer: number | undefined

const parsedItems = computed(() => parseResult.value?.items ?? [])
const parseErrors = computed(() => parseResult.value?.errors ?? [])
const ranking = computed(() =>
  rankType.value === 'income'
    ? (summary.value?.income_category_ranking ?? [])
    : (summary.value?.category_ranking ?? []),
)
const recent = computed(() => summary.value?.recent ?? [])
/** 当月每日走势；后端已按天补零。 */
const dailyPoints = computed(() => summary.value?.daily ?? [])
const donutLabel = computed(() => (rankType.value === 'income' ? '收入' : '支出'))
const maxRankAmount = computed(() =>
  Math.max(1, ...ranking.value.map((item) => item.amount_cents)),
)
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

/** 解析预览里的发生日期，如「11月16日」。 */
function shortDate(value: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return `${date.getMonth() + 1}月${date.getDate()}日`
}

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

async function doParse(): Promise<void> {
  const text = quickText.value.trim()
  if (!text || parsing.value) return

  parsing.value = true
  error.value = ''
  try {
    parseResult.value = await quickParse(text)
    if (parseResult.value.items.length === 0 && parseResult.value.errors.length === 0) {
      notify('没有解析出内容')
    }
  } catch (err) {
    error.value = messageOf(err, '解析失败')
  } finally {
    parsing.value = false
  }
}

async function confirmWrite(): Promise<void> {
  const result = parseResult.value
  if (!result || result.items.length === 0 || saving.value) return

  saving.value = true
  error.value = ''
  try {
    const items: CreateLedgerEntryInput[] = result.items.map((item) => ({
      type: item.type,
      amount_cents: item.amount_cents,
      category: item.category,
      note: item.note,
      occurred_at: item.occurred_at,
    }))
    const batch = await createLedgerBatch({
      batch_id: newBatchId(),
      raw_text: quickText.value,
      items,
    })
    const otherMonth = result.items.filter(
      (item) => item.occurred_at.slice(0, 7) !== month.value,
    ).length
    notify(
      otherMonth > 0
        ? `已记录 ${batch.total} 笔，其中 ${otherMonth} 笔在其他月份`
        : `已记录 ${batch.total} 笔`,
    )
    quickText.value = ''
    parseResult.value = null
    await reload()
  } catch (err) {
    error.value = messageOf(err, '写入失败')
  } finally {
    saving.value = false
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

    <section class="ledger-summary" aria-label="月度汇总">
      <div class="ledger-total">
        <span class="ledger-total__label">{{ monthLabel }}支出</span>
        <span v-if="loadingSummary && !summary" class="skeleton skeleton--title ledger-total__skeleton"></span>
        <span v-else class="ledger-total__value">{{ formatYuan(summary?.total_expense_cents ?? 0) }}</span>
        <span class="ledger-total__meta">
          收入 {{ formatYuan(summary?.total_income_cents ?? 0) }}
          <span aria-hidden="true">·</span>
          {{ summary?.total_count ?? 0 }} 笔
        </span>
      </div>

      <div class="ledger-ranking">
        <div class="ledger-card-head">
          <h2 class="ledger-card__title">分类排行</h2>
          <div class="ledger-rank-toggle" role="tablist" aria-label="排行方向">
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
        <p v-if="!ranking.length" class="ledger-muted">
          {{ rankType === 'income' ? '这个月还没有收入记录。' : '这个月还没有支出记录。' }}
        </p>
        <div v-for="item in ranking" :key="item.category" class="ledger-rank">
          <span class="ledger-rank__name">
            <i class="ledger-dot" :class="`ledger-dot--${categoryTone(item.category)}`" aria-hidden="true"></i>
            {{ item.category }}
          </span>
          <span class="ledger-rank__track" aria-hidden="true">
            <span
              class="ledger-rank__bar"
              :class="`ledger-dot--${categoryTone(item.category)}`"
              :style="{ width: `${Math.max(6, (item.amount_cents / maxRankAmount) * 100)}%` }"
            ></span>
          </span>
          <span class="ledger-rank__amount">{{ formatYuan(item.amount_cents) }}</span>
        </div>
      </div>
    </section>

    <div class="ledger-columns">
      <section class="ledger-card">
        <div class="ledger-card-head">
          <h2 class="ledger-card__title">快速记一笔</h2>
          <span class="ledger-kbd">⌘ / Ctrl + Enter 解析</span>
        </div>
        <p class="field__hint">
          一行一条：[日期] 分类 [备注…] 金额。日期可写 11月16 / 2026-11-16 / 昨天，不写就是今天；
          金额支持 12 / 12.5 / 32元 / ¥32 / 二十五块，工资、奖金等自动判为收入。
        </p>
        <textarea
          v-model="quickText"
          class="textarea ledger-quick__input"
          placeholder="午饭12&#10;晚饭 20&#10;11月16 午餐 16&#10;昨天 打车 25&#10;工资 8000"
          aria-label="记账输入"
          @keydown.meta.enter.prevent="doParse"
          @keydown.ctrl.enter.prevent="doParse"
        ></textarea>
        <div class="ledger-quick__actions">
          <button
            class="btn"
            type="button"
            :disabled="parsing || !quickText.trim()"
            @click="doParse"
          >
            {{ parsing ? '解析中…' : '解析预览' }}
          </button>
          <button
            v-if="parsedItems.length"
            class="btn btn--primary"
            type="button"
            :disabled="saving"
            @click="confirmWrite"
          >
            {{ saving ? '写入中…' : `确认写入 ${parsedItems.length} 笔` }}
          </button>
        </div>

        <div v-if="parseResult" class="ledger-parse" aria-live="polite">
          <div v-for="item in parsedItems" :key="item.line" class="ledger-parse__row">
            <span class="ledger-parse__date">{{ shortDate(item.occurred_at) }}</span>
            <span class="ledger-cat" :class="`ledger-cat--${categoryTone(item.category)}`">
              {{ item.category }}
            </span>
            <span class="ledger-parse__note">{{ item.note || '（无备注）' }}</span>
            <span class="ledger-parse__amount" :class="{ 'is-income': item.type === 'income' }">
              {{ formatSignedYuan(item.type, item.amount_cents) }}
            </span>
          </div>
          <ul v-if="parseErrors.length" class="ledger-parse__errors">
            <li v-for="err in parseErrors" :key="err.line">
              第 {{ err.line }} 行：{{ err.message }}
              <span v-if="err.raw" class="muted">（{{ err.raw }}）</span>
            </li>
          </ul>
          <p v-if="!parsedItems.length && !parseErrors.length" class="ledger-muted">
            没有可写入的内容。
          </p>
        </div>
      </section>

      <section class="ledger-card">
        <div class="ledger-card-head">
          <h2 class="ledger-card__title">最近 3 笔</h2>
          <span class="muted">按录入时间</span>
        </div>
        <p class="field__hint">刚记的会出现在这里，兼作「记上了没有」的确认。</p>
        <p v-if="!recent.length" class="ledger-muted">还没有记录。</p>
        <div v-for="entry in recent" :key="entry.id" class="ledger-recent__row">
          <span class="ledger-cat" :class="`ledger-cat--${categoryTone(entry.category)}`">
            {{ entry.category }}
          </span>
          <span class="ledger-recent__note">{{ entry.note || '（无备注）' }}</span>
          <span class="ledger-recent__amount" :class="{ 'is-income': entry.type === 'income' }">
            {{ formatSignedYuan(entry.type, entry.amount_cents) }}
          </span>
          <span class="ledger-recent__time">{{ formatRelative(entry.created_at) }}</span>
        </div>
      </section>
    </div>

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
          <span class="muted">按{{ donutLabel }}</span>
        </div>
        <LedgerDonutChart :items="ranking" :label="donutLabel" />
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

      <p class="field__hint ledger-entries__hint">
        改分类会自动记住备注里的第一个词，下次输入直接命中。
      </p>

      <div v-if="loadingEntries && entries.length === 0" class="ledger-entry-list" aria-busy="true">
        <div v-for="i in 4" :key="i" class="ledger-entry ledger-entry--skeleton">
          <span class="skeleton" style="width: 86px; height: 14px"></span>
          <span class="skeleton" style="width: 64px; height: 26px"></span>
          <span class="skeleton" style="width: 40%; height: 14px"></span>
          <span class="skeleton" style="width: 64px; height: 14px"></span>
        </div>
      </div>

      <div v-else-if="entries.length === 0" class="ledger-empty">
        <p class="ledger-empty__title">这个月还没有记录</p>
        <p class="ledger-empty__text">
          {{ categoryFilter ? '换个分类看看，或者在左边记一笔。' : '在左边输入「午饭12」，先试试解析。' }}
        </p>
      </div>

      <div v-else class="ledger-entry-list">
        <div v-for="entry in entries" :key="entry.id" class="ledger-entry">
          <span class="ledger-entry__date">{{ formatDateTime(entry.occurred_at) }}</span>
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