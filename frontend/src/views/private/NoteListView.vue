<script setup lang="ts">
/** 工作台首页：私有笔记列表。 */
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import PrivateHeader from '@/components/PrivateHeader.vue'
import NewNoteModal from '@/components/NewNoteModal.vue'
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

// 新建笔记：先弹窗定标题与标签，再进编辑页
const showNew = ref(false)
const modal = ref<InstanceType<typeof NewNoteModal> | null>(null)

async function openModal(): Promise<void> {
  showNew.value = true
  await nextTick()
  void modal.value?.focusTitle()
}

const filters = [
  { value: 'all', label: '全部' },
  { value: 'private', label: '私有' },
  { value: 'public', label: '已公开' },
] as const

const subtitle = computed(() => {
  if (loading.value) return '加载中…'
  if (total.value === 0) return '还没有笔记'
  return `共 ${total.value} 篇`
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
  <div class="shell">
    <PrivateHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">笔记</h1>
          <p class="page-sub">{{ subtitle }}</p>
        </div>
        <button class="btn btn--primary btn--lg" type="button" @click="openModal">新建笔记</button>
      </header>

      <div class="segmented" role="group" aria-label="筛选">
        <button
          v-for="option in filters"
          :key="option.value"
          class="segmented__item"
          type="button"
          :aria-pressed="filter === option.value"
          @click="filter = option.value"
        >
          {{ option.label }}
        </button>
      </div>

      <p v-if="error" class="notice notice--error" style="margin-top: var(--sp-4)">
        {{ error }}
        <span class="notice__actions">
          <button class="btn btn--sm" type="button" @click="load()">重试</button>
        </span>
      </p>

      <div v-else-if="loading" class="panel panel--pad" style="margin-top: var(--sp-4)">
        <div class="skeleton skeleton--title" style="width: 42%"></div>
        <div class="skeleton skeleton--line" style="width: 90%"></div>
        <div class="skeleton skeleton--line" style="width: 66%"></div>
      </div>

      <div v-else-if="notes.length === 0" class="panel empty" style="margin-top: var(--sp-4)">
        <p class="empty__title">{{ filter === 'all' ? '还没有笔记' : '这个筛选下没有笔记' }}</p>
        <p class="empty__text">新建一篇，记录今天学到的东西。</p>
        <button class="btn btn--primary" type="button" @click="openModal">新建笔记</button>
      </div>

      <div v-else class="panel rows" style="margin-top: var(--sp-4)">
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

      <div v-if="!loading && notes.length < total" class="row" style="margin-top: var(--sp-6); justify-content: center">
        <button class="btn" type="button" @click="load(notes.length)">加载更多</button>
      </div>
    </main>

    <NewNoteModal ref="modal" :open="showNew" @close="showNew = false" />
  </div>
</template>
