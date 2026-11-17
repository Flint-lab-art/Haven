<script setup lang="ts">
/**
 * 中间列表栏：文件夹树 + 笔记（docs/frontend/ui-design.md 第九节）。
 *
 * - 顶部工具栏左侧显示当前目录名，右侧是新建笔记 / 新建文件夹；
 * - 收件箱是真实文件夹（is_inbox = true），固定在根目录第一位；
 * - 文件夹可无限嵌套，箭头折叠 / 展开，点击名称高亮并展开直属笔记；
 * - 右键或 ... 菜单：新建子文件夹、重命名、更改图标、删除；
 * - 文件夹和笔记都支持拖拽；同层拖动会重编号 sort_order。
 *
 * 数据一次拉全：folder 接口返回平铺数组，笔记按 folder_id 分组；
 * 笔记分页在内部循环取完（个人使用量级足够）。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ConfirmDialog from '@/components/common/ConfirmDialog.vue'
import FolderTreeNode from './FolderTreeNode.vue'
import NoteTreeItem from './NoteTreeItem.vue'
import { ApiError } from '@/api/client'
import {
  createFolder,
  deleteFolder,
  listFolders,
  updateFolder,
  type Folder,
} from '@/api/folders'
import { deleteNote, listNotes, publishNote, unpublishNote, updateNote, type NoteSummary } from '@/api/notes'
import { useTreeDrag } from '@/composables/useTreeDrag'
import { useUiStore } from '@/stores/ui'
import { uploadImage } from '@/api/uploads'

import {
  folderIndent,
  isFolderDescendant,
} from '@/utils/tree'

/** 分页上限 100，内部循环取完所有笔记。 */
const PAGE_SIZE = 100

/** 图标面板的三个来源页（docs/v4/frontend/frontend.md 3.3）。 */
type Row =
  | { kind: 'folder'; folder: Folder; depth: number }
  | { kind: 'note'; note: NoteSummary; depth: number }

const route = useRoute()
const router = useRouter()
const ui = useUiStore()

// 拖拽状态机：与数据无关，单独放在 composable 里便于测试
const {
  dragState,
  dropTarget,
  isDragging,
  isDrop,
  startFolderDrag,
  startNoteDrag,
  clearDrag,
  onFolderDragOver,
  onNoteDragOver,
  onRootDragOver,
} = useTreeDrag(
  () => folders.value,
  () => busy.value,
)

const folders = ref<Folder[]>([])
const notes = ref<NoteSummary[]>([])
const loading = ref(true)
const error = ref('')
const busy = ref(false)

const expanded = ref<Set<string>>(new Set())
/** 当前选中的文件夹 id；加载完成后默认选中收件箱。 */
const selectedFolder = ref<string | null>(null)

/** 当前拖拽中的节点与可放置位置。 */

const menuFolderId = ref<string | null>(null)
/** undefined = 未在创建；null = 建在根目录；字符串 = 建在该文件夹下。 */
const creatingUnder = ref<string | null | undefined>(undefined)
const createDraft = ref('')
const renamingId = ref<string | null>(null)
const renameDraft = ref('')

/** 正在设置图标的文件夹，以及手动输入的 Emoji。 */
const iconFolderId = ref<string | null>(null)

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
    list.sort(
      (a, b) =>
        Number(b.is_inbox) - Number(a.is_inbox) ||
        a.sort_order - b.sort_order ||
        a.name.localeCompare(b.name, 'zh-CN'),
    )
  }
  return map
})

/** folder_id -> 笔记（按目录内 sort_order，更新时间为兜底）。 */
const notesMap = computed(() => {
  const map = new Map<string | null, NoteSummary[]>()
  for (const note of notes.value) {
    const key = note.folder_id ?? null
    const list = map.get(key) ?? []
    list.push(note)
    map.set(key, list)
  }
  for (const list of map.values()) {
    list.sort(
      (a, b) =>
        a.sort_order - b.sort_order ||
        new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime(),
    )
  }
  return map
})

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

/** 当前用户的真实收件箱 id。 */
const inboxFolderId = computed(() => folders.value.find((folder) => folder.is_inbox)?.id ?? null)

/** 当前可见的笔记顺序，供上下方向键切换。 */
const visibleNotes = computed(() => {
  const out: NoteSummary[] = []
  for (const row of rows.value) {
    if (row.kind === 'note') out.push(row.note)
  }
  return out
})

/** 当前选中的文件夹；未选中时新建笔记交给后端默认归入收件箱。 */
const targetFolderId = computed(() => selectedFolder.value)

/** 顶部左侧显示当前目录名（ui-design.md 9.1）。 */
const panelTitle = computed(() => {
  if (!selectedFolder.value) return '收件箱'
  return folders.value.find((folder) => folder.id === selectedFolder.value)?.name ?? '收件箱'
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

    const ids = new Set(folderResult.items.map((folder) => folder.id))
    const selectionMissing = !selectedFolder.value || !ids.has(selectedFolder.value)
    if (selectionMissing) {
      const inbox = folderResult.items.find((folder) => folder.is_inbox)
      selectedFolder.value = inbox?.id ?? folderResult.items[0]?.id ?? null
      if (selectedFolder.value) {
        expanded.value = new Set([...expanded.value, selectedFolder.value])
      }
    }
    expanded.value = new Set([...expanded.value].filter((id) => ids.has(id)))
    if (iconFolderId.value && !ids.has(iconFolderId.value)) closeIconPicker()
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

/**
 * 新建笔记：直接进入空白编辑页，标题与正文都为空。
 *
 * 不再弹窗收标题——空白编辑页本身就让标题始终可见可改，
 * 也省掉「先起名才能动笔」这一步。草稿只在内存，首次保存才 POST /api/notes。
 */
function startNewNote(): void {
  const folderId = targetFolderId.value
  void router.push({
    name: 'note-create',
    query: folderId ? { folder_id: folderId } : {},
  })
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

/** 文件夹行菜单的「新建笔记」：先选中该文件夹，再进入空白编辑页。 */
function createNoteIn(folder: Folder): void {
  selectFolder(folder)
  startNewNote()
}

function noteTarget(note: NoteSummary): { name: string; params: { id: string } } {
  return { name: 'note-detail', params: { id: note.id } }
}

function openMenu(folder: Folder): void {
  closeIconPicker()
  menuFolderId.value = menuFolderId.value === folder.id ? null : folder.id
}

function startChangeIcon(folder: Folder): void {
  menuFolderId.value = null
  iconFolderId.value = folder.id
}

/** 点击图标本身：再点一次收起面板。 */
function toggleIconPicker(folder: Folder): void {
  if (iconFolderId.value === folder.id) {
    closeIconPicker()
    return
  }
  startChangeIcon(folder)
}

function closeIconPicker(): void {
  iconFolderId.value = null
}

/** 上传图片并保存为图标。 */
async function uploadIcon(folder: Folder, file: File): Promise<void> {
  if (busy.value) return

  busy.value = true
  error.value = ''
  try {
    const res = await uploadImage(file, 'icon')
    await updateFolder(folder.id, { icon: res.url })
    closeIconPicker()
    ui.foldersChanged()
    await refresh()
  } catch (err) {
    error.value = actionError(err, '上传图标失败')
  } finally {
    busy.value = false
  }
}

/** value 为 null / 空串时清除图标，回到默认文件夹图标。 */
async function saveIcon(folder: Folder, value: string | null): Promise<void> {
  if (busy.value) return
  const icon = value?.trim() || null
  if (icon === folder.icon) {
    closeIconPicker()
    return
  }

  busy.value = true
  error.value = ''
  try {
    await updateFolder(folder.id, { icon })
    closeIconPicker()
    ui.foldersChanged()
    await refresh()
  } catch (err) {
    error.value = actionError(err, '更新图标失败')
  } finally {
    busy.value = false
  }
}

/** 顶部「新建文件夹」：建在根目录，不跟随当前选中的目录。 */
function startCreateRoot(): void {
  selectedFolder.value = null
  void startCreate(null)
}

async function startCreate(parentId: string | null): Promise<void> {
  menuFolderId.value = null
  creatingUnder.value = parentId
  createDraft.value = ''
  // 根目录输入框渲染在树的顶部，不受展开状态影响（ui-design.md 9.1）
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
  if (folder.is_inbox) return
  menuFolderId.value = null
  pendingDelete.value = {
    kind: 'folder',
    id: folder.id,
    name: folder.name,
    message: `删除「${folder.name}」及其所有子文件夹？里面的笔记会移到收件箱。`,
  }
}

function removeNote(note: NoteSummary): void {
  pendingDelete.value = {
    kind: 'note',
    id: note.id,
    name: note.title,
    // docs/v2/frontend/frontend.md 第四节：删除改为移入回收站，文案同步变更。
    message: `确定删除「${note.title}」吗？可在回收站中还原。`,
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
      if (selectedFolder.value === target.id) selectedFolder.value = null
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
  const target = event.target as Element | null
  if (menuFolderId.value && !target?.closest('.tree-menu, .tree-more')) {
    menuFolderId.value = null
  }
  if (iconFolderId.value && !target?.closest('.icon-picker')) {
    closeIconPicker()
  }
}

function onDocumentKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape') {
    menuFolderId.value = null
    closeIconPicker()
    clearDrag()
    if (creatingUnder.value !== undefined) cancelCreate()
    if (renamingId.value) cancelRename()
  }
}

/* ---------------- 拖拽 ---------------- */

function siblingFolders(parentId: string | null, excludeId?: string): Folder[] {
  return (childrenMap.value.get(parentId) ?? []).filter((folder) => folder.id !== excludeId)
}

function siblingNotes(parentId: string | null, excludeId?: string): NoteSummary[] {
  return (notesMap.value.get(parentId) ?? []).filter((note) => note.id !== excludeId)
}

/**
 * 把「目标父节点」翻译成更新请求里的字段。
 *
 * 后端的 PATCH 语义是：字段缺省 = 不修改，`clear_*` = 移到根目录。
 * 拖拽场景里 undefined 表示没换父节点，null 表示移到根。
 */
function toFolderParent(parentId: string | null | undefined): {
  clear_parent?: true
  parent_id?: string
} {
  if (parentId === undefined) return {}
  return parentId === null ? { clear_parent: true } : { parent_id: parentId }
}

/** 同上，用于笔记的文件夹归属。 */
function toNoteFolder(folderId: string | null | undefined): {
  clear_folder?: true
  folder_id?: string
} {
  if (folderId === undefined) return {}
  return folderId === null ? { clear_folder: true } : { folder_id: folderId }
}

async function persistFolderMove(
  moving: Folder,
  destParent: string | null,
  insertIndex: number,
): Promise<void> {
  const sourceParent = moving.parent_id ?? null
  const sameParent = sourceParent === destParent

  const siblings = siblingFolders(destParent, moving.id)
  if (siblings.some((folder) => folder.name === moving.name)) {
    error.value = '同一目录下已有同名文件夹'
    return
  }

  const destList = siblings
  destList.splice(Math.max(0, Math.min(insertIndex, destList.length)), 0, moving)

  const updates: { id: string; sort_order: number; parent_id?: string | null }[] = []
  destList.forEach((folder, index) => {
    const parentChanged = folder.id === moving.id && !sameParent
    if (!folder.is_inbox && (folder.sort_order !== index || parentChanged)) {
      updates.push({
        id: folder.id,
        sort_order: index,
        ...(parentChanged ? { parent_id: destParent } : {}),
      })
    }
  })

  if (!sameParent) {
    siblingFolders(sourceParent, moving.id).forEach((folder, index) => {
      if (!folder.is_inbox && folder.sort_order !== index) {
        updates.push({ id: folder.id, sort_order: index })
      }
    })
  }

  if (updates.length === 0) return

  busy.value = true
  error.value = ''
  try {
    await Promise.all(
      updates.map((update) =>
        updateFolder(update.id, {
          sort_order: update.sort_order,
          ...toFolderParent(update.parent_id),
        }),
      ),
    )
    if (destParent) expand(destParent)
    ui.foldersChanged()
    await refresh()
  } catch (err) {
    error.value = actionError(err, '移动文件夹失败')
    await refresh()
  } finally {
    busy.value = false
  }
}

async function persistNoteMove(
  moving: NoteSummary,
  destParent: string | null,
  insertIndex: number,
): Promise<void> {
  const sourceParent = moving.folder_id ?? null
  const sameParent = sourceParent === destParent

  const destList = siblingNotes(destParent, moving.id)
  destList.splice(Math.max(0, Math.min(insertIndex, destList.length)), 0, moving)

  const updates: { id: string; sort_order: number; folder_id?: string | null }[] = []
  destList.forEach((note, index) => {
    const parentChanged = note.id === moving.id && !sameParent
    if (note.sort_order !== index || parentChanged) {
      updates.push({
        id: note.id,
        sort_order: index,
        ...(parentChanged ? { folder_id: destParent } : {}),
      })
    }
  })

  if (!sameParent) {
    siblingNotes(sourceParent, moving.id).forEach((note, index) => {
      if (note.sort_order !== index) updates.push({ id: note.id, sort_order: index })
    })
  }

  if (updates.length === 0) return

  // 正在编辑这篇笔记时，先把编辑器草稿落库，避免自动保存与移动互相覆盖。
  if (moving.id === currentNoteId.value) {
    const ok = await ui.flushNote()
    if (!ok) return
  }

  busy.value = true
  error.value = ''
  try {
    await Promise.all(
      updates.map((update) =>
        updateNote(update.id, {
          sort_order: update.sort_order,
          ...toNoteFolder(update.folder_id),
        }),
      ),
    )
    if (destParent) expand(destParent)
    if (!sameParent && moving.id === currentNoteId.value) {
      ui.noteMoved(moving.id, destParent)
    }
    await refresh()
  } catch (err) {
    error.value = actionError(err, '移动笔记失败')
    await refresh()
  } finally {
    busy.value = false
  }
}

async function onFolderDrop(folder: Folder): Promise<void> {
  const drag = dragState.value
  const target = dropTarget.value
  clearDrag()
  if (!drag) return

  // 笔记拖到文件夹上：移动到该文件夹顶部（api.md 6.4）。
  if (drag.kind === 'note') {
    if (target?.kind !== 'folder' || target.position !== 'inside') return
    const moving = notes.value.find((note) => note.id === drag.id)
    if (!moving) return
    await persistNoteMove(moving, folder.id, 0)
    return
  }

  if (drag.id === folder.id || isFolderDescendant(folders.value, drag.id, folder.id)) return
  const moving = folders.value.find((item) => item.id === drag.id)
  if (!moving || target?.kind !== 'folder' || target.id !== folder.id) return

  if (target.position === 'inside') {
    await persistFolderMove(moving, folder.id, siblingFolders(folder.id, moving.id).length)
    return
  }

  const destParent = folder.parent_id ?? null
  const destList = siblingFolders(destParent, moving.id)
  const targetIndex = destList.findIndex((item) => item.id === folder.id)
  if (targetIndex < 0) return
  await persistFolderMove(
    moving,
    destParent,
    target.position === 'before' ? targetIndex : targetIndex + 1,
  )
}

async function onNoteDrop(note: NoteSummary): Promise<void> {
  const drag = dragState.value
  const target = dropTarget.value
  clearDrag()
  if (!drag || drag.kind !== 'note' || drag.id === note.id) return
  if (target?.kind !== 'note' || target.id !== note.id) return

  const moving = notes.value.find((item) => item.id === drag.id)
  if (!moving) return

  const destParent = note.folder_id ?? null
  const destList = siblingNotes(destParent, moving.id)
  const targetIndex = destList.findIndex((item) => item.id === note.id)
  if (targetIndex < 0) return
  await persistNoteMove(
    moving,
    destParent,
    target.position === 'before' ? targetIndex : targetIndex + 1,
  )
}

async function onRootDrop(): Promise<void> {
  const drag = dragState.value
  clearDrag()
  if (!drag) return

  if (drag.kind === 'folder') {
    const moving = folders.value.find((folder) => folder.id === drag.id)
    if (!moving) return
    await persistFolderMove(moving, null, siblingFolders(null, moving.id).length)
    return
  }

  const moving = notes.value.find((note) => note.id === drag.id)
  if (!moving) return
  await persistNoteMove(moving, inboxFolderId.value, 0)
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
    let folderId = note?.folder_id ?? inboxFolderId.value
    if (!folderId) return

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
      <h1 class="panel-title panel-title--compact">{{ panelTitle }}</h1>
      <div class="panel-actions">
        <button class="icon-btn" type="button" title="新建笔记" aria-label="新建笔记" @click="startNewNote">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M6 3h7l5 5v13H6z" />
            <path d="M13 3v5h5" />
            <path d="M12 12v5M9.5 14.5h5" />
          </svg>
        </button>
        <button class="icon-btn" type="button" title="新建文件夹" aria-label="新建文件夹" @click="startCreateRoot">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            <path d="M12 11v5M9.5 13.5h5" />
          </svg>
        </button>
      </div>
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
          <FolderTreeNode
            :folder="row.folder"
            :depth="row.depth"
            :expanded="expanded.has(row.folder.id)"
            :selected="selectedFolder === row.folder.id"
            :dragging="isDragging('folder', row.folder.id)"
            :drop-position="
              isDrop('folder', row.folder.id, 'before')
                ? 'before'
                : isDrop('folder', row.folder.id, 'after')
                  ? 'after'
                  : isDrop('folder', row.folder.id, 'inside')
                    ? 'inside'
                    : null
            "
            :renaming="renamingId === row.folder.id"
            v-model:rename-draft="renameDraft"
            @select="selectFolder(row.folder)"
            @toggle="toggleFolder(row.folder.id)"
            @menu="openMenu(row.folder)"
            @change-icon="toggleIconPicker(row.folder)"
            @create-note="createNoteIn(row.folder)"
            @create-child="startCreate(row.folder.id)"
            @submit-rename="
              renameDraft.trim() && renameDraft !== row.folder.name
                ? submitRename(row.folder)
                : cancelRename()
            "
            @cancel-rename="cancelRename"
            @dragstart="startFolderDrag($event, row.folder)"
            @dragover="onFolderDragOver($event, row.folder)"
            @drop="onFolderDrop(row.folder)"
            @dragend="clearDrag"
          />

          <div v-if="menuFolderId === row.folder.id" class="tree-menu" role="menu">
            <button
              class="tree-menu__item"
              type="button"
              role="menuitem"
              @click.stop="startCreate(row.folder.id)"
            >
              新建子文件夹
            </button>
            <button
              class="tree-menu__item"
              type="button"
              role="menuitem"
              @click.stop="startRename(row.folder)"
            >
              重命名
            </button>
            <button
              class="tree-menu__item"
              type="button"
              role="menuitem"
              @click.stop="startChangeIcon(row.folder)"
            >
              更改图标
            </button>
            <button
              v-if="!row.folder.is_inbox"
              class="tree-menu__item tree-menu__item--danger"
              type="button"
              role="menuitem"
              @click.stop="removeFolder(row.folder)"
            >
              删除
            </button>
          </div>

          <IconPicker
            v-if="iconFolderId === row.folder.id"
            :open="true"
            :disabled="busy"
            @select="(value: string | null) => saveIcon(row.folder, value)"
            @upload="(file: File) => uploadIcon(row.folder, file)"
            @close="closeIconPicker"
          />

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
        <NoteTreeItem
          v-else
          :note="row.note"
          :depth="row.depth"
          :active="row.note.id === currentNoteId"
          :dragging="isDragging('note', row.note.id)"
          :drop-position="
            isDrop('note', row.note.id, 'before')
              ? 'before'
              : isDrop('note', row.note.id, 'after')
                ? 'after'
                : null
          "
          :busy="busyNoteId === row.note.id"
          @open="router.push(noteTarget(row.note))"
          @toggle-visibility="toggleNoteVisibility(row.note)"
          @remove="removeNote(row.note)"
          @dragstart="startNoteDrag($event, row.note)"
          @dragover="onNoteDragOver($event, row.note)"
          @drop="onNoteDrop(row.note)"
          @dragend="clearDrag"
        />
      </template>

      <!-- 拖到树的最下方：文件夹回根目录，笔记进收件箱 -->
      <div
        v-if="dragState"
        class="tree-root-drop"
        :class="{ 'tree-root-drop--active': isDrop('root', null) }"
        @dragover.prevent="onRootDragOver"
        @drop.prevent="onRootDrop"
      >
        {{ dragState.kind === 'folder' ? '移到根目录' : '移到收件箱' }}
      </div>

      <!-- 有文件夹但没有任何笔记时给一个空提示 -->
      <p v-if="notes.length === 0" class="tree-empty">
        {{ folders.length > 0 ? '这里还没有笔记。' : '还没有笔记，用上方按钮新建一篇或先建一个文件夹。' }}
      </p>
    </div>


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
