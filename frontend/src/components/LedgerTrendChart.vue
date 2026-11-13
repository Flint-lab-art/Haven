<script setup lang="ts">
/**
 * 记账走势图：支出 / 收入的每日折线 + 面积。
 *
 * 不引入图表库，直接用 SVG 画：整站只需要折线、圆环两种图，
 * 手写可以完全复用现有色阶与字体，构建体积也几乎不变。
 * 数据由后端按天补零，这里只负责几何与悬停提示。
 */
import { computed, ref, useId } from 'vue'
import type { LedgerDailyPoint } from '@/api/ledger'
import { formatYuan } from '@/utils/ledger'

const props = withDefaults(
  defineProps<{
    points: LedgerDailyPoint[]
    /** 仪表盘用紧凑高度。 */
    compact?: boolean
  }>(),
  { compact: false },
)

const W = 640
const height = computed(() => (props.compact ? 136 : 196))
const PAD = { top: 16, right: 14, bottom: 26, left: 44 }

const gradientId = `ledger-trend-${useId()}`

const plotWidth = computed(() => W - PAD.left - PAD.right)
const plotHeight = computed(() => height.value - PAD.top - PAD.bottom)

/** 把最大值抬到 1 / 2 / 5 × 10^n，让网格线落在整档上。 */
function niceCeil(value: number): number {
  if (value <= 0) return 1000
  const exponent = 10 ** Math.floor(Math.log10(value))
  const normalized = value / exponent
  const step = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10
  return step * exponent
}

const yMax = computed(() =>
  niceCeil(
    Math.max(
      1,
      ...props.points.map((point) => Math.max(point.expense_cents, point.income_cents)),
    ),
  ),
)

/** 0 / 1/3 / 2/3 / 1 四条横向网格线。 */
const gridValues = computed(() => [0, 1 / 3, 2 / 3, 1].map((ratio) => ratio * yMax.value))

const xAt = (index: number): number => {
  if (props.points.length <= 1) return PAD.left + plotWidth.value / 2
  return PAD.left + (index / (props.points.length - 1)) * plotWidth.value
}

const yAt = (cents: number): number =>
  PAD.top + plotHeight.value - (cents / yMax.value) * plotHeight.value

/**
 * 平滑折线：每两个点之间用一条三次贝塞尔，
 * 控制点取两点横坐标的中点，避免曲线在一天内来回摆。
 */
function smoothPath(values: number[]): string {
  if (values.length === 0) return ''
  const start = `M ${xAt(0)} ${yAt(values[0])}`
  let d = start
  for (let i = 1; i < values.length; i++) {
    const midX = (xAt(i - 1) + xAt(i)) / 2
    d += ` C ${midX} ${yAt(values[i - 1])}, ${midX} ${yAt(values[i])}, ${xAt(i)} ${yAt(values[i])}`
  }
  return d
}

const expensePath = computed(() => smoothPath(props.points.map((point) => point.expense_cents)))
const incomePath = computed(() => smoothPath(props.points.map((point) => point.income_cents)))

const expenseArea = computed(() => {
  if (!expensePath.value) return ''
  const baseline = yAt(0)
  return `${expensePath.value} L ${xAt(props.points.length - 1)} ${baseline} L ${xAt(0)} ${baseline} Z`
})

const showDots = computed(() => props.points.length <= 16)

/** 横轴只标几档，避免 31 天挤成一团。 */
const xTicks = computed(() => {
  const total = props.points.length
  if (total === 0) return []
  const step = Math.max(1, Math.ceil(total / 6))
  const indexes = new Set<number>()
  for (let i = 0; i < total; i += step) indexes.add(i)
  indexes.add(total - 1)
  return [...indexes].sort((a, b) => a - b).map((index) => ({
    index,
    x: xAt(index),
    label: props.points[index].date.slice(5),
  }))
})

function axisLabel(cents: number): string {
  const yuan = cents / 100
  if (yuan <= 0) return '0'
  if (yuan >= 10000) {
    const wan = yuan / 10000
    return `${wan >= 10 ? Math.round(wan) : wan.toFixed(1).replace(/\.0$/, '')}万`
  }
  if (yuan >= 1000) {
    const k = yuan / 1000
    return `${k >= 10 ? Math.round(k) : k.toFixed(1).replace(/\.0$/, '')}k`
  }
  return String(Math.round(yuan))
}

// ---- 悬停 ----

const hovered = ref<number | null>(null)
const hoveredPoint = computed(() =>
  hovered.value === null ? null : (props.points[hovered.value] ?? null),
)
const hoveredX = computed(() =>
  hovered.value === null ? 0 : xAt(hovered.value),
)
const tooltipX = computed(() => Math.min(Math.max(hoveredX.value - 62, 4), W - 128))

function onPointerMove(event: PointerEvent): void {
  if (props.points.length === 0) return
  const rect = (event.currentTarget as SVGSVGElement).getBoundingClientRect()
  if (rect.width === 0) return
  const x = ((event.clientX - rect.left) / rect.width) * W
  const ratio = (x - PAD.left) / plotWidth.value
  const index = Math.round(ratio * (props.points.length - 1))
  hovered.value = Math.min(Math.max(index, 0), props.points.length - 1)
}

function clearHover(): void {
  hovered.value = null
}
</script>

<template>
  <figure class="ledger-chart">
    <div class="ledger-chart__legend">
      <span class="ledger-chart__legend-item">
        <i class="ledger-chart__swatch ledger-chart__swatch--expense" aria-hidden="true"></i>支出
      </span>
      <span class="ledger-chart__legend-item">
        <i class="ledger-chart__swatch ledger-chart__swatch--income" aria-hidden="true"></i>收入
      </span>
    </div>

    <svg
      class="ledger-chart__svg"
      :viewBox="`0 0 ${W} ${height}`"
      role="img"
      aria-label="每日收支走势图"
      @pointermove="onPointerMove"
      @pointerleave="clearHover"
    >
      <defs>
        <linearGradient :id="gradientId" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="var(--accent)" stop-opacity="0.22" />
          <stop offset="100%" stop-color="var(--accent)" stop-opacity="0" />
        </linearGradient>
      </defs>

      <!-- 网格与纵轴刻度 -->
      <g>
        <line
          v-for="value in gridValues"
          :key="`grid-${value}`"
          :x1="PAD.left"
          :x2="W - PAD.right"
          :y1="yAt(value)"
          :y2="yAt(value)"
          class="ledger-chart__grid"
        />
        <text
          v-for="value in gridValues"
          :key="`tick-${value}`"
          :x="PAD.left - 8"
          :y="yAt(value) + 3.5"
          class="ledger-chart__axis"
          text-anchor="end"
        >
          {{ axisLabel(value) }}
        </text>
      </g>

      <!-- 面积与折线 -->
      <path v-if="expenseArea" :d="expenseArea" :fill="`url(#${gradientId})`" />
      <path
        v-if="expensePath"
        :d="expensePath"
        class="ledger-chart__line ledger-chart__line--expense"
      />
      <path
        v-if="incomePath"
        :d="incomePath"
        class="ledger-chart__line ledger-chart__line--income"
      />

      <g v-if="showDots">
        <circle
          v-for="(point, index) in points"
          :key="`dot-${point.date}`"
          :cx="xAt(index)"
          :cy="yAt(point.expense_cents)"
          r="2.4"
          class="ledger-chart__dot ledger-chart__dot--expense"
        >
          <title>{{ point.date }} 支出 {{ formatYuan(point.expense_cents) }}</title>
        </circle>
      </g>

      <!-- 横轴日期 -->
      <text
        v-for="tick in xTicks"
        :key="`x-${tick.index}`"
        :x="tick.x"
        :y="height - 8"
        class="ledger-chart__axis"
        text-anchor="middle"
      >
        {{ tick.label }}
      </text>

      <!-- 悬停：竖线 + 数据点 + 提示框 -->
      <g v-if="hoveredPoint">
        <line
          :x1="hoveredX"
          :x2="hoveredX"
          :y1="PAD.top"
          :y2="height - PAD.bottom"
          class="ledger-chart__guide"
        />
        <circle
          :cx="hoveredX"
          :cy="yAt(hoveredPoint.expense_cents)"
          r="4"
          class="ledger-chart__dot ledger-chart__dot--expense"
        />
        <circle
          :cx="hoveredX"
          :cy="yAt(hoveredPoint.income_cents)"
          r="4"
          class="ledger-chart__dot ledger-chart__dot--income"
        />
        <g :transform="`translate(${tooltipX} 4)`">
          <rect width="124" height="54" rx="8" class="ledger-chart__tip" />
          <text x="10" y="17" class="ledger-chart__tip-date">{{ hoveredPoint.date }}</text>
          <text x="10" y="34" class="ledger-chart__tip-value">
            支出 {{ formatYuan(hoveredPoint.expense_cents) }}
          </text>
          <text x="10" y="48" class="ledger-chart__tip-value">
            收入 {{ formatYuan(hoveredPoint.income_cents) }}
          </text>
        </g>
      </g>
    </svg>
  </figure>
</template>
