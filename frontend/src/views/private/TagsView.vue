<script setup lang="ts">
/**
 * 右侧标签详情：新建标签、查看某个标签下的笔记、物理删除标签。
 *
 * 标签随笔记生命周期出现 / 隐藏；只有这里可以做物理删除（docs/backend/data-model.md 第四节）。
 */
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import { ApiError } from '@/api/client'
import {
  createTag,
  deleteTag,
  listTagNotes,
  listTags,
  type Tag,
} from '@/api/tags'
import type { NoteSummary } from '@/api/notes'
import { useUiStore } from '@/stores/ui'
import { formatRelative } from '@/utils/format'

const ui = useUiStore()

const tags = ref<Tag[]>([])
const name = ref('')
const creating = ref(false)
const error = ref('')

const tagNotes = ref<NoteSummary[]>([])
const notesLoading = ref(false)

const pendingTag = ref<Tag | null>(null)
const deleting = ref(false)

const selected = computed(() => tags.value.find((tag) => tag.id === ui.selectedTagId) ?? null)

async function load(): Promise<void> {
  try {
    tags.value = (await listTags()).items
    if (ui.selectedTagId && !tags.value.some((tag) => tag.id === ui.selectedTagId)) {
      ui.selectTag(null)
    }
  } catch {
    error.value = '标签加载失败，请稍后重试'
  }
}

async function loadNotes(id: string | null): Promise<void> {
  tagNotes.value = []
  if (!id) return

  notesLoading.value = true
  try {
    tagNotes.value = (await listTagNotes(id)).items
  } catch {
    // 笔记列表拉取失败不影响标签本身的操作
  } finally {
    notesLoading.value = false
  }
}

async function create(): Promise<void> {
  const value = name.value.trim()
  if (!value || creating.value) return

  creating.value = true
  error.value = ''
  try {
    const tag = await createTag(value)
    name.value = ''
    ui.selectTag(tag.id)
    ui.tagsChanged()
    await load()
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) {
      error.value = `标签「${value}」已存在`
    } else {
      error.value = err instanceof ApiError ? err.message : '创建失败，请稍后重试'
    }
  } finally {
    creating.value = false
  }
}

function remove(tag: Tag): void {
  pendingTag.value = tag
}

async function confirmRemove(): Promise<void> {
  const tag = pendingTag.value
  if (!tag || deleting.value) return

  deleting.value = true
  error.value = ''
  try {
    await deleteTag(tag.id)
    ui.selectTag(null)
    ui.tagsChanged()
    await load()
    pendingTag.value = null
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '删除失败，请稍后重试'
    pendingTag.value = null
  } finally {
    deleting.value = false
  }
}

watch(
  () => ui.tagsVersion,
  () => void load(),
)
watch(
  () => ui.selectedTagId,
  (id) => void loadNotes(id),
)

onMounted(async () => {
  await load()
  await loadNotes(ui.selectedTagId)
})
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">标签</h1>
      <p class="detail-sub">标签跟随笔记出现；计数归零后自动从列表隐藏。</p>
    </header>

    <form class="row" style="gap: 9px" @submit.prevent="create">
      <input
        v-model="name"
        class="input"
        type="text"
        placeholder="新标签名"
        aria-label="新标签名"
        maxlength="64"
      />
      <button class="btn btn--primary" type="submit" :disabled="creating">添加</button>
    </form>

    <p v-if="error" class="notice notice--error" style="margin-top: 16px">{{ error }}</p>

    <section v-if="selected" class="tag-detail">
      <div class="tag-detail__head">
        <div>
          <h2 class="tag-detail__name">{{ selected.name }}</h2>
          <p class="field__hint">{{ selected.note_count }} 篇笔记</p>
        </div>
        <button class="btn btn--danger btn--sm" type="button" @click="remove(selected)">删除标签</button>
      </div>

      <div v-if="notesLoading" style="margin-top: 16px">
        <div class="skeleton skeleton--line" style="width: 60%"></div>
      </div>

      <p v-else-if="tagNotes.length === 0" class="field__hint" style="margin-top: 16px">
        这个标签下还没有笔记。
      </p>

      <ul v-else class="rows" style="margin-top: 16px; border: 1px solid var(--sep); border-radius: 10px">
        <li v-for="note in tagNotes" :key="note.id">
          <RouterLink :to="{ name: 'note-detail', params: { id: note.id } }" class="row-item row-item--tappable">
            <div class="row-item__main">
              <div class="row-item__title">{{ note.title }}</div>
              <div class="row-item__sub">更新于 {{ formatRelative(note.updated_at) }}</div>
            </div>
            <span class="row-item__chevron" aria-hidden="true">›</span>
          </RouterLink>
        </li>
      </ul>
    </section>

    <p v-else class="field__hint" style="margin-top: 24px">在左侧选择一个标签查看详情。</p>

    <ConfirmDialog
      :open="pendingTag !== null"
      title="删除标签"
      :message="`删除标签「${pendingTag?.name ?? ''}」？笔记不会删除，只解除关联。`"
      :busy="deleting"
      @confirm="confirmRemove"
      @cancel="pendingTag = null"
    />
  </div>
</template>
