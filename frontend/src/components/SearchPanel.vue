<script setup lang="ts">
/** 中间栏搜索（私有域）：输入关键词，结果平铺在列表里，点击进入右侧笔记。 */
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import NoteListItem from './NoteListItem.vue'
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

function submit(): void {
  const q = keyword.value.trim()
  void router.push({ path: '/search', query: q ? { q } : {} })
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
  <div class="list-panel">
    <header class="panel-head">
      <h1 class="panel-title">搜索</h1>
      <span v-if="searched" class="field__hint">{{ noteTotal }} 篇</span>
    </header>

    <div class="panel-tools">
      <form role="search" @submit.prevent="submit">
        <input
          v-model="keyword"
          class="input"
          type="search"
          placeholder="搜索标题、正文或标签"
          aria-label="搜索"
          autocomplete="off"
          spellcheck="false"
        />
      </form>
    </div>

    <p v-if="error" class="notice notice--error" style="margin: 0 16px 12px">{{ error }}</p>

    <div v-if="!searched" class="detail-empty" style="min-height: 40svh">
      <p class="detail-empty__title">输入关键词开始搜索</p>
      <p class="detail-empty__text">支持标题、正文与标签，2 个字以上效果最好。</p>
    </div>

    <template v-else>
      <div v-if="tagHits.length" class="search-tags">
        <button
          v-for="tag in tagHits"
          :key="tag.id"
          class="tag"
          type="button"
          @click="router.push({ path: '/search', query: { q: tag.name } })"
        >
          {{ tag.name }} · {{ tag.note_count }}
        </button>
      </div>

      <div v-if="loading" style="padding: 0 16px 16px">
        <div class="skeleton skeleton--title" style="width: 48%"></div>
        <div class="skeleton skeleton--line" style="width: 84%; margin-top: 12px"></div>
      </div>

      <div v-else-if="noteHits.length === 0" class="detail-empty" style="min-height: 32svh">
        <p class="detail-empty__title">没有匹配的笔记</p>
        <p class="detail-empty__text">换个关键词试试。</p>
      </div>

      <div v-else class="note-list">
        <NoteListItem
          v-for="hit in noteHits"
          :key="hit.id"
          :id="hit.id"
          :title="hit.title"
          :preview="hit.content_preview"
          :meta="`更新于 ${formatRelative(hit.updated_at)}`"
          :visibility="hit.visibility ?? 'private'"
        />
      </div>
    </template>
  </div>
</template>
