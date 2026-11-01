<script setup lang="ts">
/**
 * 仪表盘（docs/v5/frontend/frontend.md 第三节）。
 *
 * 只读：统计卡片 + 写作热力图 + 最近编辑。
 * 数据一次从 GET /api/stats 取回，前端不再拉全量笔记。
 */
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import HeatmapChart from '@/components/HeatmapChart.vue'
import { getStats, type StatsSnapshot } from '@/api/stats'
import { formatRelative } from '@/utils/format'

const data = ref<StatsSnapshot | null>(null)
const loading = ref(true)
const error = ref('')

/** 四张统计卡片。 */
const cards = computed(() => {
  const t = data.value?.totals
  const w = data.value?.week
  return [
    { label: '笔记', value: formatCount(t?.notes ?? 0) },
    { label: '字', value: formatWords(t?.words ?? 0) },
    { label: '公开', value: formatCount(t?.public_notes ?? 0) },
    { label: '本周新建', value: formatCount(w?.created ?? 0) },
  ]
})

/** 千分位。 */
function formatCount(n: number): string {
  return n.toLocaleString('zh-CN')
}

/** 大字缩写：超过 1 万显示为「4.2 万」。 */
function formatWords(n: number): string {
  if (n < 10000) return formatCount(n)
  const wan = n / 10000
  return `${wan.toFixed(wan >= 100 ? 0 : 1)} 万`
}

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    data.value = await getStats()
  } catch {
    error.value = '统计数据加载失败'
  } finally {
    loading.value = false
  }
}

onMounted(() => void load())
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">仪表盘</h1>
      <p class="detail-sub">写作概况与最近动态。</p>
    </header>

    <p v-if="error" class="notice notice--error">
      {{ error }}
      <span class="notice__actions">
        <button class="btn btn--sm" type="button" @click="load">重试</button>
      </span>
    </p>

    <div class="stat-grid">
      <div v-for="card in cards" :key="card.label" class="stat-card">
        <span v-if="loading" class="skeleton skeleton--title" style="width: 60%; margin: 0 auto"></span>
        <span v-else class="stat-card__value">{{ card.value }}</span>
        <span class="stat-card__label">{{ card.label }}</span>
      </div>
    </div>

    <div class="home-columns">
      <section class="home-panel">
        <h2 class="home-panel__title">写作热力图</h2>
        <p class="field__hint" style="margin-bottom: 10px">近三个月每天编辑过的笔记数。</p>
        <HeatmapChart v-if="data" :cells="data.heatmap" />
        <div v-else class="skeleton skeleton--line" style="width: 100%; height: 80px"></div>
      </section>

      <section class="home-panel">
        <h2 class="home-panel__title">最近编辑</h2>
        <p v-if="loading" class="field__hint">加载中…</p>
        <p v-else-if="!data || data.recent.length === 0" class="field__hint">还没有笔记。</p>
        <ul v-else class="recent-list">
          <li v-for="note in data.recent" :key="note.id">
            <RouterLink :to="{ name: 'note-detail', params: { id: note.id } }" class="recent-row">
              <span class="recent-row__title">{{ note.title }}</span>
              <span class="recent-row__meta">{{ formatRelative(note.updated_at) }}</span>
            </RouterLink>
          </li>
        </ul>
      </section>
    </div>
  </div>
</template>
