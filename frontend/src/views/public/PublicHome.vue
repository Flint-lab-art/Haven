<script setup lang="ts">
/** 公开域首页：公开笔记列表 + 搜索入口。 */
import { onMounted, ref } from 'vue'
import SearchBar from '@/components/SearchBar.vue'
import PublicEmpty from '@/components/PublicEmpty.vue'
import PublicNoteRow from '@/components/PublicNoteRow.vue'
import { listPublicNotes, type PublicNoteSummary } from '@/api/notes'

const PAGE_SIZE = 20

const notes = ref<PublicNoteSummary[]>([])
const total = ref(0)
const loading = ref(true)
const error = ref('')
const keyword = ref('')

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
  <main class="container">
    <header class="public-intro">
      <h1 class="public-intro__title">公开笔记</h1>
      <p class="public-intro__sub">写作、阅读与查资料记录。</p>
      <SearchBar v-model="keyword" placeholder="搜索公开笔记" />
    </header>

    <p v-if="error" class="notice notice--error">
      {{ error }}
      <span class="notice__actions">
        <button class="btn btn--sm" type="button" @click="load()">重试</button>
      </span>
    </p>

    <div v-else-if="loading && notes.length === 0" class="public-list public-notes">
      <div v-for="n in 3" :key="n" class="public-row">
        <div class="skeleton skeleton--title" style="width: 46%"></div>
        <div class="skeleton skeleton--line" style="width: 88%; margin-top: 12px"></div>
        <div class="skeleton skeleton--line" style="width: 62%"></div>
      </div>
    </div>

    <PublicEmpty
      v-else-if="notes.length === 0"
      title="这里还空空的"
      text="等第一篇公开笔记出现时，这里就会热闹起来。"
    />

    <div v-else class="public-list public-notes">
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

    <p v-if="!loading && notes.length > 0" class="public-count">共 {{ total }} 篇公开笔记</p>
  </main>
</template>
