<script setup lang="ts">
/**
 * 标签引用笔记的居中弹窗（docs/v3/frontend/frontend.md 第五节）。
 *
 * 只读：列出引用该标签的笔记，点标题跳转对应笔记。
 */
import { onBeforeUnmount, ref, watch } from 'vue'
import { ApiError } from '@/api/client'
import { listTagNotes, type Tag } from '@/api/tags'
import type { NoteSummary } from '@/api/notes'
import { formatRelative } from '@/utils/format'

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
const dialogRef = ref<HTMLElement | null>(null)

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

function onPointerDown(event: PointerEvent): void {
  if (!props.open) return
  const target = event.target as Node | null
  if (dialogRef.value && target && dialogRef.value.contains(target)) return
  emit('close')
}

function onKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape' && props.open) emit('close')
}

watch(
  () => [props.open, props.tag?.id] as const,
  ([open]) => {
    if (open) {
      void load()
      document.addEventListener('pointerdown', onPointerDown, true)
      document.addEventListener('keydown', onKeydown)
    } else {
      notes.value = []
      error.value = ''
      document.removeEventListener('pointerdown', onPointerDown, true)
      document.removeEventListener('keydown', onKeydown)
    }
  },
)

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', onPointerDown, true)
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <div v-if="open && tag" class="modal-backdrop" role="presentation">
    <div ref="dialogRef" class="modal tag-notes-modal" role="dialog" aria-modal="true" :aria-label="tag.name">
      <header class="tag-notes-modal__head">
        <h2 class="tag-notes-modal__title">{{ tag.name }}</h2>
        <button class="icon-btn" type="button" aria-label="关闭" @click="emit('close')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true">
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
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
    </div>
  </div>
</template>
