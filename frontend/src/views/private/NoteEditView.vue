<script setup lang="ts">
/**
 * 笔记编辑（默认即可写，无「编辑 / 保存」按钮）。
 *
 * 按照 docs/frontend/ui-design.md 7.5：
 * - Milkdown 无边框、无阴影，标题与正文处在同一个纯白容器里；
 * - 正文变化由 `markdownUpdated` 回传后防抖 1000ms 自动保存；
 * - 保存状态以轻量文字显示在标题栏右侧；
 * - 添加标签、公开 / 私有、删除放在标题栏最右侧。
 *
 * 新建笔记（/notes/new）首次自动保存时才真正 POST /api/notes，
 * 随后换成 /notes/:id，刷新不会重复创建。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import MarkdownEditor from '@/components/MarkdownEditor.vue'
import TagDropdown from '@/components/TagDropdown.vue'
import { ApiError } from '@/api/client'
import {
  createNote,
  getNote,
  updateNote,
  type Note,
} from '@/api/notes'
import { listTags, type Tag } from '@/api/tags'
import { listFolders, type Folder } from '@/api/folders'
import { useUiStore } from '@/stores/ui'
import { countWords, formatReadingTime } from '@/utils/text-stats'

/** 自动保存防抖时间（ui-design.md 7.5.4）。 */
const AUTOSAVE_DELAY = 1000

const route = useRoute()
const router = useRouter()
const ui = useUiStore()

const noteId = computed(() => (route.params.id ? String(route.params.id) : ''))
const isNew = computed(() => !noteId.value)

const note = ref<Note | null>(null)
const tags = ref<Tag[]>([])
const folders = ref<Folder[]>([])
const title = ref('')
const content = ref('')
const folderId = ref<string | null>(null)
const selectedTagIds = ref<string[]>([])

const loading = ref(true)
const saving = ref(false)
const error = ref('')
/** 载入 / 回填期间不触发自动保存。 */
const hydrating = ref(true)
const saveState = ref<'idle' | 'dirty' | 'saving' | 'saved' | 'error'>('idle')

const editorRef = ref<InstanceType<typeof MarkdownEditor> | null>(null)

const editingMode = computed(() => Boolean(note.value || isNew.value))

/** 正文字数与阅读时长，显示在保存状态旁边。 */
const wordCount = computed(() => countWords(content.value))

/** 最近一次成功保存时的内容快照，用来判断是否真的需要再存一次。 */
const lastSaved = ref('')
/** 上次保存时的标签集合；只有标签变化或新建笔记时才重新拉标签计数。 */
let lastSavedTags = ''

let saveTimer: ReturnType<typeof setTimeout> | undefined
let savePending = false
/** 正处在离开守卫里：此时新建笔记后不再 replace 路由，避免打断原导航。 */
let leaving = false

const statusText = computed(() => {
  switch (saveState.value) {
    case 'dirty':
      return '未保存'
    case 'saving':
      return '正在保存…'
    case 'saved':
      return '已保存'
    case 'error':
      return '保存失败'
    default:
      return ''
  }
})

function snapshot(): string {
  return JSON.stringify({
    title: title.value,
    content: content.value,
    tags: selectedTagIds.value,
    folder: folderId.value,
  })
}

/** 标题、正文、标签任一变化都走同一个防抖保存。 */
watch(
  [title, content, selectedTagIds, folderId],
  () => {
    if (hydrating.value) return
    if (snapshot() === lastSaved.value) return
    scheduleSave()
  },
  { deep: true },
)

function scheduleSave(): void {
  saveState.value = 'dirty'
  if (saveTimer) clearTimeout(saveTimer)
  saveTimer = setTimeout(() => void save(), AUTOSAVE_DELAY)
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

/** 保存；`syncEditor` 用于离开页面 / 发布前把编辑器最新内容补进来。 */
async function save(syncEditor = false): Promise<boolean> {
  if (saveTimer) {
    clearTimeout(saveTimer)
    saveTimer = undefined
  }
  if (hydrating.value) return true

  if (syncEditor && editorRef.value) {
    editorRef.value.sync()
    await nextTick()
  }

  if (snapshot() === lastSaved.value) {
    if (saveState.value !== 'saved' && saveState.value !== 'idle') saveState.value = 'saved'
    return true
  }
  if (saving.value) {
    savePending = true
    return true
  }

  saving.value = true
  saveState.value = 'saving'
  error.value = ''

  const pending = snapshot()
  const tagKey = JSON.stringify(selectedTagIds.value)
  try {
    if (isNew.value) {
      const created = await createNote({
        title: title.value,
        content: content.value,
        tag_ids: selectedTagIds.value,
        folder_id: folderId.value,
      })
      note.value = created
      lastSaved.value = pending
      saveState.value = 'saved'
      ui.notesChanged()
      // 换成详情地址；路由监听会重新载入，hydrating 防止回填触发再次保存
      if (!leaving) {
        await router.replace({ name: 'note-detail', params: { id: created.id } })
      }
      lastSavedTags = tagKey
      await reloadTags()
      return true
    }

    const updated = await updateNote(noteId.value, {
      title: title.value,
      content: content.value,
      tag_ids: selectedTagIds.value,
      folder_id: folderId.value,
    })
    note.value = updated
    lastSaved.value = pending
    saveState.value = 'saved'
    ui.notesChanged()
    // 标签计数变了：不再被使用的标签会自动从列表消失
    if (tagKey !== lastSavedTags) {
      lastSavedTags = tagKey
      await reloadTags()
    }
    return true
  } catch (err) {
    if (err instanceof ApiError && err.isNotFound) {
      // 笔记已在目录树里被删除：放弃本次保存，并允许离开
      lastSaved.value = snapshot()
      saveState.value = 'idle'
      return true
    }
    handleError(err)
    saveState.value = 'error'
    return false
  } finally {
    saving.value = false
    if (savePending) {
      savePending = false
      if (snapshot() !== lastSaved.value) scheduleSave()
    }
  }
}

async function load(): Promise<void> {
  hydrating.value = true
  loading.value = true
  error.value = ''
  // 切换笔记时先清空，避免 404 或加载失败时还显示上一篇的正文
  note.value = null
  content.value = ''
  try {
    const [tagResult, folderResult] = await Promise.allSettled([listTags(), listFolders()])
    if (tagResult.status === 'fulfilled') tags.value = tagResult.value.items
    if (folderResult.status === 'fulfilled') folders.value = folderResult.value.items

    if (isNew.value) {
      // 标题与标签来自新建弹窗（路由 query），正文留空
      title.value = String(route.query.title ?? '')
      const rawTagIds = route.query.tag_ids
      selectedTagIds.value = typeof rawTagIds === 'string' && rawTagIds ? rawTagIds.split(',') : []
      const rawFolderId = route.query.folder_id
      folderId.value =
        typeof rawFolderId === 'string' && rawFolderId ? rawFolderId : defaultInboxId()
      content.value = ''
      note.value = null
    } else {
      const loaded = await getNote(noteId.value)
      note.value = loaded
      title.value = loaded.title
      content.value = loaded.content
      selectedTagIds.value = loaded.tags.map((t) => t.id)
      folderId.value = loaded.folder_id ?? defaultInboxId()
    }
  } catch (err) {
    error.value = err instanceof ApiError && err.isNotFound ? '这篇笔记不存在' : '笔记加载失败'
  } finally {
    loading.value = false
    // 新建时 URL 上的 folder_id 可能无效（手改地址），回退到收件箱
    if (folderId.value && !folders.value.some((folder) => folder.id === folderId.value)) {
      folderId.value = defaultInboxId()
    }
    // 等编辑器把初始内容同步完，再把当前状态记为「已保存」
    requestAnimationFrame(() => {
      lastSaved.value = snapshot()
      lastSavedTags = JSON.stringify(selectedTagIds.value)
      saveState.value = isNew.value ? 'idle' : 'saved'
      hydrating.value = false
    })
  }
}

/** 标签被新建或删除后重新拉取（删除会影响其它笔记，需要最新列表）。 */
async function reloadTags(): Promise<void> {
  try {
    tags.value = (await listTags()).items
  } catch {
    // 拉取失败不阻塞编辑
  }
}

/** 当前用户的收件箱 id；没有收件箱时返回 null（历史数据兜底）。 */
function defaultInboxId(): string | null {
  return folders.value.find((folder) => folder.is_inbox)?.id ?? null
}

/** 文件夹被增删改后重新拉取；当前文件夹若被删除则回到收件箱。 */
async function reloadFolders(): Promise<void> {
  try {
    folders.value = (await listFolders()).items
    if (folderId.value && !folders.value.some((folder) => folder.id === folderId.value)) {
      folderId.value = defaultInboxId()
    }
  } catch {
    // 拉取失败不阻塞编辑
  }
}

/** 用「父 / 子」形式显示文件夹，避免不同目录下的同名项混淆。 */
function folderPath(folder: Folder): string {
  const names = [folder.name]
  const seen = new Set([folder.id])
  let parent = folder.parent_id
  while (parent && !seen.has(parent)) {
    seen.add(parent)
    const parentFolder = folders.value.find((item) => item.id === parent)
    if (!parentFolder) break
    names.unshift(parentFolder.name)
    parent = parentFolder.parent_id
  }
  return names.join(' / ')
}

const folderOptions = computed(() =>
  folders.value
    .map((folder) => ({ id: folder.id, label: folderPath(folder) }))
    .sort((a, b) => a.label.localeCompare(b.label, 'zh-CN')),
)

function onFolderChange(event: Event): void {
  folderId.value = (event.target as HTMLSelectElement).value || null
}

watch(
  () => ui.foldersVersion,
  () => void reloadFolders(),
)

// 目录树里拖动当前笔记后，同步 folder_id；只改 lastSaved 里的 folder，
// 避免把尚未保存的标题 / 正文误判为已保存。
watch(
  () => ui.lastNoteMove,
  (move) => {
    if (!move || move.id !== noteId.value) return
    if (lastSaved.value) {
      try {
        const saved = JSON.parse(lastSaved.value) as Record<string, unknown>
        saved.folder = move.folderId
        lastSaved.value = JSON.stringify(saved)
      } catch {
        // 快照格式异常时忽略，下一次保存会以当前 folder_id 为准
      }
    }
    if (note.value) note.value = { ...note.value, folder_id: move.folderId }
    folderId.value = move.folderId
  },
)

// 三栏布局里本组件不会随笔记切换重建；新建页再次从树里点「新建」时
// 参数也是 query 变化而不是 id 变化，所以这些来源都要监听
watch(
  () => [route.params.id, route.query.title, route.query.folder_id, route.query.tag_ids],
  () => void load(),
  { immediate: true },
)

onBeforeRouteLeave(async () => {
  if (hydrating.value) return true
  if (snapshot() === lastSaved.value) return true
  leaving = true
  const ok = await save(true)
  leaving = false
  if (ok) return true
  if (window.confirm('保存失败，仍要离开？')) return true
  if (snapshot() !== lastSaved.value) scheduleSave()
  return false
})

onMounted(() => {
  ui.registerNoteFlush(() => save(true))
})

onBeforeUnmount(() => {
  if (saveTimer) clearTimeout(saveTimer)
  ui.registerNoteFlush(null)
})
</script>

<template>
  <div class="note-shell" :class="{ 'note-shell--editing': editingMode }">
    <div class="note-view" :class="{ 'note-view--editing': editingMode }">
      <div v-if="error" class="note-flash">
        <p class="notice notice--error">{{ error }}</p>
      </div>

      <div v-if="loading" class="detail-inner">
        <div class="skeleton skeleton--title" style="width: 52%"></div>
        <div class="skeleton skeleton--line" style="width: 92%; margin-top: 16px"></div>
        <div class="skeleton skeleton--line" style="width: 76%"></div>
      </div>

      <template v-else>
        <!-- 编辑态（默认）：标题与正文在同一个无边框容器里 -->
        <section v-if="note || isNew" class="editor-page">
          <header class="editor-header">
            <input
              id="note-title"
              v-model="title"
              class="editor-title"
              type="text"
              placeholder="标题"
              aria-label="标题"
            />

            <div class="editor-actions">
              <span v-if="statusText" class="save-state" :class="`save-state--${saveState}`">{{ statusText }}</span>

              <span class="word-count" :title="`约 ${formatReadingTime(wordCount)}`">
                {{ wordCount }} 字
              </span>

              <select class="select folder-select" :value="folderId ?? ''" aria-label="所属文件夹" @change="onFolderChange">
                <option v-if="!folders.some((folder) => folder.is_inbox)" value="">收件箱</option>
                <option v-for="option in folderOptions" :key="option.id" :value="option.id">{{ option.label }}</option>
              </select>

              <TagDropdown v-model:selected="selectedTagIds" :tags="tags" @changed="reloadTags" />
            </div>
          </header>

          <div class="editor-body">
            <MarkdownEditor ref="editorRef" v-model="content" :autofocus="isNew" />
          </div>
        </section>

        <div v-else class="detail-inner">
          <div class="detail-empty">
            <p class="detail-empty__title">这篇笔记不存在</p>
            <p class="detail-empty__text">它可能已经被删除了。</p>
            <button class="btn btn--primary" type="button" @click="router.push({ name: 'workbench' })">
              返回笔记列表
            </button>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
