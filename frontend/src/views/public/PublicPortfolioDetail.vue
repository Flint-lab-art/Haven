<script setup lang="ts">
/**
 * 公开作品详情（docs/v3/frontend/frontend.md 第六节）。
 *
 * 告诉访客这个作品是做什么的：标题、简介、正文（Markdown 渲染）、仓库链接。
 */
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import PublicEmpty from '@/components/PublicEmpty.vue'
import { getPublicPortfolioItem, type PortfolioItem, type PortfolioRepo } from '@/api/portfolio'
import { renderMarkdown, decorateLinks } from '@/utils/markdown'

const route = useRoute()

const item = ref<PortfolioItem | null>(null)
const loading = ref(true)
const error = ref('')

const rendered = computed(() => decorateLinks(renderMarkdown(item.value?.content ?? '')))

/** 仓库链接显示平台名，普通链接显示标题（没有标题时退回地址）。 */
function repoLabel(repo: PortfolioRepo): string {
  if (repo.kind === 'link') return repo.title || repo.url
  return repo.kind === 'gogs' ? 'Gogs' : 'GitHub'
}

function sortedRepos(value: PortfolioItem) {
  return [...value.repos].sort((a, b) => Number(b.is_primary) - Number(a.is_primary))
}

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    item.value = await getPublicPortfolioItem(String(route.params.id))
  } catch {
    error.value = '作品加载失败，可能已经下线'
    item.value = null
  } finally {
    loading.value = false
  }
}

watch(() => route.params.id, () => void load())
onMounted(() => void load())
</script>

<template>
  <main class="container container--wide">
    <p class="portfolio-back">
      <RouterLink :to="{ name: 'public-portfolio' }">← 作品集</RouterLink>
    </p>

    <div v-if="loading" class="public-list">
      <div class="skeleton skeleton--title" style="width: 40%"></div>
      <div class="skeleton skeleton--line" style="width: 80%; margin-top: 16px"></div>
    </div>

    <PublicEmpty
      v-else-if="!item"
      title="找不到这个作品"
      :text="error || '它可能已经下线了。'"
    />

    <article v-else class="portfolio-detail">
      <header class="portfolio-detail__head">
        <h1 class="portfolio-detail__title">{{ item.title }}</h1>
        <p v-if="item.description" class="portfolio-detail__sub">{{ item.description }}</p>

        <div v-if="item.repos.length" class="tag-row" style="margin-top: 16px">
          <a
            v-for="repo in sortedRepos(item)"
            :key="repo.id"
            :href="repo.url"
            target="_blank"
            rel="noopener noreferrer"
            class="repo-pill repo-pill--link"
            :class="{ 'repo-pill--primary': repo.is_primary }"
          >
            {{ repoLabel(repo) }}
          </a>
        </div>
      </header>

      <!-- eslint-disable-next-line vue/no-v-html -- 已经过 DOMPurify 过滤 -->
      <div v-if="rendered" class="md-body" v-html="rendered"></div>
      <p v-else class="field__hint">这个作品还没有写介绍。</p>
    </article>
  </main>
</template>
