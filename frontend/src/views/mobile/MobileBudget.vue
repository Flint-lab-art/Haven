<script setup lang="ts">
/**
 * 移动端预算页（设置 → 预算）。
 *
 * 版式与账户页保持一致：
 * 1. 顶部「本月预算」总览卡，显示合计与已用进度；
 * 2. 每个一级分类一行，右侧输入金额；
 * 3. 有预算的显示「已花 / 剩多少」，没设的显示淡色的「不设」。
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

const budget = ref<Budget | null>(null)
const categories = ref<Category[]>([])
const inputs = ref<Record<number, string>>({})

const expenseRoots = computed(() => categories.value.filter((c) => c.kind === 'expense'))
const configured = computed(() => new Set((budget.value?.items ?? []).map((i) => i.category_id)))

/** 合计按输入框实时算，包含还没保存的编辑。 */
const totalInputCents = computed(() => {
  let sum = 0
  for (const root of expenseRoots.value) {
    const cents = parseYuanToCents(inputs.value[root.id] ?? '')
    if (cents != null) sum += cents
  }
  return sum
})

/** 已花合计（来自后端，只算已保存的预算分类）。 */
const spentCents = computed(() => budget.value?.total_spent_cents ?? 0)

/** 预算使用百分比，用于顶部进度条。 */
const usedPercent = computed(() => {
  const total = totalInputCents.value
  if (total <= 0) return 0
  return Math.min(100, Math.round((spentCents.value / total) * 100))
})

const overBudget = computed(() => totalInputCents.value > 0 && spentCents.value > totalInputCents.value)

/** 某分类是否超支。 */
function remainingOf(rootId: number): number | null {
  const item = budget.value?.items.find((i) => i.category_id === rootId)
  return item ? item.remaining_cents : null
}

function spentOf(rootId: number): number | null {
  const item = budget.value?.items.find((i) => i.category_id === rootId)
  return item ? item.spent_cents : null
}

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const [b, cats] = await Promise.all([getBudget(month.value), listCategories()])
    budget.value = b
    if (categories.value.length === 0) categories.value = cats

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

async function save(rootId: number): Promise<void> {
  const raw = (inputs.value[rootId] ?? '').trim()
  error.value = ''
  try {
    if (raw === '') {
      if (configured.value.has(rootId)) await deleteBudget(rootId, month.value)
    } else {
      const cents = parseYuanToCents(raw)
      if (cents == null || cents <= 0) {
        error.value = '金额需为大于 0 的数字'
        return
      }
      await upsertBudget(rootId, month.value, cents)
    }
    budget.value = await getBudget(month.value)
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '保存失败'
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
  <div class="m-page">
    <MobilePageHeader title="预算">
      <template #lead>
        <button class="m-icon-btn" type="button" aria-label="返回" @click="$router.back()">
        <ChevronLeft aria-hidden="true" />
        </button>
      </template>
    </MobilePageHeader>

    <!-- 月份切换 -->
    <div class="m-range">
      <button class="m-icon-btn" type="button" aria-label="上个月" @click="stepMonth(-1)">
        <ChevronLeft aria-hidden="true" />
      </button>
      <span class="m-range__label">{{ monthLabel(month) }}</span>
      <button class="m-icon-btn" type="button" aria-label="下个月" @click="stepMonth(1)">
        <ChevronRight aria-hidden="true" />
      </button>
    </div>

    <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

    <!-- 总览：合计预算 + 已用进度 -->
    <section class="m-total" aria-label="本月预算">
      <span class="m-total__label">预算合计</span>
      <span class="m-total__value" :class="{ 'm-total__value--negative': overBudget }">
        {{ formatYuan(totalInputCents) }}
      </span>
      <div class="m-total__bar">
        <div
          class="m-total__fill"
          :class="{ 'm-total__fill--over': overBudget }"
          :style="{ transform: `scaleX(${usedPercent / 100})` }"
        ></div>
      </div>
      <p class="m-total__meta">
        已花 {{ formatYuan(spentCents) }}
        <span class="m-total__dot">·</span>
        {{ overBudget ? '已超支' : `剩 ${formatYuan(totalInputCents - spentCents)}` }}
      </p>
    </section>

    <div v-if="loading" class="m-skeleton">
      <div class="skeleton skeleton--title" style="width: 60%"></div>
    </div>

    <ul v-else class="m-card m-budget-list">
      <li v-for="root in expenseRoots" :key="root.id" class="m-budget-item">
        <span class="cat-icon m-budget-item__icon" aria-hidden="true">{{ root.icon }}</span>

        <div class="m-budget-item__body">
          <span class="m-budget-item__name">{{ root.name }}</span>
          <span
            class="m-budget-item__sub"
            :class="{ 'm-budget-item__sub--over': (remainingOf(root.id) ?? 0) < 0 }"
          >
            <template v-if="configured.has(root.id)">
              已花 {{ formatYuan(spentOf(root.id) ?? 0) }} ·
              <template v-if="(remainingOf(root.id) ?? 0) >= 0">
                剩 {{ formatYuan(remainingOf(root.id) ?? 0) }}
              </template>
              <template v-else>超 {{ formatYuan(-(remainingOf(root.id) ?? 0)) }}</template>
            </template>
            <template v-else>未设置</template>
          </span>
        </div>

        <input
          v-model="inputs[root.id]"
          class="m-budget-item__input"
          :class="{ 'm-budget-item__input--set': configured.has(root.id) }"
          type="text"
          inputmode="decimal"
          placeholder="不设"
          :aria-label="`${root.name}的预算`"
          @keydown.enter="($event.target as HTMLInputElement).blur()"
          @blur="save(root.id)"
        />
      </li>
    </ul>

    <p class="m-hint">输入后离开即保存；清空输入框可取消该项。</p>
  </div>
</template>
