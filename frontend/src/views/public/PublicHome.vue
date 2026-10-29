<script setup lang="ts">
/** 公开域首页：公开笔记列表。 */
import { onMounted, ref } from 'vue'
import PublicHeader from '@/components/PublicHeader.vue'
import NoteCard from '@/components/NoteCard.vue'
import { listPublicNotes, type PublicNoteSummary } from '@/api/notes'
import { formatDate } from '@/utils/format'

const PAGE_SIZE = 20

const notes = ref<PublicNoteSummary[]>([])
const total = ref(0)
const loading = ref(true)
const error = ref('')

async function load(offset = 0): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const result = await listPublicNotes(PAGE_SIZE, offset)
    notes.value = offset === 0 ? result.items : [...notes.value, ...result.items]
    total.value = result.total
  } catch {
    error.value = '笔记加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

onMounted(() => load())
</script>

<template>
  <div class="shell">
    <PublicHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">笔记</h1>
          <p class="page-sub">
            {{ total > 0 ? `共 ${total} 篇公开笔记` : '公开的写作与查资料记录' }}
          </p>
        </div>
      </header>

      <p v-if="error" class="notice notice--error">
        {{ error }}
        <span class="notice__actions">
          <button class="btn btn--sm" type="button" @click="load()">重试</button>
        </span>
      </p>

      <div v-else-if="loading" class="panel panel--pad">
        <div class="skeleton skeleton--title" style="width: 44%"></div>
        <div class="skeleton skeleton--line" style="width: 92%"></div>
        <div class="skeleton skeleton--line" style="width: 70%"></div>
      </div>

      <div v-else-if="notes.length === 0" class="panel empty">
        <p class="empty__title">还没有公开的笔记</p>
        <p class="empty__text">发布后的笔记会出现在这里。</p>
      </div>

      <div v-else class="panel rows">
        <NoteCard
          v-for="note in notes"
          :key="note.id"
          :id="note.id"
          :title="note.title"
          :preview="note.content_preview"
          :tags="note.tags"
          :meta="formatDate(note.published_at)"
          :to="`/notes/${note.id}`"
        />
      </div>

      <div v-if="!loading && notes.length < total" class="row" style="margin-top: var(--sp-6); justify-content: center">
        <button class="btn" type="button" @click="load(notes.length)">加载更多</button>
      </div>
    </main>
  </div>
</template>
