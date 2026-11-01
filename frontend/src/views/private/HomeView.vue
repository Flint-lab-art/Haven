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
import { listTags, type Tag } from '@/api/tags'
import { formatRelative } from '@/utils/format'

const data = ref<StatsSnapshot | null>(null)
/** 常用标签：按引用数倒序取前若干个。 */
const tags = ref<Tag[]>([])
const loading = ref(true)
const error = ref('')

/** 统计字段：主数字用原值，其余用缩写。 */
const totals = computed(() => ({
  notes: data.value?.totals.notes ?? 0,
  publicNotes: data.value?.totals.public_notes ?? 0,
}))
const totalWords = computed(() => formatWords(data.value?.totals.words ?? 0))
const weekCreated = computed(() => data.value?.week.created ?? 0)

/** 文件夹概况：只取笔记数最多的 6 个。 */
const topFolders = computed(() => (data.value?.folders ?? []).slice(0, 6))

/** 常用标签：按引用数倒序取前 12 个。 */
const topTags = computed(() =>
  [...tags.value].sort((a, b) => b.note_count - a.note_count).slice(0, 12),
)

/** 文件夹占比的基准：最大计数，用来算条形宽度。 */
const maxFolderCount = computed(() =>
  Math.max(1, ...topFolders.value.map((f) => f.count)),
)

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
    const [statsResult, tagResult] = await Promise.allSettled([getStats(), listTags()])
    if (statsResult.status === 'fulfilled') data.value = statsResult.value
    if (tagResult.status === 'fulfilled') tags.value = tagResult.value.items
    if (statsResult.status === 'rejected') throw statsResult.reason
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

    <div class="home-columns">
      <section class="home-panel">
        <h2 class="home-panel__title">写作热力图</h2>
        <p class="field__hint" style="margin-bottom: 10px">近五个月每天编辑过的笔记数。</p>
        <HeatmapChart v-if="data" :cells="data.heatmap" />
        <div v-else class="skeleton skeleton--line" style="width: 100%; height: 80px"></div>
      </section>

      <!-- 统计：笔记数放大做主数字，其余三项用一行小字概括 -->
      <section class="home-panel home-panel--stats">
        <h2 class="home-panel__title">统计</h2>

        <!-- 品字：上面一个主数字居中，下面两个并排 -->
        <div class="stat-trio">
          <div class="stat-cell stat-cell--hero">
            <span v-if="loading" class="skeleton skeleton--title" style="display: block; width: 60px; height: 36px; margin: 0 auto"></span>
            <template v-else>
              <span class="stat-cell__value">{{ totals.notes }}</span>
              <span class="stat-cell__label">篇笔记</span>
            </template>
          </div>

          <div class="stat-cell">
            <span v-if="loading" class="skeleton skeleton--title" style="display: block; width: 44px; height: 24px; margin: 0 auto"></span>
            <template v-else>
              <span class="stat-cell__value">{{ totalWords }}</span>
              <span class="stat-cell__label">字</span>
            </template>
          </div>

          <div class="stat-cell">
            <span v-if="loading" class="skeleton skeleton--title" style="display: block; width: 24px; height: 24px; margin: 0 auto"></span>
            <template v-else>
              <span class="stat-cell__value">{{ totals.publicNotes }}</span>
              <span class="stat-cell__label">篇公开</span>
            </template>
          </div>
        </div>

        <p v-if="!loading" class="stat-foot">
          本周新建 <strong>{{ weekCreated }}</strong> 篇
        </p>
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

    <!-- 第二排：文件夹概况 + 常用标签 -->
    <div class="home-bottom">
      <section class="home-panel">
        <h2 class="home-panel__title">文件夹</h2>
        <p v-if="topFolders.length === 0" class="field__hint">还没有文件夹。</p>
        <ul v-else class="folder-stat-list">
          <li v-for="folder in topFolders" :key="folder.id" class="folder-stat">
            <span class="folder-stat__name">{{ folder.name }}</span>
            <span class="folder-stat__bar" aria-hidden="true">
              <span
                class="folder-stat__bar-fill"
                :style="{ width: `${Math.max(4, (folder.count / maxFolderCount) * 100)}%` }"
              ></span>
            </span>
            <span class="folder-stat__count">{{ folder.count }}</span>
          </li>
        </ul>
      </section>

      <section class="home-panel">
        <h2 class="home-panel__title">常用标签</h2>
        <p v-if="topTags.length === 0" class="field__hint">还没有标签。</p>
        <ul v-else class="tag-chip-list">
          <li v-for="tag in topTags" :key="tag.id" class="tag-chip">
            <span class="tag-chip__name">{{ tag.name }}</span>
            <span class="tag-chip__count">{{ tag.note_count }}</span>
          </li>
        </ul>
      </section>
    </div>
  </div>
</template>
