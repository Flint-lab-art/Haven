<script setup lang="ts">
/**
 * 全部公开笔记（docs/v3/frontend/frontend.md 第五节）。
 *
 * 沿用 v1 的「加载更多」分页，不做分页器；行距比首页宽松，字号回到 20px。
 */
import { onMounted, ref } from 'vue'
import PublicEmpty from '@/components/PublicEmpty.vue'
import PublicNoteRow from '@/components/PublicNoteRow.vue'
import { listPublicNotes, type PublicNoteSummary } from '@/api/notes'

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

onMounted(() => void load())
</script>

<template>
  <main class="container container--wide">
    <header class="public-page-head">
      <h1 class="public-page-head__title">公开笔记</h1>
      <p class="public-page-head__sub">
        {{ total > 0 ? `共 ${total} 篇公开笔记` : '写作、阅读与查资料记录。' }}
      </p>
    </header>

    <p v-if="error" class="notice notice--error">
      {{ error }}
      <span class="notice__actions">
        <button class="btn btn--sm" type="button" @click="load()">重试</button>
      </span>
    </p>

    <div v-else-if="loading && notes.length === 0" class="notes-list">
      <div v-for="n in 3" :key="n" class="public-row">
        <div class="skeleton skeleton--title" style="width: 46%"></div>
        <div class="skeleton skeleton--line" style="width: 88%; margin-top: 12px"></div>
        <div class="skeleton skeleton--line" style="width: 62%"></div>
      </div>
    </div>

    <PublicEmpty
      v-else-if="notes.length === 0"
      title="还没有公开的笔记"
      text="公开出去的笔记会出现在这里。"
    />

    <div v-else class="notes-list">
      <PublicNoteRow
        v-for="note in notes"
        :key="note.id"
        :id="note.id"
        :title="note.title"
        :preview="note.content_preview"
        :published-at="note.published_at"
      />
    </div>

    <div v-if="!loading && notes.length > 0 && notes.length < total" class="public-more">
      <button class="btn" type="button" @click="load(notes.length)">加载更多</button>
    </div>
  </main>
</template>
