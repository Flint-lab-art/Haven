<script setup lang="ts">
/**
 * 笔记详情 / 编辑（docs/frontend/frontend.md 第四节 /notes/:id 与 /notes/new）。
 *
 * 一个页面承担两种角色：有 id 走详情编辑，无 id 走新建。
 * 写操作全部依赖登录 + write 权限；read Token 会收到 403。
 */
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import PrivateHeader from '@/components/PrivateHeader.vue'
import { ApiError } from '@/api/client'
import {
  createNote,
  deleteNote,
  getNote,
  publishNote,
  unpublishNote,
  updateNote,
  type Note,
} from '@/api/notes'
import { listTags, type Tag } from '@/api/tags'
import { formatDateTime } from '@/utils/format'

const route = useRoute()
const router = useRouter()

const noteId = computed(() => (route.params.id ? String(route.params.id) : ''))
const isNew = computed(() => !noteId.value)

const note = ref<Note | null>(null)
const tags = ref<Tag[]>([])
const title = ref('')
const content = ref('')
const selectedTagIds = ref<string[]>([])

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const notice = ref('')
/** 已保存过一次后，后续保存改为 PATCH。 */
const saved = ref(false)

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const [tagResult] = await Promise.all([listTags()])
    tags.value = tagResult.items

    if (noteId.value) {
      const loaded = await getNote(noteId.value)
      note.value = loaded
      title.value = loaded.title
      content.value = loaded.content
      selectedTagIds.value = loaded.tags.map((t) => t.id)
      saved.value = true
    }
  } catch (err) {
    error.value = err instanceof ApiError && err.isNotFound ? '笔记不存在' : '笔记加载失败'
  } finally {
    loading.value = false
  }
}

function toggleTag(id: string): void {
  const index = selectedTagIds.value.indexOf(id)
  if (index >= 0) {
    selectedTagIds.value.splice(index, 1)
  } else {
    selectedTagIds.value.push(id)
  }
}

function handleError(err: unknown): void {
  if (err instanceof ApiError) {
    if (err.fields) {
      error.value = Object.values(err.fields).join('；')
    } else if (err.isForbidden) {
      error.value = '当前身份只能阅读，不能编辑笔记'
    } else {
      error.value = err.message
    }
  } else {
    error.value = '保存失败，请稍后重试'
  }
}

async function save(): Promise<void> {
  if (saving.value) return
  saving.value = true
  error.value = ''
  notice.value = ''

  try {
    if (!saved.value) {
      const created = await createNote({
        title: title.value,
        content: content.value,
        tag_ids: selectedTagIds.value,
      })
      note.value = created
      saved.value = true
      // 新建后换成详情地址，刷新不会重复创建
      await router.replace({ name: 'note-detail', params: { id: created.id } })
      notice.value = '已保存'
    } else {
      const updated = await updateNote(noteId.value, {
        title: title.value,
        content: content.value,
        tag_ids: selectedTagIds.value,
      })
      note.value = updated
      notice.value = '已保存'
    }
  } catch (err) {
    handleError(err)
  } finally {
    saving.value = false
  }
}

async function toggleVisibility(): Promise<void> {
  if (!note.value) return
  error.value = ''
  notice.value = ''
  try {
    note.value =
      note.value.visibility === 'public'
        ? await unpublishNote(note.value.id)
        : await publishNote(note.value.id)
    notice.value = note.value.visibility === 'public' ? '已公开，任何人都能看到' : '已撤回为私有'
  } catch (err) {
    handleError(err)
  }
}

async function remove(): Promise<void> {
  if (!note.value) return
  if (!window.confirm('删除后无法恢复，确定删除这篇笔记？')) return

  try {
    await deleteNote(note.value.id)
    await router.push({ name: 'workbench' })
  } catch (err) {
    handleError(err)
  }
}

onMounted(load)
</script>

<template>
  <PrivateHeader />

  <main class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ isNew ? '新建笔记' : '编辑笔记' }}</h1>
        <p v-if="note" class="page-subtitle">
          {{ note.visibility === 'public' ? '已公开' : '私有' }}
          <template v-if="note.published_at"> · 首发于 {{ formatDateTime(note.published_at) }}</template>
          · 更新于 {{ formatDateTime(note.updated_at) }}
        </p>
      </div>

      <div class="row" style="gap: 8px">
        <button v-if="note" class="btn" type="button" @click="toggleVisibility">
          {{ note.visibility === 'public' ? '撤回' : '公开' }}
        </button>
        <button v-if="note" class="btn btn--danger" type="button" @click="remove">删除</button>
        <button class="btn btn--primary" type="button" :disabled="saving || loading" @click="save">
          {{ saving ? '保存中…' : '保存' }}
        </button>
      </div>
    </div>

    <p v-if="error" class="notice notice--error">{{ error }}</p>
    <p v-if="notice" class="notice notice--info" style="margin-top: 8px">{{ notice }}</p>

    <div v-if="loading" class="panel panel--padded">
      <div class="skeleton" style="width: 40%"></div>
      <div class="skeleton" style="width: 90%"></div>
    </div>

    <form v-else class="stack" @submit.prevent="save">
      <div class="field">
        <label class="field__label" for="note-title">标题</label>
        <input id="note-title" v-model="title" class="input" type="text" required />
      </div>

      <div class="field">
        <label class="field__label" for="note-content">正文</label>
        <textarea id="note-content" v-model="content" class="textarea" spellcheck="false" />
      </div>

      <div class="field">
        <span class="field__label">标签</span>
        <div v-if="tags.length === 0" class="field__hint">
          还没有标签，去「标签」页创建后再回来。
        </div>
        <div v-else class="tag-row" style="margin-top: 0">
          <button
            v-for="tag in tags"
            :key="tag.id"
            type="button"
            class="tag"
            :style="
              selectedTagIds.includes(tag.id)
                ? { background: 'var(--accent)', color: '#fff', border: 'none', cursor: 'pointer' }
                : { cursor: 'pointer' }
            "
            @click="toggleTag(tag.id)"
          >
            {{ tag.name }}
          </button>
        </div>
        <span class="field__hint">再次点击取消选择；每次保存都是全量替换。</span>
      </div>
    </form>
  </main>
</template>
