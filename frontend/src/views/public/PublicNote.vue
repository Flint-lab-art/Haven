<script setup lang="ts">
/** 公开笔记详情：以阅读为中心，正文限宽 68ch。 */
import { onMounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import PublicHeader from '@/components/PublicHeader.vue'
import TagBadge from '@/components/TagBadge.vue'
import { getPublicNote, type PublicNote } from '@/api/notes'
import { formatDate } from '@/utils/format'

const route = useRoute()
const note = ref<PublicNote | null>(null)
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    note.value = await getPublicNote(String(route.params.id))
  } catch {
    error.value = '这篇笔记不存在，或尚未公开'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="shell">
    <PublicHeader />

    <main class="container container--reading">
      <div v-if="loading" class="panel panel--pad">
        <div class="skeleton skeleton--title" style="width: 56%"></div>
        <div class="skeleton skeleton--line" style="width: 92%"></div>
        <div class="skeleton skeleton--line" style="width: 88%"></div>
        <div class="skeleton skeleton--line" style="width: 64%"></div>
      </div>

      <div v-else-if="error" class="panel empty">
        <p class="empty__title">{{ error }}</p>
        <p class="empty__text">链接可能已失效，或者作者撤回了公开。</p>
        <RouterLink :to="{ name: 'public-home' }" class="btn">返回笔记列表</RouterLink>
      </div>

      <article v-else-if="note" class="panel panel--pad">
        <RouterLink :to="{ name: 'public-home' }" class="btn btn--quiet btn--sm" style="margin-bottom: var(--sp-4)">
          ← 全部笔记
        </RouterLink>

        <header class="article">
          <h1 class="article__title">{{ note.title }}</h1>
          <div class="article__meta">
            <span>{{ formatDate(note.published_at) }}</span>
            <template v-if="note.tags.length">
              <span class="meta-dot"></span>
              <div class="tag-row">
                <TagBadge
                  v-for="tag in note.tags"
                  :key="tag.id"
                  :name="tag.name"
                  :to="`/search?q=${encodeURIComponent(tag.name)}`"
                />
              </div>
            </template>
          </div>
        </header>

        <div class="article__body">{{ note.content }}</div>
      </article>
    </main>
  </div>
</template>
