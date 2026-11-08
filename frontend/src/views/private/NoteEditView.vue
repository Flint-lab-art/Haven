<script setup lang="ts">
/**
 * 笔记编辑（默认即可写，无「编辑 / 保存」按钮）。
 *
 * 按照 docs/frontend/ui-design.md 7.5：
 * - TipTap 无边框、无阴影，标题与正文处在同一个纯白容器里；
 * - 正文变化由 `markdownUpdated` 回传后防抖 1000ms 自动保存；
 * - 标题独占一行，文件夹 / 标签 / 历史版本 / 保存状态排在标题下方的第二行；
 * - 保存状态以轻量文字显示在第二行最右侧；
 * - 第二行最右侧的关闭按钮会先保存一次，再回到工作台空态。
 *
 * 新建笔记（/notes/new）是空白编辑页：标题与正文都为空，直接开写。
 * 首次自动保存时才真正 POST /api/notes，
 * 随后换成 /notes/:id，刷新不会重复创建。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import RichTextEditor from '@/components/RichTextEditor.vue'
import TagDropdown from '@/components/TagDropdown.vue'
import VersionHistoryDialog from '@/components/VersionHistoryDialog.vue'
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
import { stripHtml } from '@/utils/html'

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

const editorRef = ref<InstanceType<typeof RichTextEditor> | null>(null)

/** 历史版本浮层（docs/v2/frontend/frontend.md 第五节）。 */
const historyOpen = ref(false)

function openHistory(): void {
  // 先把编辑器当前内容交回来，DIFF 的新侧才是用户眼前的正文
  editorRef.value?.sync()
  historyOpen.value = true
}

/** 还原成功后重新拉取笔记内容并重置保存基线。 */
async function onVersionRestored(): Promise<void> {
  if (!noteId.value) return
  await load()
  ui.notesChanged()
}

const editingMode = computed(() => Boolean(note.value || isNew.value))

/** 正文字数与阅读时长，显示在保存状态旁边。 */
const wordCount = computed(() => countWords(stripHtml(content.value)))

/** 只有图片 / 视频 / 音频 / 分割线这类没有文字的元素，也算有内容。 */
const MEDIA_ONLY_PATTERN = /<(img|video|audio|iframe|hr)\b/i

/**
 * 空白的新建笔记：标题、正文、标签都没填。
 * 关闭或离开时直接丢弃，不为它创建一条空记录。
 */
const isBlankNewNote = computed(
  () =>
    isNew.value &&
    !title.value.trim() &&
    selectedTagIds.value.length === 0 &&
    !stripHtml(content.value) &&
    !MEDIA_ONLY_PATTERN.test(content.value),
)

/** 最近一次成功保存时的内容快照，用来判断是否真的需要再存一次。 */
const lastSaved = ref('')
/** 上次保存时的标签集合；只有标签变化或新建笔记时才重新拉标签计数。 */
let lastSavedTags = ''

let saveTimer: ReturnType<typeof setTimeout> | undefined
let savePending = false
/** 正处在离开守卫里：此时新建笔记后不再 replace 路由，避免打断原导航。 */
let leaving = false
/** 用户已确认「保存失败也要关闭」：离开守卫不再重复保存与询问一次。 */
let leavingAnyway = false

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

  // 空白新笔记不创建空记录：把基线对齐，状态回到闲置
  if (isBlankNewNote.value) {
    lastSaved.value = snapshot()
    if (saveState.value !== 'idle') saveState.value = 'idle'
    return true
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
      // 空白编辑页：正文与标签从空开始；
      // 标题可由命令面板通过 query.title 带入，folder_id 来自目录树或文件夹选择器
      const rawTitle = route.query.title
      title.value = typeof rawTitle === 'string' ? rawTitle : ''
      selectedTagIds.value = []
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

/** 标签列表请求序号：并发请求时只接受最后一次发出的结果，避免旧响应覆盖新状态。 */
let tagRequestSeq = 0

/** 标签被新建或删除后重新拉取（删除会影响其它笔记，需要最新列表）。 */
async function reloadTags(): Promise<void> {
  const seq = ++tagRequestSeq
  try {
    const items = (await listTags()).items
    if (seq === tagRequestSeq) tags.value = items
  } catch {
    // 拉取失败不阻塞编辑
  }
}

/**
 * 编辑页新建标签（TagDropdown 的 created 事件）。
 *
 * 标签只在本篇关联后才有意义：GET /api/tags 会删掉 0 引用的标签，
 * 所以先把它并入本地列表（避免立刻重拉时被清掉），再落到当前笔记上。
 * 已保存过的笔记立刻 PATCH tag_ids；空白笔记等首次保存时随 createNote 一起提交。
 */
async function onTagCreated(tag: Tag): Promise<void> {
  if (!tags.value.some((item) => item.id === tag.id)) {
    tags.value = [...tags.value, tag]
  }
  if (isNew.value || hydrating.value) {
    // 新笔记：selectedTagIds 已由子组件更新，首次保存会带上；
    // 同步基线，避免「刚建标签」被当成未保存的改动
    lastSavedTags = JSON.stringify(selectedTagIds.value)
    if (lastSaved.value) {
      try {
        const saved = JSON.parse(lastSaved.value) as Record<string, unknown>
        saved.tags = selectedTagIds.value
        lastSaved.value = JSON.stringify(saved)
      } catch {
        // 快照格式异常时忽略，下一次保存会以当前标签为准
      }
    }
    return
  }

  const pending = snapshot()
  const tagKey = JSON.stringify(selectedTagIds.value)
  const newTagId = tag.id
  const revertTag = (): void => {
    // 关联失败：把刚建的标签从本篇撤掉，它仍是 0 引用，重拉时也会被后端清掉
    selectedTagIds.value = selectedTagIds.value.filter((id) => id !== newTagId)
    tags.value = tags.value.filter((item) => item.id !== newTagId)
    lastSaved.value = snapshot()
  }

  saving.value = true
  saveState.value = 'saving'
  error.value = ''
  try {
    const updated = await updateNote(noteId.value, { tag_ids: selectedTagIds.value })
    note.value = updated
    lastSaved.value = pending
    lastSavedTags = tagKey
    saveState.value = 'saved'
    ui.notesChanged()
    await reloadTags()
  } catch (err) {
    if (err instanceof ApiError && err.isNotFound) {
      lastSaved.value = snapshot()
      saveState.value = 'idle'
      return
    }
    revertTag()
    handleError(err)
    saveState.value = 'error'
    await reloadTags()
  } finally {
    saving.value = false
    if (savePending) {
      savePending = false
      if (snapshot() !== lastSaved.value) scheduleSave()
    }
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
  () => [route.params.id, route.query.folder_id],
  () => void load(),
  { immediate: true },
)

/** 等正在进行的那次保存落地，避免「关闭」跑在请求前面。 */
function whenSaveIdle(): Promise<void> {
  if (!saving.value) return Promise.resolve()
  return new Promise<void>((resolve) => {
    const stop = watch(saving, (value) => {
      if (!value) {
        stop()
        resolve()
      }
    })
  })
}

/** 关闭当前笔记：先保存一次，成功（或用户确认放弃）后回到工作台空态。 */
async function closeNote(): Promise<void> {
  if (saveTimer) {
    clearTimeout(saveTimer)
    saveTimer = undefined
  }
  await whenSaveIdle()
  // 空白的新建笔记直接关掉，不创建记录
  if (isNew.value) {
    editorRef.value?.sync()
    await nextTick()
    if (isBlankNewNote.value) {
      await router.push({ name: 'workbench' })
      return
    }
  }
  // 新建笔记关闭时不要再 replace 到 /notes/:id，直接回工作台
  leaving = true
  try {
    const ok = await save(true)
    if (!ok && !window.confirm('保存失败，仍要关闭？')) return
    if (!ok) leavingAnyway = true
    await router.push({ name: 'workbench' })
  } finally {
    leaving = false
  }
}

onBeforeRouteLeave(async () => {
  if (hydrating.value) return true
  if (leavingAnyway) return true
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
        <!-- 编辑态（默认）：标题独占一行，文件夹 / 标签 / 状态排在下一行 -->
        <section v-if="note || isNew" class="editor-page">
          <header class="editor-header">
            <input
              id="note-title"
              v-model="title"
              class="editor-title"
              type="text"
              placeholder="标题"
              aria-label="标题"
              autocomplete="off"
              autocorrect="off"
              autocapitalize="off"
              spellcheck="false"
            />

            <div class="editor-meta">
              <select class="select folder-select" :value="folderId ?? ''" aria-label="所属文件夹" @change="onFolderChange">
                <option v-if="!folders.some((folder) => folder.is_inbox)" value="">收件箱</option>
                <option v-for="option in folderOptions" :key="option.id" :value="option.id">{{ option.label }}</option>
              </select>

              <TagDropdown
                v-model:selected="selectedTagIds"
                :tags="tags"
                @created="onTagCreated"
              />

              <div class="editor-meta__status">
                <button
                  v-if="!isNew"
                  class="icon-btn"
                  type="button"
                  title="历史版本"
                  aria-label="历史版本"
                  @click="openHistory"
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <path d="M3 12a9 9 0 1 0 3-6.7" />
                    <path d="M3 4v5h5" />
                    <path d="M12 8v4l3 2" />
                  </svg>
                </button>

                <span class="word-count" :title="`约 ${formatReadingTime(wordCount)}`">
                  {{ wordCount }} 字
                </span>

                <span v-if="statusText" class="save-state" :class="`save-state--${saveState}`">{{ statusText }}</span>

                <button
                  class="icon-btn editor-close"
                  type="button"
                  title="关闭笔记"
                  aria-label="关闭笔记"
                  @click="closeNote"
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <path d="M6 6l12 12" />
                    <path d="M18 6 6 18" />
                  </svg>
                </button>
              </div>
            </div>
          </header>

          <div class="editor-body">
            <RichTextEditor ref="editorRef" v-model="content" :autofocus="isNew" />
          </div>

          <VersionHistoryDialog
            :open="historyOpen"
            :note-id="noteId"
            :current-content="content"
            :current-title="title"
            @close="historyOpen = false"
            @restored="onVersionRestored"
          />
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
