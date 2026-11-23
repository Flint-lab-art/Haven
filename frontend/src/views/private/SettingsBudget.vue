<script setup lang="ts">
/**
 * 设置 · 预算（PC）。
 *
 * 按月设置各一级分类的预算上限。总预算 = 各项之和，不单独存。
 *
 * 为什么要选月份：预算按月独立，10 月的记录不会因为改了 11 月而变。
 * 想「沿用上个月」时，切到上个月看一眼数字再填即可——
 * 做成「一键复制上月」反而容易把忘记调整的预算带进新月份。
 */
import { computed, onMounted, ref, watch } from 'vue'
import { ApiError } from '@/api/client'
import {
  deleteBudget,
  getBudget,
  listCategories,
  upsertBudget,
  type Budget,
  type Category,
} from '@/api/ledger'
import { currentMonth, formatYuan, monthLabel, parseYuanToCents, shiftMonth } from '@/utils/ledger'
import { ChevronLeft, ChevronRight } from 'lucide-vue-next'

const month = ref(currentMonth())
const loading = ref(true)
const error = ref('')
const toast = ref('')

const budget = ref<Budget | null>(null)
const categories = ref<Category[]>([])

/** 每个一级分类的输入值（元）；空串表示没有预算。 */
const inputs = ref<Record<number, string>>({})
const saving = ref<Record<number, boolean>>({})

/** 只有支出分类能设预算。 */
const expenseRoots = computed(() => categories.value.filter((c) => c.kind === 'expense'))

/** 已设预算的分类 id 集合，用于标记「已设置」。 */
const configured = computed(() => new Set((budget.value?.items ?? []).map((i) => i.category_id)))

/** 总预算 = 各项输入之和（实时算，包含还没保存的编辑）。 */
const totalInputCents = computed(() => {
  let sum = 0
  for (const root of expenseRoots.value) {
    const cents = parseYuanToCents(inputs.value[root.id] ?? '')
    if (cents != null) sum += cents
  }
  return sum
})

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const [b, cats] = await Promise.all([getBudget(month.value), listCategories()])
    budget.value = b
    if (categories.value.length === 0) categories.value = cats

    // 用已设的预算回填输入框
    const next: Record<number, string> = {}
    for (const root of expenseRoots.value) {
      const item = b.items.find((i) => i.category_id === root.id)
      next[root.id] = item ? String(item.amount_cents / 100) : ''
    }
    inputs.value = next
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '预算加载失败'
  } finally {
    loading.value = false
  }
}

/** 保存单个分类的预算；输入为空则删除。 */
async function save(rootId: number): Promise<void> {
  if (saving.value[rootId]) return
  const raw = (inputs.value[rootId] ?? '').trim()
  saving.value = { ...saving.value, [rootId]: true }
  error.value = ''

  try {
    if (raw === '') {
      // 空输入 = 取消这一项的预算
      if (configured.value.has(rootId)) {
        await deleteBudget(rootId, month.value)
      }
    } else {
      const cents = parseYuanToCents(raw)
      if (cents == null || cents <= 0) {
        error.value = '金额需为大于 0 的数字'
        return
      }
      await upsertBudget(rootId, month.value, cents)
    }
    await refresh()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '保存失败'
  } finally {
    saving.value = { ...saving.value, [rootId]: false }
  }
}

/** 只重拉预算，不重置输入框（否则正在编辑的项会被清掉）。 */
async function refresh(): Promise<void> {
  try {
    budget.value = await getBudget(month.value)
    toast.value = '已保存'
    setTimeout(() => (toast.value = ''), 1500)
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '刷新失败'
  }
}

async function stepMonth(delta: number): Promise<void> {
  month.value = shiftMonth(month.value, delta)
  await load()
}

watch(month, () => void load())
onMounted(load)
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">预算</h1>
      <p class="detail-sub">按月设为各支出分类的上限；总预算 = 各项之和</p>
    </header>

    <div class="ledger-toolbar">
      <div class="ledger-month">
        <button class="icon-btn" type="button" aria-label="上个月" @click="stepMonth(-1)">
          <ChevronLeft aria-hidden="true" />
        </button>
        <span class="ledger-month__label">{{ monthLabel(month) }}</span>
        <button class="icon-btn" type="button" aria-label="下个月" @click="stepMonth(1)">
          <ChevronRight aria-hidden="true" />
        </button>
      </div>
      <span class="field__hint">合计 {{ formatYuan(totalInputCents) }}</span>
    </div>

    <p v-if="error" class="notice notice--error ledger-notice">{{ error }}</p>
    <p v-if="toast" class="notice notice--success ledger-notice">{{ toast }}</p>

    <div v-if="loading" class="panel panel--pad">
      <div class="skeleton skeleton--title" style="width: 40%"></div>
    </div>

    <ul v-else class="panel rows">
      <li v-for="root in expenseRoots" :key="root.id" class="row-item budget-row">
        <span class="cat-icon budget-row__icon" aria-hidden="true">{{ root.icon }}</span>

        <div class="row-item__main">
          <div class="row-item__title">
            {{ root.name }}
            <span v-if="configured.has(root.id)" class="badge badge--public">已设置</span>
          </div>
          <div class="row-item__sub">
            <template v-if="budget">
              <template v-for="item in budget.items.filter((i) => i.category_id === root.id)" :key="item.category_id">
                已花 {{ formatYuan(item.spent_cents) }} · 剩 {{ formatYuan(item.remaining_cents) }}
              </template>
            </template>
            <span v-else>还没有支出</span>
          </div>
        </div>

        <input
          v-model="inputs[root.id]"
          class="input budget-row__input"
          type="text"
          inputmode="decimal"
          placeholder="不设"
          :aria-label="`${root.name}的预算`"
          @keydown.enter="save(root.id)"
          @blur="save(root.id)"
        />
        <span class="budget-row__unit">元</span>
      </li>
    </ul>

    <p class="field__hint" style="margin-top: 12px">
      输入金额后失焦或按回车即保存；清空输入框可取消该项预算。
    </p>
  </div>
</template>
