<script setup lang="ts">
/** 公开作品集（docs/frontend/frontend.md 第三节）。 */
import { onMounted, ref } from 'vue'
import PublicHeader from '@/components/PublicHeader.vue'
import { listPortfolio, type PortfolioItem } from '@/api/portfolio'

const items = ref<PortfolioItem[]>([])
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    const result = await listPortfolio()
    items.value = result.items
  } catch {
    error.value = '作品集加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <PublicHeader />

  <main class="page page--wide">
    <h1 class="page-title" style="margin-bottom: 24px">作品集</h1>

    <p v-if="error" class="notice notice--error">{{ error }}</p>

    <div v-if="loading" class="panel panel--padded">
      <span class="skeleton" style="display: block; width: 40%"></span>
    </div>

    <div v-else-if="items.length === 0" class="panel empty">
      <p class="empty__title">还没有作品</p>
    </div>

    <div v-else class="stack">
      <section v-for="item in items" :key="item.id" class="panel panel--padded">
        <h2 class="card__title" style="font: var(--text-title2)">{{ item.title }}</h2>
        <p v-if="item.description" class="page-subtitle">{{ item.description }}</p>

        <div class="tag-row" style="margin-top: 16px">
          <!-- 主链接优先展示；没有主链接时取第一个 -->
          <a
            v-for="repo in item.repos"
            :key="repo.id"
            class="btn btn--small"
            :class="{ 'btn--primary': repo.is_primary }"
            :href="repo.url"
            target="_blank"
            rel="noopener noreferrer"
          >
            {{ repo.platform === 'gogs' ? 'Gogs' : 'GitHub' }} · {{ repo.repo_path }}
          </a>
          <span v-if="item.repos.length === 0" class="field__hint">暂无仓库链接</span>
        </div>
      </section>
    </div>
  </main>
</template>
