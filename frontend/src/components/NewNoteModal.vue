<script setup lang="ts">
/**
 * 新建笔记弹窗：先定标题与标签，再进编辑页写正文。
 *
 * 按用户选择，弹窗只把数据暂存在前端（不立刻建空笔记），
 * 首次保存时才真正 POST /api/notes。
 */
import { nextTick, onMounted, onBeforeUnmount, ref } from 'vue'
import { useRouter } from 'vue-router'
import { listTags, type Tag } from '@/api/tags'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{ close: [] }>()

const router = useRouter()

const tags = ref<Tag[]>([])
const loadingTags = ref(true)
const title = ref('')
const selected = ref<string[]>([])
const error = ref('')
const titleInput = ref<HTMLInputElement | null>(null)

function toggle(id: string): void {
  const i = selected.value.indexOf(id)
  if (i >= 0) selected.value.splice(i, 1)
  else selected.value.push(id)
}

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

function start(): void {
  const value = title.value.trim()
  if (!value) {
    error.value = '先给笔记起个标题'
    titleInput.value?.focus()
    return
  }

  // 只带标题与标签进入编辑页；正文在编辑页写，首次保存才创建
  void router.push({
    name: 'note-create',
    query: {
      title: value,
      tag_ids: selected.value.length ? selected.value.join(',') : undefined,
    },
  })
  emit('close')
}

function onKeydown(event: KeyboardEvent): void {
  if (!props.open) return
  if (event.key === 'Escape') emit('close')
}

onMounted(() => {
  void loadTags()
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
          <span class="field__label">标签（可多选）</span>
          <p v-if="loadingTags" class="field__hint">加载中…</p>
          <p v-else-if="tags.length === 0" class="field__hint">
            还没有标签。可以先直接开始，之后再补。
          </p>
          <div v-else class="tag-row">
            <button
              v-for="tag in tags"
              :key="tag.id"
              class="tag"
              type="button"
              :aria-pressed="selected.includes(tag.id)"
              @click="toggle(tag.id)"
            >
              {{ tag.name }}
            </button>
          </div>
        </div>

        <div class="modal__actions">
          <button class="btn" type="button" @click="emit('close')">取消</button>
          <button class="btn btn--primary" type="submit">开始写</button>
        </div>
      </form>
    </div>
  </div>
</template>
