<script setup lang="ts">
/** 私有搜索（docs/frontend/frontend.md 第四节）：笔记 + 标签两块结果。 */
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SearchBar from '@/components/SearchBar.vue'
import NoteCard from '@/components/NoteCard.vue'
import { searchPrivate, type SearchNoteHit, type SearchTagHit } from '@/api/search'
import { formatRelative } from '@/utils/format'

const route = useRoute()
const router = useRouter()

const keyword = ref(String(route.query.q ?? ''))
const noteHits = ref<SearchNoteHit[]>([])
const noteTotal = ref(0)
const tagHits = ref<SearchTagHit[]>([])
const loading = ref(false)
const error = ref('')
const searched = ref('')

async function run(q: string): Promise<void> {
  const trimmed = q.trim()
  if (!trimmed) {
    noteHits.value = []
    tagHits.value = []
    noteTotal.value = 0
    searched.value = ''
    return
  }

  loading.value = true
  error.value = ''
  searched.value = trimmed
  try {
    const result = await searchPrivate(trimmed)
    noteHits.value = result.notes.items
    noteTotal.value = result.notes.total
    tagHits.value = result.tags.items
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
  <PrivateHeader />

  <main class="page">
    <h1 class="page-title" style="margin-bottom: 16px">搜索</h1>

    <SearchBar v-model="keyword" />

    <p v-if="error" class="notice notice--error" style="margin-top: 16px">{{ error }}</p>

    <template v-if="searched">
      <template v-if="tagHits.length">
        <p class="section-caption">标签</p>
        <div class="tag-row" style="margin-top: 0">
          <RouterLink
            v-for="tag in tagHits"
            :key="tag.id"
            :to="{ name: 'tags' }"
            class="tag"
          >
            {{ tag.name }} · {{ tag.note_count }}
          </RouterLink>
        </div>
      </template>

      <p class="section-caption">笔记 · {{ noteTotal }} 篇</p>

      <div v-if="loading" class="panel panel--padded">
        <span class="skeleton" style="display: block; width: 60%"></span>
      </div>

      <div v-else-if="noteHits.length === 0" class="panel empty">
        <p class="empty__title">没有匹配的笔记</p>
        <button class="btn" type="button" @click="router.push({ name: 'workbench' })">
          返回笔记列表
        </button>
      </div>

      <div v-else class="panel">
        <NoteCard
          v-for="hit in noteHits"
          :key="hit.id"
          :id="hit.id"
          :title="hit.title"
          :preview="hit.content_preview"
          :tags="hit.tags"
          :meta="`更新于 ${formatRelative(hit.updated_at)}`"
        />
      </div>
    </template>
  </main>
</template>
