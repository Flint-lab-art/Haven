<script setup lang="ts">
/** 公开搜索（docs/frontend/frontend.md 第三节）：只搜已公开笔记。 */
import { ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import PublicHeader from '@/components/PublicHeader.vue'
import SearchBar from '@/components/SearchBar.vue'
import NoteCard from '@/components/NoteCard.vue'
import { searchPublic, type SearchNoteHit } from '@/api/search'
import { formatDate } from '@/utils/format'

const route = useRoute()
const keyword = ref(String(route.query.q ?? ''))
const results = ref<SearchNoteHit[]>([])
const total = ref(0)
const loading = ref(false)
const error = ref('')
const searched = ref('')

async function run(q: string): Promise<void> {
  if (!q.trim()) {
    results.value = []
    total.value = 0
    searched.value = ''
    return
  }

  loading.value = true
  error.value = ''
  searched.value = q
  try {
    const result = await searchPublic(q)
    results.value = result.items
    total.value = result.total
  } catch {
    error.value = '搜索失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

watch(
  () => route.query.q,
  (q) => {
    keyword.value = String(q ?? '')
    void run(keyword.value)
  },
  { immediate: true },
)
</script>

<template>
  <PublicHeader />

  <main class="page">
    <h1 class="page-title" style="margin-bottom: 16px">搜索</h1>

    <SearchBar v-model="keyword" />

    <p v-if="error" class="notice notice--error" style="margin-top: 16px">{{ error }}</p>

    <template v-if="searched">
      <p class="section-caption">
        “{{ searched }}” · 找到 {{ total }} 篇
      </p>

      <div v-if="loading" class="panel panel--padded">
        <span class="skeleton" style="display: block; width: 60%"></span>
      </div>

      <div v-else-if="results.length === 0" class="panel empty">
        <p class="empty__title">没有匹配的笔记</p>
        <p>换个关键词试试。</p>
      </div>

      <div v-else class="panel">
        <NoteCard
          v-for="hit in results"
          :key="hit.id"
          :id="hit.id"
          :title="hit.title"
          :preview="hit.content_preview"
          :tags="hit.tags"
          :meta="formatDate(hit.published_at)"
          :to="`/notes/${hit.id}`"
        />
      </div>
    </template>
  </main>
</template>
