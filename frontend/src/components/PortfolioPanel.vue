<script setup lang="ts">
/** 中间栏作品集列表；新增与编辑在右侧。 */
import { onMounted, ref, watch } from 'vue'
import { listPortfolio, type PortfolioItem } from '@/api/portfolio'
import { useUiStore } from '@/stores/ui'

const ui = useUiStore()

const items = ref<PortfolioItem[]>([])
const loading = ref(true)
const error = ref('')

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    items.value = (await listPortfolio()).items
  } catch {
    error.value = '作品集加载失败'
  } finally {
    loading.value = false
  }
}

watch(
  () => ui.portfolioVersion,
  () => void load(),
)
onMounted(() => void load())
</script>

<template>
  <div class="list-panel">
    <header class="panel-head">
      <h1 class="panel-title">作品集</h1>
      <button class="btn btn--primary btn--sm" type="button" @click="ui.startPortfolioCreate()">添加</button>
    </header>

    <p v-if="error" class="notice notice--error" style="margin: 0 16px 12px">{{ error }}</p>

    <div v-if="loading && items.length === 0" style="padding: 0 16px">
      <div class="skeleton skeleton--title" style="width: 44%"></div>
    </div>

    <div v-else-if="items.length === 0" class="detail-empty" style="min-height: 40svh">
      <p class="detail-empty__title">还没有作品</p>
      <p class="detail-empty__text">添加作品和仓库链接，公开首页会展示它们。</p>
      <button class="btn btn--primary" type="button" @click="ui.startPortfolioCreate()">添加作品</button>
    </div>

    <div v-else class="list-rows">
      <button
        v-for="item in items"
        :key="item.id"
        class="list-row"
        :class="{ 'list-row--active': ui.selectedPortfolioId === item.id }"
        type="button"
        @click="ui.selectPortfolio(item.id)"
      >
        <span class="list-row__title">{{ item.title }}</span>
        <span class="list-row__meta">{{ item.repos.length }} 个仓库</span>
      </button>
    </div>
  </div>
</template>
