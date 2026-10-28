<script setup lang="ts">
/**
 * 笔记详情 / 编辑 / 新建。
 *
 * 三种模式：
 *   - /notes/:id     已有笔记，默认阅读态，点「编辑」进入所见即所得编辑
 *   - /notes/new?title=&tag_ids=   刚在弹窗里定好标题与标签，正文从这里开始写，
 *                                  首次保存才真正创建笔记
 *
 * 正文以 Markdown 原文存储（docs/backend/data-model.md 的 notes.content）。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import PrivateHeader from '@/components/PrivateHeader.vue'
import MarkdownEditor from '@/components/MarkdownEditor.vue'
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
import { renderMarkdown, decorateLinks } from '@/utils/markdown'
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
const editing = ref(false)

/** 首次保存前的临时草稿：标题与标签来自弹窗，正文在这里写。 */
const draftTitle = ref('')
const editorRef = ref<InstanceType<typeof MarkdownEditor> | null>(null)

const renderedHtml = computed(() => decorateLinks(renderMarkdown(content.value)))

/** 有未保存改动时离开要确认（新建模式尤其重要，否则会丢草稿）。 */
const dirty = ref(false)
function markDirty(): void {
  if (!dirty.value) dirty.value = true
}

watch([title, content, selectedTagIds], markDirty, { deep: true })

onBeforeRouteLeave(() => {
  if (!dirty.value) return true
  return window.confirm('还有未保存的改动，确定离开？')
})

onBeforeUnmount(() => {
  dirty.value = false
})

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    tags.value = (await listTags()).items

    if (isNew.value) {
      // 标题与标签来自新建弹窗（路由 query），正文留空
      draftTitle.value = String(route.query.title ?? '')
      title.value = draftTitle.value
      const rawTagIds = route.query.tag_ids
      selectedTagIds.value = typeof rawTagIds === 'string' && rawTagIds ? rawTagIds.split(',') : []
      content.value = ''
      editing.value = true
      // 初始填充不算改动
      requestAnimationFrame(() => {
        dirty.value = false
      })
      return
    }

    const loaded = await getNote(noteId.value)
    note.value = loaded
    title.value = loaded.title
    content.value = loaded.content
    selectedTagIds.value = loaded.tags.map((t) => t.id)
    editing.value = false
    requestAnimationFrame(() => {
      dirty.value = false
    })
  } catch (err) {
    error.value = err instanceof ApiError && err.isNotFound ? '这篇笔记不存在' : '笔记加载失败'
  } finally {
    loading.value = false
  }
}

function toggleTag(id: string): void {
  const index = selectedTagIds.value.indexOf(id)
  if (index >= 0) selectedTagIds.value.splice(index, 1)
  else selectedTagIds.value.push(id)
}

function handleError(err: unknown): void {
  if (err instanceof ApiError) {
    if (err.fields) error.value = Object.values(err.fields).join('；')
    else if (err.isForbidden) error.value = '当前身份只能阅读，不能编辑笔记'
    else error.value = err.message
  } else {
    error.value = '操作失败，请稍后重试'
  }
}

async function save(): Promise<void> {
  if (saving.value) return

  // 先把编辑器的最新内容同步回 content，避免存到上一拍的值
  if (editing.value) {
    editorRef.value?.sync()
    await nextTick()
  }

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
      dirty.value = false
      editing.value = false // 保存后进入阅读态，避免看起来像没保存
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
      dirty.value = false
      notice.value = '已保存'
      editing.value = false
    }
  } catch (err) {
    handleError(err)
  } finally {
    saving.value = false
  }
}

function cancelEditing(): void {
  if (dirty.value && !window.confirm('放弃未保存的改动？')) return
  if (note.value) {
    title.value = note.value.title
    content.value = note.value.content
    selectedTagIds.value = note.value.tags.map((t) => t.id)
  }
  dirty.value = false
  editing.value = false
}

async function toggleVisibility(): Promise<void> {
  if (!note.value) return
  error.value = ''
  notice.value = ''
  try {
    note.value =
      note.value.visibility === 'public' ? await unpublishNote(note.value.id) : await publishNote(note.value.id)
    notice.value =
      note.value.visibility === 'public' ? '已公开，任何人通过公开链接都能看到' : '已撤回为私有'
  } catch (err) {
    handleError(err)
  }
}

async function remove(): Promise<void> {
  if (!note.value) return
  if (!window.confirm('删除后无法恢复，确定删除这篇笔记？')) return

  try {
    dirty.value = false
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

    <main class="container" :class="editing ? 'container--editor' : 'container--reading'">
      <p v-if="error" class="notice notice--error">{{ error }}</p>
      <p v-if="notice" class="notice notice--success" style="margin-bottom: var(--sp-4)">{{ notice }}</p>

      <div v-if="loading" class="panel panel--pad">
        <div class="skeleton skeleton--title" style="width: 52%"></div>
        <div class="skeleton skeleton--line" style="width: 92%"></div>
        <div class="skeleton skeleton--line" style="width: 76%"></div>
      </div>

      <!-- 编辑态：标题与标签在上，正文撑满，操作在底部 -->
      <section v-else-if="editing" class="editor-layout">
        <div class="editor-layout__head">
          <input
            id="note-title"
            v-model="title"
            class="input editor-title"
            type="text"
            placeholder="标题"
            aria-label="标题"
          />

          <div class="row row--wrap tag-field" style="gap: var(--sp-2)">
            <span class="field__label" style="margin: 0">标签</span>
            <p v-if="tags.length === 0" class="field__hint" style="margin: 0">
              还没有标签，去「标签」页创建后再回来。
            </p>
            <div v-else class="tag-row" style="margin: 0">
              <button
                v-for="tag in tags"
                :key="tag.id"
                class="tag"
                type="button"
                :aria-pressed="selectedTagIds.includes(tag.id)"
                @click="toggleTag(tag.id)"
              >
                {{ tag.name }}
              </button>
            </div>
          </div>
        </div>

        <div class="editor-layout__body">
          <MarkdownEditor ref="editorRef" v-model="content" :autofocus="isNew" />
        </div>

        <div class="editor-layout__foot">
          <span class="field__hint">
            Markdown：**粗体**、`代码`、- 列表、&gt; 引用、``` 代码块
          </span>
          <div class="spacer"></div>
          <button
            class="btn"
            type="button"
            @click="isNew ? router.push({ name: 'workbench' }) : cancelEditing()"
          >
            取消
          </button>
          <button class="btn btn--primary" type="button" :disabled="saving" @click="save">
            {{ saving ? '保存中…' : '保存' }}
          </button>
        </div>
      </section>

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
            <button class="btn btn--primary btn--sm" type="button" @click="editing = true">编辑</button>
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

        <!-- eslint-disable-next-line vue/no-v-html -- 已经过 DOMPurify 过滤 -->
        <div v-if="note.content" class="md-body" v-html="renderedHtml"></div>
        <p v-else class="field__hint">这篇笔记还没有正文。</p>
      </article>

      <div v-else class="panel empty">
        <p class="empty__title">这篇笔记不存在</p>
        <p class="empty__text">它可能已经被删除了。</p>
        <button class="btn" type="button" @click="router.push({ name: 'workbench' })">返回笔记列表</button>
      </div>
    </main>
  </div>
</template>
