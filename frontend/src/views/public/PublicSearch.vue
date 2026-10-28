<script setup lang="ts">
/** 公开搜索：只搜已公开笔记。 */
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
  searched.value = q.trim()
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
  <div class="shell">
    <PublicHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">搜索</h1>
          <p v-if="searched" class="page-sub">“{{ searched }}” · {{ total }} 篇结果</p>
          <p v-else class="page-sub">按标题、正文或标签查找公开笔记</p>
        </div>
      </header>

      <SearchBar v-model="keyword" large />

      <p v-if="error" class="notice notice--error" style="margin-top: var(--sp-4)">{{ error }}</p>

      <template v-if="searched">
        <div v-if="loading" class="panel panel--pad" style="margin-top: var(--sp-6)">
          <div class="skeleton skeleton--title" style="width: 50%"></div>
          <div class="skeleton skeleton--line" style="width: 80%"></div>
        </div>

        <div v-else-if="results.length === 0" class="panel empty" style="margin-top: var(--sp-6)">
          <p class="empty__title">没有匹配的笔记</p>
          <p class="empty__text">换个关键词试试，或浏览全部笔记。</p>
        </div>

        <div v-else class="panel rows" style="margin-top: var(--sp-6)">
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
  </div>
</template>
