<script setup lang="ts">
/** 公开作品集：平铺条目，主链接最显眼。 */
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import PublicEmpty from '@/components/PublicEmpty.vue'
import { listPortfolio, type PortfolioItem, type PortfolioRepo } from '@/api/portfolio'

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

/** 仓库链接显示平台名，普通链接显示标题（没有标题时退回地址）。 */
function repoLabel(repo: PortfolioRepo): string {
  if (repo.kind === 'link') return repo.title || repo.url
  return repo.kind === 'gogs' ? 'Gogs' : 'GitHub'
}

function sortedRepos(item: PortfolioItem) {
  // 主链接在前，其余保持后端顺序
  return [...item.repos].sort((a, b) => Number(b.is_primary) - Number(a.is_primary))
}
</script>

<template>
  <main class="container container--wide">
    <header class="public-page-head">
      <h1 class="public-page-head__title">作品集</h1>
      <p class="public-page-head__sub">
        {{ items.length > 0 ? `共 ${items.length} 个项目` : '正在做的事和写过的东西' }}
      </p>
    </header>

    <p v-if="error" class="notice notice--error">{{ error }}</p>

    <div v-else-if="loading" class="public-list">
      <div v-for="n in 2" :key="n" class="public-project">
        <div class="skeleton skeleton--title" style="width: 40%"></div>
        <div class="skeleton skeleton--line" style="width: 80%; margin-top: 12px"></div>
      </div>
    </div>

    <PublicEmpty
      v-else-if="items.length === 0"
      title="作品还在整理中"
      text="项目会连同代码仓库链接一起展示。"
    />

    <div v-else class="public-list">
      <div v-for="item in items" :key="item.id" class="public-project">
        <h2 class="public-project__title">
          <RouterLink
            :to="{ name: 'public-portfolio-detail', params: { id: item.id } }"
            class="public-project__link"
          >
            {{ item.title }}
          </RouterLink>
        </h2>
        <p v-if="item.description" class="public-project__desc">{{ item.description }}</p>

        <div v-if="item.repos.length" class="tag-row public-project__repos">
          <a
            v-for="repo in sortedRepos(item)"
            :key="repo.id"
            :href="repo.url"
            target="_blank"
            rel="noopener noreferrer"
            class="repo-link"
            :class="{ 'repo-link--primary': repo.is_primary }"
          >
            {{ repoLabel(repo) }}
          </a>
        </div>
        <p v-else class="field__hint">暂无仓库链接</p>
      </div>
    </div>
  </main>
</template>
