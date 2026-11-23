<script setup lang="ts">
/**
 * 移动端统计页：周 / 月 / 季 / 年。
 *
 * 四个粒度不只是换时间范围，**重点图也不同**：
 * - 周：哪天花得最多 → 7 天柱状
 * - 月：钱花在哪   → 分类圆环 + 日折线
 * - 季：三个月对比  → 3 个月柱状
 * - 年：全年走势   → 12 个月折线
 *
 * 共同部分：区间结余 + 收支细字 + 预算明细。
 */
import { computed, onMounted, ref, watch } from 'vue'
import LedgerDonutChart from '@/components/LedgerDonutChart.vue'
import MobileStatsChart from '@/components/mobile/MobileStatsChart.vue'
import { ApiError } from '@/api/client'
import { getBudget, getRangeStats, type Budget, type LedgerRangeStats } from '@/api/ledger'
import { formatYuan } from '@/utils/ledger'
import {
  GRANULARITY_LABEL,
  mergeByMonth,
  mergeByWeek,
  monthDaysInRange,
  rangeOf,
  type StatsGranularity,
} from '@/utils/statsRange'
import { Check, ChevronLeft, ChevronRight } from 'lucide-vue-next'


const granularity = ref<StatsGranularity>('week')
/** 相对当前格子的位移。 */
const offset = ref(0)

const loading = ref(true)
const error = ref('')
const stats = ref<LedgerRangeStats | null>(null)
/** 预算只在「月」粒度有意义。 */
const budget = ref<Budget | null>(null)
/** 周视图跨月时需要两个月的预算。 */
const budgetCache = ref(new Map<string, Budget | null>())

/** 取某个月的预算（带缓存）。 */
function budgetForMonth(month: string): Budget | null {
  return budgetCache.value.get(month) ?? null
}

const range = computed(() => rangeOf(granularity.value, offset.value))

const granularities: StatsGranularity[] = ['week', 'month', 'quarter', 'year']

/** 粒度选择弹层的开关。 */
const pickerOpen = ref(false)

/** 每个粒度看什么，给弹层做副标题。 */
const GRANULARITY_HINT: Record<StatsGranularity, string> = {
  week: '哪天花得最多',
  month: '钱花在哪',
  quarter: '三个月对比',
  year: '全年走势',
}

/** 结余 = 收入 − 支出。 */
const balance = computed(
  () => (stats.value?.total_income_cents ?? 0) - (stats.value?.total_expense_cents ?? 0),
)

/** 圆环优先展示支出分类；只有收入时退回收入分类。 */
const donut = computed(() => {
  const s = stats.value
  if (!s) return { items: [], label: '支出' }
  if (s.expense_by_category.length > 0) return { items: s.expense_by_category, label: '支出' }
  return { items: s.income_by_category, label: '收入' }
})

/** 季 / 年：按天合并成月。 */
const monthly = computed(() => mergeByMonth(stats.value?.buckets ?? []))

/**
 * 图表数据：所有粒度都产出同一结构，由图表组件决定画折线还是柱状。
 *
 * - 周 / 月：每天一个点
 * - 季 / 年：每月一个点
 */
const chartPoints = computed(() => {
  const g = granularity.value
  if (g === 'week') {
    // 周：每天一个点
    return (stats.value?.buckets ?? []).map((d) => ({
      label: String(Number(d.date.slice(8))),
      expense: d.expense_cents,
      income: d.income_cents,
    }))
  }
  if (g === 'month') {
    // 月：按自然周分桶（4~5 个点），比 30 个点更容易看节奏
    return mergeByWeek(stats.value?.buckets ?? []).map((w) => ({
      label: w.label,
      expense: w.expense_cents,
      income: w.income_cents,
    }))
  }
  // 季 / 年：每月一个点
  return monthly.value.map((m) => ({
    label: m.month.replace(' 月', ''),
    expense: m.expense_cents,
    income: m.income_cents,
  }))
})

/**
 * 预算明细（月与周展示）。
 *
 * 月：预算就是设的那个数，已花用后端算好的。
 * 周：预算按月天数折算，已花用本周区间内的支出——
 *     跨月的那一周按各月占的天数加权，避免整周都算进一个月的预算。
 */
const budgetRows = computed(() => {
  const g = granularity.value
  if (g !== 'month' && g !== 'week') return []

  const items = budget.value?.items ?? []
  if (g === 'month') {
    return items
      .map((b) => ({
        ...b,
        percent: b.amount_cents > 0 ? Math.round((b.spent_cents / b.amount_cents) * 100) : 0,
      }))
      .sort((a, b) => b.percent - a.percent)
  }

  // 周：按天数折算预算，并按本周区间重算已花
  const parts = monthDaysInRange(range.value.from, range.value.to)
  const spentByCategory = new Map(
    (stats.value?.expense_by_category ?? []).map((c) => [c.category_id, c.spent_cents]),
  )

  return items
    .map((b) => {
      // 预算按「这一周落在各月的天数 / 该月总天数」分摊后相加
      const weeklyBudget = parts.reduce((sum, part) => {
        const partBudget = budgetForMonth(part.month)?.items.find((i) => i.category_id === b.category_id)
        if (!partBudget) return sum
        const [y, m] = part.month.split('-').map(Number)
        const daysInThatMonth = new Date(y, m, 0).getDate()
        return sum + Math.round((partBudget.amount_cents * part.days) / daysInThatMonth)
      }, 0)

      const spent = spentByCategory.get(b.category_id) ?? 0
      return {
        category_id: b.category_id,
        category_name: b.category_name,
        amount_cents: weeklyBudget,
        spent_cents: spent,
        remaining_cents: weeklyBudget - spent,
        percent: weeklyBudget > 0 ? Math.round((spent / weeklyBudget) * 100) : 0,
      }
    })
    .filter((b) => b.amount_cents > 0)
    .sort((a, b) => b.percent - a.percent)
})

const overBudgets = computed(() => budgetRows.value.filter((b) => b.remaining_cents < 0))

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const r = range.value
    const statsPromise = getRangeStats(r.from, r.to)

    // 月与周都需要预算；季度与年不涉及（预算是按月设的）
    const needBudget = granularity.value === 'month' || granularity.value === 'week'
    const months = needBudget
      ? [...new Set(monthDaysInRange(r.from, r.to).map((p) => p.month))]
      : []

    const [s, ...budgets] = await Promise.all([
      statsPromise,
      ...months.map((m) => getBudget(m).catch(() => null)),
    ])
    stats.value = s

    const cache = new Map<string, Budget | null>()
    months.forEach((m, i) => cache.set(m, budgets[i] ?? null))
    budgetCache.value = cache
    // 主预算取区间起点所在月（月视图即该月；周视图用于兜底）
    budget.value = months.length > 0 ? (cache.get(months[0]) ?? null) : null
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '统计加载失败'
  } finally {
    loading.value = false
  }
}

/** 切粒度：回到当前格并关掉弹层。 */
async function pickGranularity(g: StatsGranularity): Promise<void> {
  pickerOpen.value = false
  if (granularity.value === g) return
  granularity.value = g
  offset.value = 0
  await load()
}

async function step(delta: number): Promise<void> {
  if (delta > 0 && range.value.isCurrent) return
  offset.value += delta
  await load()
}

// 粒度变化时重新加载（setGranularity 已处理，这里兜底 watch）
watch(granularity, () => void load())

onMounted(load)
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="统计" />

    <!--
      顶部导航合并成一行：‹  [粒度 · 区间]  ›

      粒度和时间原本是两行独立控件，风格不统一、要扫两次才知道在看什么。
      合并后中间这块既是「当前视图」，也是切换粒度的入口。
    -->
    <div class="m-nav">
      <button class="m-nav__arrow" type="button" aria-label="上一段" @click="step(-1)">
        <ChevronLeft aria-hidden="true" />
      </button>

      <button
        class="m-nav__center"
        type="button"
        :aria-label="`当前粒度 ${GRANULARITY_LABEL[granularity]}，点击切换`"
        @click="pickerOpen = true"
      >
        <span class="m-nav__badge">{{ GRANULARITY_LABEL[granularity] }}</span>
        <span class="m-nav__label">{{ range.label }}</span>
      </button>

      <!-- 占位保持中心对称：到头时不显示箭头，但宽度不能变 -->
      <button
        class="m-nav__arrow"
        type="button"
        aria-label="下一段"
        :class="{ 'm-nav__arrow--hidden': range.isCurrent }"
        :disabled="range.isCurrent"
        @click="step(1)"
      >
        <ChevronRight aria-hidden="true" />
      </button>
    </div>

    <!--
      粒度选择：点中间标签弹出。

      Teleport 到 body：.m-main 有 overflow-y: auto，会创建新的层叠上下文，
      弹层的 z-index 只在 .m-main 内部比较，压不住 fixed 的底部菜单栏。
    -->
    <DialogRoot :open="pickerOpen" @update:open="(value: boolean) => !value && (pickerOpen = false)">
      <DialogPortal>
        <DialogOverlay class="m-picker-backdrop" />
        <DialogContent class="m-granularity-sheet">
          <div class="m-picker__grab"></div>
          <div class="m-picker__head">
            <span></span>
            <DialogTitle class="m-picker__title">统计粒度</DialogTitle>
            <DialogDescription class="sr-only">按周、月、季、年查看收支</DialogDescription>
            <button type="button" class="m-picker__action" @click="pickerOpen = false">取消</button>
          </div>
          <div class="m-granularity-list">
            <button
              v-for="g in granularities"
              :key="g"
              type="button"
              class="m-granularity-item"
              :class="{ 'm-granularity-item--active': granularity === g }"
              @click="pickGranularity(g)"
            >
              <span class="m-granularity-item__name">{{ GRANULARITY_LABEL[g] }}</span>
              <span class="m-granularity-item__hint">{{ GRANULARITY_HINT[g] }}</span>
              <Check v-if="granularity === g" aria-hidden="true" />
            </button>
          </div>
        </div>
      </DialogContent>
    </DialogPortal>
    </DialogRoot>

    <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

    <div v-if="loading" class="m-skeleton">
      <div class="skeleton skeleton--title" style="width: 46%"></div>
      <div class="skeleton skeleton--title" style="width: 68%"></div>
    </div>

    <template v-else>
      <!-- 结余：大字悬浮，不做卡片 -->
      <section class="m-card m-hero" aria-label="区间结余">
        <span class="m-hero__label">结余</span>
        <span class="m-hero__value" :class="{ 'm-hero__value--negative': balance < 0 }">
          {{ balance < 0 ? '−' : '' }}{{ formatYuan(Math.abs(balance)) }}
        </span>
        <p class="m-hero__meta">
          支出 <strong>{{ formatYuan(stats?.total_expense_cents ?? 0) }}</strong>
          <span class="m-hero__dot">·</span>
          收入 <strong class="m-hero__meta-income">{{ formatYuan(stats?.total_income_cents ?? 0) }}</strong>
          <span class="m-hero__dot">·</span>
          {{ stats?.total_count ?? 0 }} 笔
        </p>
      </section>

      <p v-if="overBudgets.length > 0" class="m-notice m-notice--warn">
        {{ overBudgets.map((b) => b.category_name).join('、') }} 超出预算
      </p>

      <!--
        图表随粒度切换：
        - 周 / 月：折线（看每日波动）
        - 季 / 年：柱状（看月度对比）
        两种形态都同时画支出与收入，方便看「这个月进的多还是出的多」。
      -->
      <section v-if="granularity === 'week'" class="m-card m-stat-block" aria-label="本周每日收支">
        <h2 class="m-stat-block__title">每天收支</h2>
        <p v-if="chartPoints.length === 0" class="m-hint">这一周还没有记录。</p>
        <MobileStatsChart v-else :points="chartPoints" variant="line" />
      </section>

      <section v-if="granularity === 'month'" class="m-card m-stat-block" aria-label="本月每日收支">
        <h2 class="m-stat-block__title">每天收支</h2>
        <p v-if="chartPoints.length === 0" class="m-hint">这个月还没有记录。</p>
        <MobileStatsChart v-else :points="chartPoints" variant="line" />
      </section>

      <section v-if="granularity === 'quarter'" class="m-card m-stat-block" aria-label="季度内各月收支">
        <h2 class="m-stat-block__title">三个月收支</h2>
        <MobileStatsChart :points="chartPoints" variant="bar" />
      </section>

      <section v-if="granularity === 'year'" class="m-card m-stat-block" aria-label="全年各月收支">
        <h2 class="m-stat-block__title">全年收支</h2>
        <MobileStatsChart :points="chartPoints" variant="bar" />
      </section>

      <!-- 月的分类占比放在走势下面：先看节奏，再看结构 -->
      <section v-if="granularity === 'month' && donut.items.length > 0" class="m-card m-stat-block" aria-label="分类占比">
        <h2 class="m-stat-block__title">钱花在哪</h2>
        <LedgerDonutChart :items="donut.items" :label="donut.label" />
      </section>

      <!-- 分类占比：月以外的粒度也看看结构 -->
      <section v-if="granularity !== 'month' && donut.items.length > 0" class="m-card m-stat-block" aria-label="分类占比">
        <h2 class="m-stat-block__title">钱花在哪</h2>
        <LedgerDonutChart :items="donut.items" :label="donut.label" />
      </section>

      <!-- 预算明细：只有月粒度 -->
      <section v-if="budgetRows.length > 0" class="m-card m-stat-block" aria-label="预算明细">
        <h2 class="m-stat-block__title">
          预算明细
          <span v-if="granularity === 'week'" class="m-stat-block__note">按月折算</span>
        </h2>
        <ul class="m-cat-rows">
          <li v-for="row in budgetRows" :key="row.category_id" class="m-cat-row">
            <div class="m-cat-row__top">
              <span class="m-cat-row__name">{{ row.category_name }}</span>
              <span class="m-cat-row__amount">{{ formatYuan(row.spent_cents) }}</span>
              <span class="m-cat-row__pct" :class="{ 'is-over': row.remaining_cents < 0 }">{{ row.percent }}%</span>
            </div>
            <div class="m-cat-row__bar">
              <div
                class="m-cat-row__fill"
                :class="{ 'm-cat-row__fill--over': row.remaining_cents < 0 }"
                :style="{ width: Math.min(100, row.percent) + '%' }"
              ></div>
            </div>
            <p class="m-cat-row__budget" :class="{ 'is-over': row.remaining_cents < 0 }">
              预算 {{ formatYuan(row.amount_cents) }} ·
              <template v-if="row.remaining_cents >= 0">还剩 {{ formatYuan(row.remaining_cents) }}</template>
              <template v-else>超出 {{ formatYuan(-row.remaining_cents) }}</template>
            </p>
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>
