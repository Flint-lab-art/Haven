<script setup lang="ts">
/**
 * 分类占比：环形图 + 关键指标卡片 + 分类图例。
 *
 * 为什么不是单纯的环形图：分类一多（通常是 8~10 个），
 * 环上图例只能给出百分比，看不出「最大的是谁、平均每笔多少」这类信息，
 * 大片留白也让版面显得空。指标卡把这些数字补上，图例只保留占比。
 */
import { computed } from 'vue'
import type { LedgerCategoryRank } from '@/api/ledger'
import { categoryColor, categoryTone, formatYuan } from '@/utils/ledger'

const props = defineProps<{
  /** 当前方向下的分类排行（已按金额倒序）。 */
  items: LedgerCategoryRank[]
  /** 「支出」或「收入」。 */
  label: string
}>()

const total = computed(() => props.items.reduce((sum, item) => sum + item.amount_cents, 0))
const count = computed(() => props.items.reduce((sum, item) => sum + item.count, 0))

/** 每个分类的占比（0~1）。 */
const shares = computed(() =>
  props.items.map((item) => ({
    ...item,
    share: total.value > 0 ? item.amount_cents / total.value : 0,
    color: categoryColor(item.category),
  })),
)

const top = computed(() => shares.value[0] ?? null)
/** 平均每笔金额。 */
const average = computed(() => (count.value > 0 ? Math.round(total.value / count.value) : 0))

/* ── 环形图几何 ─────────────────────────────── */
const SIZE = 132
const CENTER = SIZE / 2
const RADIUS = 50
const STROKE = 14
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

const segments = computed(() => {
  if (total.value <= 0) return []
  const gap = shares.value.length > 1 ? 2 : 0
  let consumed = 0
  return shares.value.map((item) => {
    const rawLength = item.share * CIRCUMFERENCE
    const dash = Math.max(rawLength - gap, 0.5)
    const segment = { ...item, dash, rest: CIRCUMFERENCE - dash, offset: -consumed }
    consumed += rawLength
    return segment
  })
})
</script>

<template>
  <div class="ledger-share">
    <!-- ③ 环形图 + 关键指标卡片 -->
    <div class="ledger-share--cards">
      <div class="ledger-share__cards">
        <div class="ledger-share__stat">
          <span class="ledger-share__stat-label">最大一类</span>
          <span class="ledger-share__stat-value">
            {{ top ? top.category : '—' }}
          </span>
          <span class="ledger-share__stat-sub">{{ top ? formatYuan(top.amount_cents) : '' }}</span>
        </div>
        <div class="ledger-share__stat">
          <span class="ledger-share__stat-label">笔数</span>
          <span class="ledger-share__stat-value">{{ count }}</span>
          <span class="ledger-share__stat-sub">笔</span>
        </div>
        <div class="ledger-share__stat">
          <span class="ledger-share__stat-label">平均每笔</span>
          <span class="ledger-share__stat-value">{{ formatYuan(average) }}</span>
          <span class="ledger-share__stat-sub"></span>
        </div>
      </div>

      <div class="ledger-share__cards-main">
        <svg class="ledger-share__donut" :viewBox="`0 0 ${SIZE} ${SIZE}`" role="img" :aria-label="`${label}分类占比`">
          <circle :cx="CENTER" :cy="CENTER" :r="RADIUS" fill="none" class="ledger-donut__track" :stroke-width="STROKE" />
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
              <title>{{ segment.category }} {{ formatYuan(segment.amount_cents) }}</title>
            </circle>
          </g>
          <text :x="CENTER" :y="CENTER - 2" class="ledger-donut__total" text-anchor="middle">
            {{ formatYuan(total) }}
          </text>
          <text :x="CENTER" :y="CENTER + 15" class="ledger-donut__label" text-anchor="middle">{{ label }}</text>
        </svg>

        <ul class="ledger-share__list ledger-share__list--compact">
          <li v-for="item in shares" :key="item.category" class="ledger-share__legend-row">
            <i class="ledger-dot" :class="`ledger-dot--${categoryTone(item.category)}`" aria-hidden="true"></i>
            <span class="ledger-share__name">{{ item.category }}</span>
            <span class="ledger-share__pct">{{ Math.round(item.share * 100) }}%</span>
          </li>
        </ul>
      </div>
    </div>

    <p v-if="!shares.length" class="ledger-muted">这个月还没有{{ label }}记录。</p>
  </div>
</template>
