<script setup lang="ts">
/** 私有搜索：笔记 + 标签两块结果。 */
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
  <div class="shell">
    <PrivateHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">搜索</h1>
          <p v-if="searched" class="page-sub">“{{ searched }}” · {{ noteTotal }} 篇笔记</p>
          <p v-else class="page-sub">在所有私有与公开笔记里查找</p>
        </div>
      </header>

      <SearchBar v-model="keyword" large />

      <p v-if="error" class="notice notice--error" style="margin-top: var(--sp-4)">{{ error }}</p>

      <template v-if="searched">
        <template v-if="tagHits.length">
          <p class="section-label">标签</p>
          <div class="tag-row">
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
        </template>

        <p class="section-label">笔记</p>

        <div v-if="loading" class="panel panel--pad">
          <div class="skeleton skeleton--title" style="width: 48%"></div>
          <div class="skeleton skeleton--line" style="width: 84%"></div>
        </div>

        <div v-else-if="noteHits.length === 0" class="panel empty">
          <p class="empty__title">没有匹配的笔记</p>
          <p class="empty__text">换个关键词，或回到全部笔记。</p>
          <button class="btn" type="button" @click="router.push({ name: 'workbench' })">
            返回笔记列表
          </button>
        </div>

        <div v-else class="panel rows">
          <NoteCard
            v-for="hit in noteHits"
            :key="hit.id"
            :id="hit.id"
            :title="hit.title"
            :preview="hit.content_preview"
            :tags="hit.tags"
            :meta="`更新于 ${formatRelative(hit.updated_at)}`"
            :visibility="hit.visibility ?? null"
          />
        </div>
      </template>

      <div v-else class="panel empty" style="margin-top: var(--sp-6)">
        <p class="empty__title">输入关键词开始搜索</p>
        <p class="empty__text">支持标题、正文与标签；2 个字以上效果最好。</p>
      </div>
    </main>
  </div>
</template>
