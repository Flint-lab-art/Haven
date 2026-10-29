<script setup lang="ts">
/** 公开作品集：卡片栅格，主链接最显眼。 */
import { onMounted, ref } from 'vue'
import PublicHeader from '@/components/PublicHeader.vue'
import { listPortfolio, type PortfolioItem } from '@/api/portfolio'

const items = ref<PortfolioItem[]>([])
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    items.value = (await listPortfolio()).items
  } catch {
    error.value = '作品集加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
})

function sortedRepos(item: PortfolioItem) {
  // 主链接在前，其余保持后端顺序
  return [...item.repos].sort((a, b) => Number(b.is_primary) - Number(a.is_primary))
}
</script>

<template>
  <div class="shell">
    <PublicHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">作品集</h1>
          <p class="page-sub">
            {{ items.length > 0 ? `共 ${items.length} 个项目` : '正在做的事和写过的东西' }}
          </p>
        </div>
      </header>

      <p v-if="error" class="notice notice--error">{{ error }}</p>

      <div v-else-if="loading" class="portfolio-grid">
        <div v-for="n in 2" :key="n" class="panel panel--pad">
          <div class="skeleton skeleton--title" style="width: 50%"></div>
          <div class="skeleton skeleton--line" style="width: 85%"></div>
        </div>
      </div>

      <div v-else-if="items.length === 0" class="panel empty">
        <p class="empty__title">还没有作品</p>
        <p class="empty__text">项目会连同代码仓库链接一起展示。</p>
      </div>

      <div v-else class="portfolio-grid">
        <article v-for="item in items" :key="item.id" class="portfolio-card">
          <h2 class="portfolio-card__title">{{ item.title }}</h2>
          <p v-if="item.description" class="portfolio-card__desc">{{ item.description }}</p>

          <div v-if="item.repos.length" class="tag-row">
            <a
              v-for="repo in sortedRepos(item)"
              :key="repo.id"
              :href="repo.url"
              target="_blank"
              rel="noopener noreferrer"
              class="repo-link"
              :class="{ 'repo-link--primary': repo.is_primary }"
            >
              {{ repo.platform === 'gogs' ? 'Gogs' : 'GitHub' }}
              <span style="opacity: 0.7">{{ repo.repo_path }}</span>
            </a>
          </div>
          <p v-else class="field__hint">暂无仓库链接</p>
        </article>
      </div>
    </main>
  </div>
</template>
