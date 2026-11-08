<script setup lang="ts">
/**
 * 写作热力图（docs/v5/frontend/frontend.md 3.3）。
 *
 * 近半年的每日编辑数，按周分列、按星期分行，配色从浅到深五档。
 * 数据来自后端，已经补零到完整日期序列，这里只做排版。
 */
import { computed } from 'vue'
import type { HeatmapCell } from '@/api/stats'

const props = defineProps<{
  cells: HeatmapCell[]
}>()

/** 每档的编辑次数上限，与 CSS 的 .heatmap-cell--n 对应。 */
function level(count: number): 0 | 1 | 2 | 3 | 4 {
  if (count <= 0) return 0
  if (count === 1) return 1
  if (count === 2) return 2
  if (count <= 4) return 3
  return 4
}

interface Column {
  /** 该列的月份标签，只有每列第一天且月份变化时才有值。 */
  monthLabel: string
  cells: Array<HeatmapCell & { level: 0 | 1 | 2 | 3 | 4; weekday: number }>
}

/**
 * 按周分列。
 *
 * 后端给的是连续的日期序列；这里按「周一为一周第一天」切列，
 * 首列前面补空格子，让星期对齐。
 */
const columns = computed<Column[]>(() => {
  const out: Column[] = []
  let lastMonth = ''

  for (const cell of props.cells) {
    const date = new Date(`${cell.date}T00:00:00`)
    // getDay(): 0 = 周日，转成「周一 = 0」
    const weekday = (date.getDay() + 6) % 7
    const month = `${date.getMonth() + 1}月`

    if (out.length === 0 || weekday === 0) {
      const monthLabel = month !== lastMonth ? month : ''
      if (monthLabel) lastMonth = month
      out.push({ monthLabel, cells: [] })
    }

    out[out.length - 1].cells.push({ ...cell, level: level(cell.count), weekday })
  }
  return out
})

/** 图例用的五档。 */
const legendLevels = [0, 1, 2, 3, 4] as const
</script>

<template>
  <div class="heatmap">
    <div class="heatmap__inner">
      <div class="heatmap__months">
        <span v-for="(col, i) in columns" :key="i" class="heatmap__month">
          {{ col.monthLabel }}
        </span>
      </div>

      <div class="heatmap__grid">
        <div v-for="(col, i) in columns" :key="i" class="heatmap__col">
          <span
            v-for="pad in (col.cells[0]?.weekday ?? 0)"
            :key="`pad-${pad}`"
            class="heatmap__pad"
          ></span>
          <span
            v-for="cell in col.cells"
            :key="cell.date"
            class="heatmap__cell"
            :class="`heatmap__cell--${cell.level}`"
            :title="`${cell.date} · ${cell.count > 0 ? `编辑 ${cell.count} 篇` : '没有编辑'}`"
          ></span>
        </div>
      </div>
    </div>

    <div class="heatmap__legend">
      <span>少</span>
      <span v-for="l in legendLevels" :key="l" class="heatmap__cell" :class="`heatmap__cell--${l}`"></span>
      <span>多</span>
    </div>
  </div>
</template>
