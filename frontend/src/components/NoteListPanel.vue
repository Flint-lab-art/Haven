<script setup lang="ts">
/**
 * 中间列表栏：文件夹树 + 笔记（docs/frontend/ui-design.md 第九节）。
 *
 * - 顶部固定「未分类」节点，展示 folder_id 为 null 的笔记；
 * - 文件夹可无限嵌套，箭头折叠 / 展开，点击名称高亮并展开直属笔记；
 * - 右键或 ... 菜单：新建子文件夹、重命名、删除；
 * - 本期不做拖拽，笔记通过编辑页的文件夹下拉框移动。
 *
 * 数据一次拉全：folder 接口返回平铺数组，笔记按 folder_id 分组；
 * 笔记分页在内部循环取完（个人使用量级足够）。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ConfirmDialog from './ConfirmDialog.vue'
import NewNoteModal from './NewNoteModal.vue'
import { ApiError } from '@/api/client'
import {
  createFolder,
  deleteFolder,
  listFolders,
  updateFolder,
  type Folder,
} from '@/api/folders'
import { deleteNote, listNotes, publishNote, unpublishNote, type NoteSummary } from '@/api/notes'
import { useUiStore } from '@/stores/ui'

/** 分页上限 100，内部循环取完所有笔记。 */
const PAGE_SIZE = 100
const UNCLASSIFIED = '__unclassified__'

type Row =
  | { kind: 'folder'; folder: Folder; depth: number }
  | { kind: 'note'; note: NoteSummary; depth: number }

const route = useRoute()
const router = useRouter()
const ui = useUiStore()

const folders = ref<Folder[]>([])
const notes = ref<NoteSummary[]>([])
const loading = ref(true)
const error = ref('')
const busy = ref(false)

const expanded = ref<Set<string>>(new Set())
const looseExpanded = ref(true)
/** 当前选中的节点：文件夹 id / UNCLASSIFIED / null（未选中）。 */
const selectedFolder = ref<string | null>(UNCLASSIFIED)

const menuFolderId = ref<string | null>(null)
/** undefined = 未在创建；null = 建在根目录；字符串 = 建在该文件夹下。 */
const creatingUnder = ref<string | null | undefined>(undefined)
const createDraft = ref('')
const renamingId = ref<string | null>(null)
const renameDraft = ref('')

const showNew = ref(false)
const modal = ref<InstanceType<typeof NewNoteModal> | null>(null)

/** 待确认的删除目标。 */
const pendingDelete = ref<{
  kind: 'note' | 'folder'
  id: string
  name: string
  message: string
} | null>(null)
const deleting = ref(false)
const busyNoteId = ref<string | null>(null)

let refreshTimer: ReturnType<typeof setTimeout> | undefined

const currentNoteId = computed(() => String(route.params.id ?? ''))

/** parent_id -> 子文件夹（按 sort_order、name 排序）。 */
const childrenMap = computed(() => {
  const map = new Map<string | null, Folder[]>()
  for (const folder of folders.value) {
    const key = folder.parent_id ?? null
    const list = map.get(key) ?? []
    list.push(folder)
    map.set(key, list)
  }
  for (const list of map.values()) {
    list.sort((a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name, 'zh-CN'))
  }
  return map
})

/** folder_id -> 笔记（保持接口返回的 updated_at DESC 顺序）。 */
const notesMap = computed(() => {
  const map = new Map<string | null, NoteSummary[]>()
  for (const note of notes.value) {
    const key = note.folder_id ?? null
    const list = map.get(key) ?? []
    list.push(note)
    map.set(key, list)
  }
  return map
})

const looseNotes = computed(() => notesMap.value.get(null) ?? [])

/** 把树按当前展开状态拍平成行，便于渲染与键盘导航。 */
const rows = computed(() => {
  const out: Row[] = []
  const visited = new Set<string>()

  const walk = (parent: string | null, depth: number): void => {
    for (const folder of childrenMap.value.get(parent) ?? []) {
      if (visited.has(folder.id)) continue
      visited.add(folder.id)

      out.push({ kind: 'folder', folder, depth })
      if (!expanded.value.has(folder.id)) continue

      // 直属笔记先出现在文件夹下方，再展开子文件夹，
      // 这样在某个目录里新建的笔记会紧跟在该目录后面。
      for (const note of notesMap.value.get(folder.id) ?? []) {
        out.push({ kind: 'note', note, depth: depth + 1 })
      }
      walk(folder.id, depth + 1)
    }
  }

  walk(null, 0)
  return out
})

/** 当前可见的笔记顺序，供上下方向键切换。 */
const visibleNotes = computed(() => {
  const out: NoteSummary[] = []
  if (looseExpanded.value) out.push(...looseNotes.value)
  for (const row of rows.value) {
    if (row.kind === 'note') out.push(row.note)
  }
  return out
})

/** 当前选中的真实文件夹；选中「未分类」或未选中时为 null（根目录 / 未分类）。 */
const targetFolderId = computed(() =>
  selectedFolder.value && selectedFolder.value !== UNCLASSIFIED ? selectedFolder.value : null,
)

/** 顶部左侧显示当前视图名称（ui-design.md 9.1）。 */
const panelTitle = computed(() => {
  if (selectedFolder.value === UNCLASSIFIED) return '未分类'
  if (selectedFolder.value) {
    return folders.value.find((folder) => folder.id === selectedFolder.value)?.name ?? '笔记'
  }
  return '笔记'
})

async function fetchAllNotes(): Promise<NoteSummary[]> {
  const all: NoteSummary[] = []
  let offset = 0
  for (;;) {
    const page = await listNotes({ limit: PAGE_SIZE, offset })
    all.push(...page.items)
    offset += page.items.length
    if (page.items.length === 0 || offset >= page.total) break
  }
  return all
}

async function refresh(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const [folderResult, allNotes] = await Promise.all([listFolders(), fetchAllNotes()])
    folders.value = folderResult.items
    notes.value = allNotes

    // 清理已经被删除的选中项 / 展开项
    if (
      selectedFolder.value &&
      selectedFolder.value !== UNCLASSIFIED &&
      !folderResult.items.some((folder) => folder.id === selectedFolder.value)
    ) {
      selectedFolder.value = UNCLASSIFIED
    }
    const ids = new Set(folderResult.items.map((folder) => folder.id))
    expanded.value = new Set([...expanded.value].filter((id) => ids.has(id)))
  } catch {
    error.value = '笔记加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

function actionError(err: unknown, fallback: string): string {
  if (err instanceof ApiError) {
    if (err.status === 409) return '同一目录下已有同名文件夹'
    if (err.fields) return Object.values(err.fields).join('；')
    return err.message
  }
  return fallback
}

async function openModal(): Promise<void> {
  showNew.value = true
  await nextTick()
  void modal.value?.focusTitle()
}

function toggleFolder(id: string): void {
  const next = new Set(expanded.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  expanded.value = next
}

function expand(id: string): void {
  if (expanded.value.has(id)) return
  const next = new Set(expanded.value)
  next.add(id)
  expanded.value = next
}

function selectFolder(folder: Folder): void {
  selectedFolder.value = folder.id
  expand(folder.id)
  menuFolderId.value = null
}

function selectUnclassified(): void {
  selectedFolder.value = UNCLASSIFIED
  looseExpanded.value = true
  menuFolderId.value = null
}

/** 文件夹行右侧的「新建笔记」：先选中该文件夹，再打开弹窗。 */
function createNoteIn(folder: Folder): void {
  selectFolder(folder)
  void openModal()
}

function noteTarget(note: NoteSummary): { name: string; params: { id: string } } {
  return { name: 'note-detail', params: { id: note.id } }
}

function openMenu(folder: Folder): void {
  menuFolderId.value = menuFolderId.value === folder.id ? null : folder.id
}

async function startCreate(parentId: string | null): Promise<void> {
  menuFolderId.value = null
  creatingUnder.value = parentId
  createDraft.value = ''
  if (parentId) expand(parentId)
  await nextTick()
  document.querySelector<HTMLInputElement>('.tree-input .input')?.focus()
}

function cancelCreate(): void {
  creatingUnder.value = undefined
  createDraft.value = ''
}

async function submitCreate(): Promise<void> {
  const name = createDraft.value.trim()
  if (!name || busy.value) return

  busy.value = true
  error.value = ''
  const parentId = creatingUnder.value ?? null
  try {
    const created = await createFolder({ name, parent_id: parentId })
    creatingUnder.value = undefined
    createDraft.value = ''
    if (parentId) expand(parentId)
    selectedFolder.value = created.id
    ui.foldersChanged()
    await refresh()
  } catch (err) {
    error.value = actionError(err, '创建文件夹失败')
  } finally {
    busy.value = false
  }
}

async function startRename(folder: Folder): Promise<void> {
  menuFolderId.value = null
  renamingId.value = folder.id
  renameDraft.value = folder.name
  await nextTick()
  const input = document.querySelector<HTMLInputElement>('.tree-rename')
  input?.focus()
  input?.select()
}

function cancelRename(): void {
  renamingId.value = null
  renameDraft.value = ''
}

async function submitRename(folder: Folder): Promise<void> {
  const name = renameDraft.value.trim()
  if (!name || busy.value) return
  if (name === folder.name) {
    cancelRename()
    return
  }

  busy.value = true
  error.value = ''
  try {
    await updateFolder(folder.id, { name })
    renamingId.value = null
    renameDraft.value = ''
    ui.foldersChanged()
    await refresh()
  } catch (err) {
    error.value = actionError(err, '重命名失败')
  } finally {
    busy.value = false
  }
}

async function removeFolder(folder: Folder): Promise<void> {
  menuFolderId.value = null
  pendingDelete.value = {
    kind: 'folder',
    id: folder.id,
    name: folder.name,
    message: `删除「${folder.name}」及其所有子文件夹？里面的笔记会移到未分类。`,
  }
}

function removeNote(note: NoteSummary): void {
  pendingDelete.value = {
    kind: 'note',
    id: note.id,
    name: note.title,
    message: `确定删除「${note.title}」吗？删除后无法恢复。`,
  }
}

async function confirmDelete(): Promise<void> {
  const target = pendingDelete.value
  if (!target || deleting.value) return

  deleting.value = true
  error.value = ''
  try {
    if (target.kind === 'note') {
      await deleteNote(target.id)
      if (currentNoteId.value === target.id) {
        await router.push({ name: 'workbench' })
      }
      await refresh()
    } else {
      await deleteFolder(target.id)
      if (selectedFolder.value === target.id) selectedFolder.value = UNCLASSIFIED
      ui.foldersChanged()
      await refresh()
    }
    pendingDelete.value = null
  } catch (err) {
    error.value = actionError(err, target.kind === 'note' ? '删除笔记失败' : '删除文件夹失败')
    pendingDelete.value = null
  } finally {
    deleting.value = false
  }
}

async function toggleNoteVisibility(note: NoteSummary): Promise<void> {
  if (busyNoteId.value) return

  // 正在编辑这篇笔记时，先把编辑器里的最新内容落库，避免公开旧版本
  if (currentNoteId.value === note.id) {
    const ok = await ui.flushNote()
    if (!ok) return
  }

  busyNoteId.value = note.id
  error.value = ''
  try {
    const updated =
      note.visibility === 'public' ? await unpublishNote(note.id) : await publishNote(note.id)
    notes.value = notes.value.map((item) =>
      item.id === note.id
        ? { ...item, visibility: updated.visibility, updated_at: updated.updated_at }
        : item,
    )
  } catch (err) {
    error.value = actionError(err, '操作失败，请稍后重试')
  } finally {
    busyNoteId.value = null
  }
}

/** 列表内上下方向键切换笔记。 */
function onKeydown(event: KeyboardEvent): void {
  if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return
  const list = visibleNotes.value
  if (list.length === 0) return

  event.preventDefault()
  const index = list.findIndex((note) => note.id === currentNoteId.value)
  const nextIndex =
    event.key === 'ArrowDown' ? Math.min(index + 1, list.length - 1) : Math.max(index - 1, 0)
  if (nextIndex === index) return
  void router.push(noteTarget(list[nextIndex]))
}

function onDocumentPointerDown(event: PointerEvent): void {
  if (!menuFolderId.value) return
  const target = event.target as Element | null
  if (target?.closest('.tree-menu, .tree-more')) return
  menuFolderId.value = null
}

function onDocumentKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape') {
    menuFolderId.value = null
    if (creatingUnder.value !== undefined) cancelCreate()
    if (renamingId.value) cancelRename()
  }
}

function folderIndent(depth: number): string {
  return `${8 + depth * 16}px`
}

function noteIndent(depth: number): string {
  return `${8 + depth * 16 + 26}px`
}

watch(
  () => ui.notesVersion,
  () => {
    // 自动保存会频繁递增版本号；合并成一次刷新，避免每次按键都全量重取
    if (refreshTimer) clearTimeout(refreshTimer)
    refreshTimer = setTimeout(() => void refresh(), 300)
  },
)

// 打开某篇笔记时自动展开它所在的文件夹链，保证当前行可见
watch(
  [currentNoteId, notes],
  () => {
    const id = currentNoteId.value
    if (!id) return

    const note = notes.value.find((item) => item.id === id)
    let folderId = note?.folder_id ?? null
    if (!folderId) {
      looseExpanded.value = true
      return
    }

    const next = new Set(expanded.value)
    const seen = new Set<string>()
    while (folderId && !seen.has(folderId)) {
      seen.add(folderId)
      next.add(folderId)
      folderId = folders.value.find((folder) => folder.id === folderId)?.parent_id ?? null
    }
    expanded.value = next
  },
  { immediate: true },
)

onMounted(() => {
  void refresh()
  document.addEventListener('pointerdown', onDocumentPointerDown)
  document.addEventListener('keydown', onDocumentKeydown)
})

onBeforeUnmount(() => {
  if (refreshTimer) clearTimeout(refreshTimer)
  document.removeEventListener('pointerdown', onDocumentPointerDown)
  document.removeEventListener('keydown', onDocumentKeydown)
})
</script>

<template>
  <div class="list-panel">
    <header class="panel-head">
      <h1 class="panel-title">{{ panelTitle }}</h1>
    </header>

    <p v-if="error" class="notice notice--error" style="margin: 0 16px 12px">
      {{ error }}
      <span class="notice__actions">
        <button class="btn btn--sm" type="button" @click="refresh()">重试</button>
      </span>
    </p>

    <div v-if="loading && folders.length === 0 && notes.length === 0" style="padding: 0 16px 16px">
      <div class="skeleton skeleton--title" style="width: 46%"></div>
      <div class="skeleton skeleton--line" style="width: 88%; margin-top: 12px"></div>
      <div class="skeleton skeleton--line" style="width: 64%"></div>
    </div>

    <div v-else class="tree" role="tree" @keydown="onKeydown">
      <!-- 未分类：固定在最上方 -->
      <div class="tree-row tree-row--folder" :class="{ 'tree-row--selected': selectedFolder === UNCLASSIFIED }" role="treeitem" :aria-expanded="looseExpanded" @click="selectUnclassified">
        <button class="tree-toggle" type="button" :aria-label="looseExpanded ? '折叠未分类' : '展开未分类'" @click.stop="looseExpanded = !looseExpanded">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" :class="{ 'tree-chevron--open': looseExpanded }" aria-hidden="true">
            <path d="m9 6 6 6-6 6" />
          </svg>
        </button>
        <svg class="tree-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true">
          <path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
        </svg>
        <span class="tree-name">未分类</span>
        <span class="tree-count">{{ looseNotes.length }}</span>
      </div>

      <button
        v-for="note in looseExpanded ? looseNotes : []"
        :key="note.id"
        class="tree-row tree-row--note"
        :class="{ 'tree-row--active': note.id === currentNoteId }"
        type="button"
        role="treeitem"
        :style="{ paddingLeft: noteIndent(1) }"
        @click="router.push(noteTarget(note))"
      >
        <svg class="tree-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true">
          <path d="M6 3h7l5 5v13H6z" />
          <path d="M13 3v5h5" />
        </svg>
        <span class="tree-name">{{ note.title }}</span>
      </button>

      <!-- 根目录下新建文件夹 -->
      <div v-if="creatingUnder === null" class="tree-input" :style="{ paddingLeft: folderIndent(0) }">
        <input
          v-model="createDraft"
          class="input"
          type="text"
          placeholder="新文件夹名"
          aria-label="新文件夹名"
          @keydown.enter.prevent="submitCreate"
          @keydown.esc.prevent="cancelCreate"
          @blur="createDraft.trim() ? submitCreate() : cancelCreate()"
        />
      </div>

      <template v-for="row in rows" :key="row.kind === 'folder' ? `f-${row.folder.id}` : `n-${row.note.id}`">
        <!-- 文件夹行 -->
        <template v-if="row.kind === 'folder'">
          <div
            class="tree-row tree-row--folder"
            :class="{ 'tree-row--selected': selectedFolder === row.folder.id }"
            role="treeitem"
            :aria-expanded="expanded.has(row.folder.id)"
            :style="{ paddingLeft: folderIndent(row.depth) }"
            @click="selectFolder(row.folder)"
            @contextmenu.prevent="openMenu(row.folder)"
          >
            <button
              class="tree-toggle"
              type="button"
              :aria-label="expanded.has(row.folder.id) ? '折叠文件夹' : '展开文件夹'"
              @click.stop="toggleFolder(row.folder.id)"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" :class="{ 'tree-chevron--open': expanded.has(row.folder.id) }" aria-hidden="true">
                <path d="m9 6 6 6-6 6" />
              </svg>
            </button>

            <svg class="tree-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true">
              <path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            </svg>

            <input
              v-if="renamingId === row.folder.id"
              v-model="renameDraft"
              class="input tree-rename"
              type="text"
              aria-label="文件夹名"
              @click.stop
              @keydown.enter.prevent="submitRename(row.folder)"
              @keydown.esc.prevent="cancelRename"
              @blur="renameDraft.trim() && renameDraft !== row.folder.name ? submitRename(row.folder) : cancelRename()"
            />
            <span v-else class="tree-name">{{ row.folder.name }}</span>

            <button class="icon-btn tree-action" type="button" title="在此文件夹新建笔记" aria-label="在此文件夹新建笔记" @click.stop="createNoteIn(row.folder)">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M6 3h7l5 5v13H6z" />
                <path d="M13 3v5h5" />
                <path d="M12 12v5M9.5 14.5h5" />
              </svg>
            </button>
            <button class="icon-btn tree-action" type="button" title="新建子文件夹" aria-label="新建子文件夹" @click.stop="startCreate(row.folder.id)">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                <path d="M12 11v5M9.5 13.5h5" />
              </svg>
            </button>
            <button class="icon-btn tree-more" type="button" title="更多操作" aria-label="更多操作" @click.stop="openMenu(row.folder)">
              <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <circle cx="5" cy="12" r="1.6" />
                <circle cx="12" cy="12" r="1.6" />
                <circle cx="19" cy="12" r="1.6" />
              </svg>
            </button>

            <div v-if="menuFolderId === row.folder.id" class="tree-menu" role="menu">
              <button class="tree-menu__item" type="button" role="menuitem" @click.stop="startCreate(row.folder.id)">
                新建子文件夹
              </button>
              <button class="tree-menu__item" type="button" role="menuitem" @click.stop="startRename(row.folder)">
                重命名
              </button>
              <button class="tree-menu__item tree-menu__item--danger" type="button" role="menuitem" @click.stop="removeFolder(row.folder)">
                删除
              </button>
            </div>
          </div>

          <div v-if="creatingUnder === row.folder.id" class="tree-input" :style="{ paddingLeft: folderIndent(row.depth + 1) }">
            <input
              v-model="createDraft"
              class="input"
              type="text"
              placeholder="新文件夹名"
              aria-label="新文件夹名"
              @keydown.enter.prevent="submitCreate"
              @keydown.esc.prevent="cancelCreate"
              @blur="createDraft.trim() ? submitCreate() : cancelCreate()"
            />
          </div>
        </template>

        <!-- 笔记行 -->
        <div
          v-else
          class="tree-row tree-row--note"
          :class="{ 'tree-row--active': row.note.id === currentNoteId }"
          role="treeitem"
          tabindex="0"
          :style="{ paddingLeft: noteIndent(row.depth) }"
          @click="router.push(noteTarget(row.note))"
          @keydown.enter.self.prevent="router.push(noteTarget(row.note))"
        >
          <svg class="tree-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true">
            <path d="M6 3h7l5 5v13H6z" />
            <path d="M13 3v5h5" />
          </svg>
          <span class="tree-name">{{ row.note.title }}</span>

          <button
            class="icon-btn tree-action"
            type="button"
            :title="row.note.visibility === 'public' ? '撤回为私有' : '公开'"
            :aria-label="row.note.visibility === 'public' ? '撤回为私有' : '公开'"
            :disabled="busyNoteId === row.note.id"
            @click.stop="toggleNoteVisibility(row.note)"
          >
            <svg v-if="row.note.visibility === 'public'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <rect x="5" y="10" width="14" height="10" rx="2" />
              <path d="M8 10V7a4 4 0 0 1 8 0v3" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true">
              <circle cx="12" cy="12" r="9" />
              <path d="M3 12h18M12 3c2.5 2.4 3.8 5.6 3.8 9S14.5 18.6 12 21c-2.5-2.4-3.8-5.6-3.8-9S9.5 5.4 12 3z" />
            </svg>
          </button>

          <button
            class="icon-btn tree-action tree-action--danger"
            type="button"
            title="删除笔记"
            aria-label="删除笔记"
            :disabled="busyNoteId === row.note.id"
            @click.stop="removeNote(row.note)"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M4 7h16" />
              <path d="M9 7V4h6v3" />
              <path d="M6 7l1 13h10l1-13" />
              <path d="M10 11v6M14 11v6" />
            </svg>
          </button>
        </div>
      </template>

      <!-- 有文件夹但没有任何笔记时给一个空提示 -->
      <p v-if="notes.length === 0" class="tree-empty">
        {{ folders.length > 0 ? '这里还没有笔记。' : '还没有笔记，用下方按钮新建一篇或先建一个文件夹。' }}
      </p>
    </div>

    <div class="list-actions">
      <button class="btn btn--sm" type="button" @click="openModal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M6 3h7l5 5v13H6z" />
          <path d="M13 3v5h5" />
          <path d="M12 12v5M9.5 14.5h5" />
        </svg>
        新建笔记
      </button>
      <button class="btn btn--sm" type="button" @click="startCreate(targetFolderId)">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
          <path d="M12 11v5M9.5 13.5h5" />
        </svg>
        新建文件夹
      </button>
    </div>

    <NewNoteModal ref="modal" :open="showNew" :folder-id="targetFolderId" @close="showNew = false" />

    <ConfirmDialog
      :open="pendingDelete !== null"
      :title="pendingDelete?.kind === 'folder' ? '删除文件夹' : '删除笔记'"
      :message="pendingDelete?.message ?? ''"
      :busy="deleting"
      @confirm="confirmDelete"
      @cancel="pendingDelete = null"
    />
  </div>
</template>
