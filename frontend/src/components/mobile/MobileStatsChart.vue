<script setup lang="ts">
/**
 * 统计页的收支图表：折线或柱状，始终同时画支出与收入两条。
 *
 * 为什么自己写而不是复用 PC 的 LedgerTrendChart：
 * 那个组件按「最近 N 天」画固定高度，移动端要的是「周 / 月用折线、季 / 年用柱状」
 * 两种形态，且横轴标签密度随点数变化，共用会越改越乱。
 *
 * 两条线用同一套色：支出用强调色（红系）、收入用绿色，
 * 与页面里其他地方 `--accent` / `--success` 的含义一致。
 */
import { computed } from 'vue'

export interface ChartPoint {
  /** 横轴标签，如「16」「11 月」。 */
  label: string
  expense: number
  income: number
}

const props = withDefaults(
  defineProps<{
    points: ChartPoint[]
    /** line 折线 / bar 柱状。 */
    variant?: 'line' | 'bar'
  }>(),
  { variant: 'line' },
)

const WIDTH = 320
const HEIGHT = 132
const PAD_TOP = 8
const PAD_BOTTOM = 20
const PAD_X = 4

/** 可绘制区域高度。 */
const plotHeight = HEIGHT - PAD_TOP - PAD_BOTTOM

/** 纵轴最大值：两条线共用，保证可比。 */
const maxValue = computed(() =>
  Math.max(1, ...props.points.flatMap((p) => [p.expense, p.income])),
)

/** 点的横坐标：均匀分布，首尾贴边。 */
function xAt(index: number): number {
  const n = props.points.length
  if (n <= 1) return WIDTH / 2
  const usable = WIDTH - PAD_X * 2
  return PAD_X + (usable * index) / (n - 1)
}

/** 纵坐标：0 在底部。 */
function yAt(value: number): number {
  return PAD_TOP + plotHeight - (value / maxValue.value) * plotHeight
}

/** 折线的 path。 */
function linePath(key: 'expense' | 'income'): string {
  return props.points
    .map((p, i) => `${i === 0 ? 'M' : 'L'}${xAt(i).toFixed(1)},${yAt(p[key]).toFixed(1)}`)
    .join(' ')
}

/** 折线下方填充区的 path。 */
function areaPath(key: 'expense' | 'income'): string {
  if (props.points.length === 0) return ''
  const base = PAD_TOP + plotHeight
  return `${linePath(key)} L${xAt(props.points.length - 1).toFixed(1)},${base} L${xAt(0).toFixed(1)},${base} Z`
}

/** 柱状：每根柱的宽度与位置。 */
const barLayout = computed(() => {
  const n = props.points.length
  if (n === 0) return { width: 0, group: 0 }
  const usable = WIDTH - PAD_X * 2
  const group = usable / n
  // 每根柱占组宽的 34%，两根之间留缝
  return { width: Math.max(1, group * 0.34), group }
})

function barX(index: number, which: 'expense' | 'income'): number {
  const { width, group } = barLayout.value
  const left = PAD_X + group * index + group / 2
  return which === 'expense' ? left - width - 0.5 : left + 0.5
}

function barY(value: number): number {
  return yAt(value)
}

function barHeight(value: number): number {
  return Math.max(0, PAD_TOP + plotHeight - yAt(value))
}

/**
 * 横轴标签密度：点多时抽样显示，避免叠在一起。
 * 规则是「最多 6 个标签」。
 */
const labelIndexes = computed(() => {
  const n = props.points.length
  if (n <= 6) return props.points.map((_, i) => i)
  const step = Math.ceil(n / 6)
  const out: number[] = []
  for (let i = 0; i < n; i += step) out.push(i)
  // 保证最后一项也有标签
  if (out[out.length - 1] !== n - 1) out.push(n - 1)
  return out
})

/** 图例文案。 */
const hasIncome = computed(() => props.points.some((p) => p.income > 0))
</script>

<template>
  <div class="m-chart">
    <div class="m-chart__legend">
      <span class="m-chart__legend-item">
        <i class="m-chart__dot m-chart__dot--expense"></i>支出
      </span>
      <span v-if="hasIncome" class="m-chart__legend-item">
        <i class="m-chart__dot m-chart__dot--income"></i>收入
      </span>
    </div>

    <svg
      class="m-chart__svg"
      :viewBox="`0 0 ${WIDTH} ${HEIGHT}`"
      preserveAspectRatio="none"
      role="img"
      :aria-label="variant === 'line' ? '收支折线图' : '收支柱状图'"
    >
      <!-- 基线：让空数据时也有参照 -->
      <line
        :x1="PAD_X"
        :x2="WIDTH - PAD_X"
        :y1="PAD_TOP + plotHeight"
        :y2="PAD_TOP + plotHeight"
        class="m-chart__baseline"
      />

      <!-- 折线 -->
      <template v-if="variant === 'line'">
        <path
          v-if="hasIncome"
          :d="areaPath('income')"
          class="m-chart__area m-chart__area--income"
        />
        <path :d="areaPath('expense')" class="m-chart__area m-chart__area--expense" />
        <path
          v-if="hasIncome"
          :d="linePath('income')"
          class="m-chart__line m-chart__line--income"
        />
        <path :d="linePath('expense')" class="m-chart__line m-chart__line--expense" />
      </template>

      <!-- 柱状 -->
      <template v-else>
        <g v-for="(p, i) in points" :key="i">
          <rect
            :x="barX(i, 'expense')"
            :y="barY(p.expense)"
            :width="barLayout.width"
            :height="barHeight(p.expense)"
            rx="1.5"
            class="m-chart__bar m-chart__bar--expense"
          />
          <rect
            v-if="p.income > 0"
            :x="barX(i, 'income')"
            :y="barY(p.income)"
            :width="barLayout.width"
            :height="barHeight(p.income)"
            rx="1.5"
            class="m-chart__bar m-chart__bar--income"
          />
        </g>
      </template>
    </svg>

    <!-- 横轴标签用 HTML 渲染：SVG 文字在移动端不好控制字号与省略 -->
    <div class="m-chart__labels">
      <span
        v-for="i in labelIndexes"
        :key="i"
        class="m-chart__label"
        :style="{ left: `${(xAt(i) / WIDTH) * 100}%` }"
      >
        {{ points[i]?.label }}
      </span>
    </div>
  </div>
</template>
