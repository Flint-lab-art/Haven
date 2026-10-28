<script setup lang="ts">
/**
 * 笔记详情 / 编辑（docs/frontend/frontend.md 第四节 /notes/:id 与 /notes/new）。
 *
 * 默认是阅读模式（正文优先）；点「编辑」进入编辑状态，
 * 顶栏保留公开/撤回与删除等次要操作。
 */
import { computed, nextTick, onMounted, ref } from 'vue'
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
import { formatDateTime, formatRelative } from '@/utils/format'

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
/** 新建时一进来就是编辑态；已有笔记默认阅读态。 */
const editing = ref(isNew.value)

const titleInput = ref<HTMLInputElement | null>(null)

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    tags.value = (await listTags()).items
    if (noteId.value) {
      const loaded = await getNote(noteId.value)
      note.value = loaded
      title.value = loaded.title
      content.value = loaded.content
      selectedTagIds.value = loaded.tags.map((t) => t.id)
    }
  } catch (err) {
    error.value = err instanceof ApiError && err.isNotFound ? '这篇笔记不存在' : '笔记加载失败'
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
    error.value = '操作失败，请稍后重试'
  }
}

async function startEditing(): Promise<void> {
  editing.value = true
  await nextTick()
  titleInput.value?.focus()
}

async function save(): Promise<void> {
  if (saving.value) return
  saving.value = true
  error.value = ''
  notice.value = ''

  try {
    if (isNew.value) {
      const created = await createNote({
        title: title.value,
        content: content.value,
        tag_ids: selectedTagIds.value,
      })
      note.value = created
      // 换成详情地址，刷新不会重复创建
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
    editing.value = false
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
    notice.value = note.value.visibility === 'public' ? '已公开，任何人通过公开链接都能看到' : '已撤回为私有'
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
  <div class="shell">
    <PrivateHeader />

    <main class="container container--reading">
      <p v-if="error" class="notice notice--error">{{ error }}</p>
      <p v-if="notice" class="notice notice--success" style="margin-bottom: var(--sp-4)">{{ notice }}</p>

      <div v-if="loading" class="panel panel--pad">
        <div class="skeleton skeleton--title" style="width: 52%"></div>
        <div class="skeleton skeleton--line" style="width: 92%"></div>
        <div class="skeleton skeleton--line" style="width: 76%"></div>
      </div>

      <!-- 编辑态 -->
      <form v-else-if="editing" class="panel panel--pad" @submit.prevent="save">
        <div class="row" style="justify-content: space-between; margin-bottom: var(--sp-5)">
          <span class="field__label">{{ isNew ? '新建笔记' : '编辑笔记' }}</span>
          <div class="row">
            <button
              v-if="!isNew"
              class="btn btn--sm"
              type="button"
              @click="editing = false"
            >
              取消
            </button>
            <button class="btn btn--primary" type="submit" :disabled="saving">
              {{ saving ? '保存中…' : '保存' }}
            </button>
          </div>
        </div>

        <div class="field" style="margin-bottom: var(--sp-4)">
          <label class="field__label" for="note-title">标题</label>
          <input
            id="note-title"
            ref="titleInput"
            v-model="title"
            class="input"
            type="text"
            placeholder="给这篇笔记起个名字"
            required
          />
        </div>

        <div class="field" style="margin-bottom: var(--sp-4)">
          <label class="field__label" for="note-content">正文</label>
          <textarea
            id="note-content"
            v-model="content"
            class="textarea"
            placeholder="随便写点什么…"
            spellcheck="false"
          />
        </div>

        <div class="field">
          <span class="field__label">标签</span>
          <p v-if="tags.length === 0" class="field__hint">
            还没有标签，去「标签」页创建后再回来。
          </p>
          <div v-else class="tag-row">
            <button
              v-for="tag in tags"
              :key="tag.id"
              type="button"
              class="tag"
              :aria-pressed="selectedTagIds.includes(tag.id)"
              @click="toggleTag(tag.id)"
            >
              {{ tag.name }}
            </button>
          </div>
          <span class="field__hint">点选切换；保存时按当前选择全量替换。</span>
        </div>
      </form>

      <!-- 阅读态 -->
      <article v-else-if="note" class="panel panel--pad">
        <div class="row row--wrap" style="justify-content: space-between; margin-bottom: var(--sp-5)">
          <span class="row" style="gap: var(--sp-2)">
            <span class="badge" :class="note.visibility === 'public' ? 'badge--public' : 'badge--private'">
              {{ note.visibility === 'public' ? '已公开' : '私有' }}
            </span>
            <span class="field__hint">
              更新于 {{ formatRelative(note.updated_at) }}
              <template v-if="note.published_at"> · 首发 {{ formatDateTime(note.published_at) }}</template>
            </span>
          </span>

          <div class="row">
            <button class="btn btn--sm btn--quiet" type="button" @click="toggleVisibility">
              {{ note.visibility === 'public' ? '撤回' : '公开' }}
            </button>
            <button class="btn btn--sm btn--danger" type="button" @click="remove">删除</button>
            <button class="btn btn--primary btn--sm" type="button" @click="startEditing">编辑</button>
          </div>
        </div>

        <header class="article">
          <h1 class="article__title">{{ note.title }}</h1>
          <div v-if="note.tags.length" class="article__meta">
            <div class="tag-row">
              <span v-for="tag in note.tags" :key="tag.id" class="tag">{{ tag.name }}</span>
            </div>
          </div>
        </header>

        <div class="article__body">{{ note.content }}</div>
      </article>

      <div v-else class="panel empty">
        <p class="empty__title">这篇笔记不存在</p>
        <p class="empty__text">它可能已经被删除了。</p>
        <RouterLink to="/" class="btn">返回笔记列表</RouterLink>
      </div>
    </main>
  </div>
</template>
