<script setup lang="ts">
/**
 * 记账分类占比：圆环图 + 图例。
 *
 * 与 LedgerTrendChart 一样用纯 SVG，颜色取自 `categoryColor()`，
 * 和列表里的小圆点共用同一套色阶。
 */
import { computed } from 'vue'
import type { LedgerCategoryRank } from '@/api/ledger'
import { categoryColor, categoryTone, formatYuan } from '@/utils/ledger'

const props = defineProps<{
  items: LedgerCategoryRank[]
  /** 圆环中心的说明，例如「支出」。 */
  label: string
}>()

const SIZE = 132
const CENTER = SIZE / 2
const RADIUS = 50
const STROKE = 14
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

const total = computed(() =>
  props.items.reduce((sum, item) => sum + item.amount_cents, 0),
)

interface Segment extends LedgerCategoryRank {
  color: string
  dash: number
  rest: number
  offset: number
  percent: number
}

/** 相邻扇区之间留 2px 空隙；只剩一个分类时不留。 */
const segments = computed<Segment[]>(() => {
  if (total.value <= 0) return []
  const gap = props.items.length > 1 ? 2 : 0
  let consumed = 0
  return props.items.map((item) => {
    const fraction = item.amount_cents / total.value
    const rawLength = fraction * CIRCUMFERENCE
    const dash = Math.max(rawLength - gap, 0.5)
    const segment: Segment = {
      ...item,
      color: categoryColor(item.category),
      dash,
      rest: CIRCUMFERENCE - dash,
      offset: -consumed,
      percent: Math.round(fraction * 100),
    }
    consumed += rawLength
    return segment
  })
})
</script>

<template>
  <div class="ledger-donut">
    <svg
      class="ledger-donut__svg"
      :viewBox="`0 0 ${SIZE} ${SIZE}`"
      role="img"
      :aria-label="`${label}分类占比`"
    >
      <circle
        :cx="CENTER"
        :cy="CENTER"
        :r="RADIUS"
        fill="none"
        class="ledger-donut__track"
        :stroke-width="STROKE"
      />
      <g :transform="`rotate(-90 ${CENTER} ${CENTER})`">
        <circle
          v-for="segment in segments"
          :key="segment.category"
          :cx="CENTER"
          :cy="CENTER"
          :r="RADIUS"
          fill="none"
          :stroke="segment.color"
          :stroke-width="STROKE"
          :stroke-dasharray="`${segment.dash} ${segment.rest}`"
          :stroke-dashoffset="segment.offset"
        >
          <title>{{ segment.category }} {{ formatYuan(segment.amount_cents) }}（{{ segment.percent }}%）</title>
        </circle>
      </g>
      <text
        :x="CENTER"
        :y="CENTER - 2"
        class="ledger-donut__total"
        text-anchor="middle"
      >
        {{ formatYuan(total) }}
      </text>
      <text
        :x="CENTER"
        :y="CENTER + 15"
        class="ledger-donut__label"
        text-anchor="middle"
      >
        {{ label }}
      </text>
    </svg>

    <ul v-if="segments.length" class="ledger-donut__legend">
      <li v-for="segment in segments" :key="segment.category" class="ledger-donut__row">
        <i
          class="ledger-dot"
          :class="`ledger-dot--${categoryTone(segment.category)}`"
          aria-hidden="true"
        ></i>
        <span class="ledger-donut__name">{{ segment.category }}</span>
        <span class="ledger-donut__percent">{{ segment.percent }}%</span>
        <span class="ledger-donut__amount">{{ formatYuan(segment.amount_cents) }}</span>
      </li>
    </ul>
    <p v-else class="ledger-muted ledger-donut__empty">暂无数据</p>
  </div>
</template>
