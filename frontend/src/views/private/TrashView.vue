<script setup lang="ts">
/**
 * 右侧回收站详情：只读预览 + 还原 / 永久删除（docs/v2/frontend/frontend.md 3.2）。
 *
 * 回收站只回答「这篇笔记还在不在」，不提供编辑、发布、改标签，
 * 也不提供历史版本入口——那个只在编辑页出现。
 */
import { computed, ref, watch } from 'vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import EmptyDetail from '@/components/EmptyDetail.vue'
import { ApiError } from '@/api/client'
import { listTrash, purgeNote, restoreNote, type TrashItem } from '@/api/notes'
import { useUiStore } from '@/stores/ui'
import { renderMarkdown } from '@/utils/markdown'
import { formatDateTime } from '@/utils/format'

const ui = useUiStore()

const items = ref<TrashItem[]>([])
const loading = ref(false)
const busy = ref(false)
const error = ref('')
const notice = ref('')

const confirmPurge = ref(false)

const selected = computed(() => items.value.find((item) => item.id === ui.selectedTrashId) ?? null)

/** 回收站里只能拿到预览文本，没有完整正文；这里只展示标题与元信息。 */
const renderedPreview = computed(() => {
  const item = selected.value
  return item ? renderMarkdown(item.content_preview) : ''
})

async function load(): Promise<void> {
  if (!ui.selectedTrashId) {
    items.value = []
    return
  }
  loading.value = true
  error.value = ''
  try {
    // 回收站条目由中间栏维护，这里按 id 从同一接口取当前数据，避免跨栏重复请求全量。
    const result = await listTrash(100, 0)
    items.value = result.items
    if (!items.value.some((item) => item.id === ui.selectedTrashId)) {
      ui.selectTrash(null)
    }
  } catch {
    error.value = '笔记加载失败'
  } finally {
    loading.value = false
  }
}

async function restore(): Promise<void> {
  const item = selected.value
  if (!item || busy.value) return

  busy.value = true
  error.value = ''
  notice.value = ''
  try {
    const note = await restoreNote(item.id)
    ui.selectTrash(null)
    ui.trashChanged()
    ui.notesChanged()
    notice.value = `已还原「${note.title}」`
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '还原失败'
  } finally {
    busy.value = false
  }
}

async function purge(): Promise<void> {
  const item = selected.value
  if (!item || busy.value) return

  busy.value = true
  error.value = ''
  notice.value = ''
  try {
    await purgeNote(item.id)
    ui.selectTrash(null)
    ui.trashChanged()
    ui.notesChanged()
    confirmPurge.value = false
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '永久删除失败'
    confirmPurge.value = false
  } finally {
    busy.value = false
  }
}

watch(
  () => ui.selectedTrashId,
  () => {
    notice.value = ''
    void load()
  },
)
watch(
  () => ui.trashVersion,
  () => void load(),
)
</script>

<template>
  <!-- 空状态必须是 .detail-pane 的直接子元素才能垂直居中（style.css 的 .detail-pane > .detail-empty） -->
  <EmptyDetail v-if="!selected" />

  <div v-else-if="loading" class="detail-inner">
    <div class="skeleton skeleton--title" style="width: 40%"></div>
  </div>

  <div v-else class="detail-inner detail-inner--trash">
    <header class="detail-head">
      <div>
        <h2 class="detail-title">{{ selected.title }}</h2>
        <p class="detail-meta">
          <span v-if="selected.folder_path">{{ selected.folder_path }}</span>
          <span v-if="selected.folder_path" class="meta-dot"></span>
          <span>删除于 {{ formatDateTime(selected.deleted_at) }}</span>
        </p>
      </div>
      <div class="editor-actions">
        <button class="btn btn--primary btn--sm" type="button" :disabled="busy" @click="restore">
          还原
        </button>
        <button class="btn btn--danger btn--sm" type="button" :disabled="busy" @click="confirmPurge = true">
          永久删除
        </button>
      </div>
    </header>

    <p v-if="notice" class="notice notice--success" style="margin: 0 0 12px">{{ notice }}</p>
    <p v-if="error" class="notice notice--error" style="margin: 0 0 12px">{{ error }}</p>

    <!-- eslint-disable-next-line vue/no-v-html -- 已经过 DOMPurify 过滤 -->
    <div v-if="renderedPreview" class="md-body" v-html="renderedPreview"></div>
    <p v-else class="field__hint">这篇笔记没有正文。</p>
  </div>

  <ConfirmDialog
    :open="confirmPurge"
    title="永久删除"
    :message="`永久删除「${selected?.title ?? ''}」后无法恢复。`"
    :busy="busy"
    @confirm="purge"
    @cancel="confirmPurge = false"
  />
</template>
