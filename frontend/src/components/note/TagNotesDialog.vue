<script setup lang="ts">
/**
 * 标签引用笔记的居中弹窗（docs/v3/frontend/frontend.md 第五节）。
 *
 * 只读：列出引用该标签的笔记，点标题跳转对应笔记。
 */
import { ref, watch } from 'vue'
import {
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogOverlay,
  DialogPortal,
  DialogRoot,
  DialogTitle,
} from 'reka-ui'
import { ApiError } from '@/api/client'
import { listTagNotes, type Tag } from '@/api/tags'
import type { NoteSummary } from '@/api/notes'
import { formatRelative } from '@/utils/format'
import { X } from 'lucide-vue-next'


const props = defineProps<{
  open: boolean
  tag: Tag | null
}>()

const emit = defineEmits<{
  close: []
  'open-note': [id: string]
}>()

const notes = ref<NoteSummary[]>([])
const loading = ref(false)
const error = ref('')

async function load(): Promise<void> {
  const tag = props.tag
  if (!tag) return

  loading.value = true
  error.value = ''
  notes.value = []
  try {
    const result = await listTagNotes(tag.id)
    // 期间用户可能已关窗或换了标签，避免写回旧结果
    if (!props.open || props.tag?.id !== tag.id) return
    notes.value = result.items
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '笔记加载失败'
  } finally {
    loading.value = false
  }
}

// 点外部 / Esc / 焦点陷阱交给 Reka Dialog；这里只关心「打开时拉数据、关闭时清空」
watch(
  () => [props.open, props.tag?.id] as const,
  ([open]) => {
    if (open) {
      void load()
    } else {
      notes.value = []
      error.value = ''
    }
  },
)
</script>

<template>
  <DialogRoot :open="open && Boolean(tag)" @update:open="(value: boolean) => !value && emit('close')">
    <DialogPortal v-if="tag">
      <DialogOverlay class="modal-backdrop" />
      <DialogContent class="modal tag-notes-modal">
        <header class="tag-notes-modal__head">
          <DialogTitle class="tag-notes-modal__title">{{ tag.name }}</DialogTitle>
          <DialogDescription class="sr-only">引用这个标签的笔记列表</DialogDescription>
          <DialogClose as-child>
            <button class="icon-btn" type="button" aria-label="关闭">
              <X aria-hidden="true" />
            </button>
          </DialogClose>
        </header>

      <p v-if="error" class="notice notice--error" style="margin: 0 0 12px">{{ error }}</p>

      <div v-else-if="loading" class="tag-notes-modal__body">
        <div class="skeleton skeleton--line" style="width: 70%"></div>
        <div class="skeleton skeleton--line" style="width: 55%; margin-top: 12px"></div>
      </div>

      <p v-else-if="notes.length === 0" class="field__hint">这个标签下还没有笔记。</p>

      <ul v-else class="tag-notes-modal__body">
        <li v-for="note in notes" :key="note.id">
          <button class="tag-note-row" type="button" @click="emit('open-note', note.id)">
            <span class="tag-note-row__title">{{ note.title }}</span>
            <span class="tag-note-row__meta">更新于 {{ formatRelative(note.updated_at) }}</span>
          </button>
        </li>
        </ul>
      </DialogContent>
    </DialogPortal>
  </DialogRoot>
</template>
