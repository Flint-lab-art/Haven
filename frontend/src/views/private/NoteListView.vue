<script setup lang="ts">
/** 工作台首页：私有笔记列表（docs/frontend/frontend.md 第四节）。 */
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import PrivateHeader from '@/components/PrivateHeader.vue'
import NoteCard from '@/components/NoteCard.vue'
import { listNotes, type NoteSummary } from '@/api/notes'
import { formatRelative } from '@/utils/format'

const PAGE_SIZE = 20

type Filter = 'all' | 'private' | 'public'

const notes = ref<NoteSummary[]>([])
const total = ref(0)
const loading = ref(true)
const error = ref('')
const filter = ref<Filter>('all')

const filterLabel = computed(() => {
  switch (filter.value) {
    case 'private':
      return '私有'
    case 'public':
      return '已公开'
    default:
      return '全部'
  }
})

async function load(offset = 0): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const result = await listNotes({
      limit: PAGE_SIZE,
      offset,
      visibility: filter.value === 'all' ? undefined : filter.value,
    })
    notes.value = offset === 0 ? result.items : [...notes.value, ...result.items]
    total.value = result.total
  } catch {
    error.value = '笔记加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

watch(filter, () => void load())
onMounted(() => load())
</script>

<template>
  <PrivateHeader />

  <main class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">笔记</h1>
        <p class="page-subtitle">共 {{ total }} 篇 · {{ filterLabel }}</p>
      </div>
      <RouterLink :to="{ name: 'note-new' }" class="btn btn--primary">新建笔记</RouterLink>
    </div>

    <div class="row" style="gap: 4px; margin-bottom: 16px">
      <button
        v-for="option in [
          { value: 'all', label: '全部' },
          { value: 'private', label: '私有' },
          { value: 'public', label: '已公开' },
        ] as const"
        :key="option.value"
        class="pill-toggle"
        :aria-pressed="filter === option.value"
        type="button"
        @click="filter = option.value"
      >
        {{ option.label }}
      </button>
    </div>

    <p v-if="error" class="notice notice--error">{{ error }}</p>

    <div v-if="loading" class="panel panel--padded">
      <div class="skeleton" style="width: 45%"></div>
      <div class="skeleton" style="width: 85%"></div>
    </div>

    <div v-else-if="notes.length === 0" class="panel empty">
      <p class="empty__title">还没有笔记</p>
      <p style="margin-bottom: 16px">新建一篇，记录今天学到的东西。</p>
      <RouterLink :to="{ name: 'note-new' }" class="btn btn--primary">新建笔记</RouterLink>
    </div>

    <div v-else class="panel">
      <NoteCard
        v-for="note in notes"
        :key="note.id"
        :id="note.id"
        :title="note.title"
        :preview="note.content_preview"
        :tags="note.tags"
        :meta="`更新于 ${formatRelative(note.updated_at)}`"
        :visibility="note.visibility"
      />
    </div>

    <div v-if="!loading && notes.length < total" class="row" style="margin-top: 24px; justify-content: center">
      <button class="btn" type="button" @click="load(notes.length)">加载更多</button>
    </div>
  </main>
</template>
