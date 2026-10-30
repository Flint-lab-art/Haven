<script setup lang="ts">
/**
 * 新建笔记弹窗：定好标题与标签后立即创建，再进入编辑页写正文。
 *
 * 立即创建是为了让新笔记马上出现在中间栏的目录树里，
 * 不需要先在正文里输入内容触发自动保存。
 */
import { nextTick, onMounted, onBeforeUnmount, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ApiError } from '@/api/client'
import { createNote } from '@/api/notes'
import { listTags, type Tag } from '@/api/tags'
import { useUiStore } from '@/stores/ui'
import TagPicker from './TagPicker.vue'

const props = defineProps<{
  open: boolean
  /** 新建后归入的文件夹；null / 不传 = 收件箱。 */
  folderId?: string | null
}>()

const emit = defineEmits<{ close: [] }>()

const router = useRouter()
const ui = useUiStore()

const tags = ref<Tag[]>([])
const loadingTags = ref(true)
const title = ref('')
const selected = ref<string[]>([])
const error = ref('')
const creating = ref(false)
const titleInput = ref<HTMLInputElement | null>(null)

async function loadTags(): Promise<void> {
  loadingTags.value = true
  try {
    tags.value = (await listTags()).items
  } catch {
    tags.value = []
  } finally {
    loadingTags.value = false
  }
}

async function start(): Promise<void> {
  const value = title.value.trim()
  if (!value) {
    error.value = '先给笔记起个标题'
    titleInput.value?.focus()
    return
  }
  if (creating.value) return

  creating.value = true
  error.value = ''
  try {
    // 立即创建：标题、标签、文件夹一次写入，笔记随即出现在目录树
    const note = await createNote({
      title: value,
      content: '',
      tag_ids: selected.value,
      folder_id: props.folderId ?? null,
    })

    ui.notesChanged()
    title.value = ''
    selected.value = []
    emit('close')
    await router.push({ name: 'note-detail', params: { id: note.id } })
  } catch (err) {
    if (err instanceof ApiError) {
      error.value = err.fields ? Object.values(err.fields).join('；') : err.message
    } else {
      error.value = '创建失败，请稍后重试'
    }
  } finally {
    creating.value = false
  }
}

function onKeydown(event: KeyboardEvent): void {
  if (!props.open) return
  if (event.key === 'Escape') emit('close')
}

// 每次打开都重新拉一次：标签计数会随其他笔记的编辑变化
watch(
  () => props.open,
  (open) => {
    if (open) void loadTags()
  },
  { immediate: true },
)

onMounted(() => {
  window.addEventListener('keydown', onKeydown)
})

onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))

defineExpose({
  focusTitle: async () => {
    await nextTick()
    titleInput.value?.focus()
  },
})
</script>

<template>
  <div v-if="open" class="modal-backdrop" role="presentation" @click.self="emit('close')">
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="new-note-title">
      <div class="modal__head">
        <div>
          <h2 id="new-note-title" class="modal__title">新建笔记</h2>
          <p class="modal__sub">先定标题和标签，再进编辑页写正文。</p>
        </div>
        <button class="btn btn--sm" type="button" aria-label="关闭" @click="emit('close')">✕</button>
      </div>

      <form @submit.prevent="start">
        <div class="field">
          <label class="field__label" for="new-note-name">标题</label>
          <input
            id="new-note-name"
            ref="titleInput"
            v-model="title"
            class="input"
            type="text"
            placeholder="今天想写点什么？"
            autocomplete="off"
            @input="error = ''"
          />
          <span v-if="error" class="field__error">{{ error }}</span>
        </div>

        <div class="field" style="margin-top: var(--sp-4)">
          <span class="field__label">标签（可多选，也可直接新建）</span>
          <p v-if="loadingTags" class="field__hint">加载中…</p>
          <TagPicker
            v-else
            v-model:selected="selected"
            :tags="tags"
            @changed="loadTags"
          />
        </div>

        <div class="modal__actions">
          <button class="btn" type="button" :disabled="creating" @click="emit('close')">取消</button>
          <button class="btn btn--primary" type="submit" :disabled="creating">
            {{ creating ? '创建中…' : '开始写' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
