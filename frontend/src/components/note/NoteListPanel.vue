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
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ConfirmDialog from '@/components/common/ConfirmDialog.vue'
import FolderTreeNode from './FolderTreeNode.vue'
import IconPicker from './IconPicker.vue'
import NoteTreeItem from './NoteTreeItem.vue'
import { ApiError } from '@/api/client'
import { deleteFolder, type Folder } from '@/api/folders'
import { deleteNote, type NoteSummary } from '@/api/notes'
import { useFolderEditing } from '@/composables/useFolderEditing'
import { useFolderIcon } from '@/composables/useFolderIcon'
import { useNoteTree } from '@/composables/useNoteTree'
import { useTreeDrag } from '@/composables/useTreeDrag'
import { useTreeDragPersist } from '@/composables/useTreeDragPersist'
import { useUiStore } from '@/stores/ui'
import { folderIndent, isFolderDescendant } from '@/utils/tree'
import { FilePlus, FolderPlus } from 'lucide-vue-next'


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

const busy = ref(false)

// 数据层：加载、树结构、展开状态
const {
  folders,
  notes,
  loading,
  error,
  selectedFolder,
  expanded,
  childrenMap,
  notesMap,
  rows,
  visibleNotes,
  panelTitle,
  inboxFolderId,
  refresh,
  expand,
} = useNoteTree((validIds) => {
  // 刷新后文件夹可能已被删：关掉指向它的图标面板
  if (iconFolderId.value && !validIds.has(iconFolderId.value)) closeIconPicker()
})

const currentNoteId = computed(() => String(route.params.id ?? ''))

const {
  persistFolderMove,
  persistNoteMove,
  siblingFolders,
  siblingNotes,
} = useTreeDragPersist({
  childrenMap,
  notesMap,
  currentNoteId,
  busy,
  error,
  expand,
  refresh,
  onFoldersChanged: () => ui.foldersChanged(),
  onNoteMoved: (noteId, folderId) => ui.noteMoved(noteId, folderId),
  flushCurrentNote: () => ui.flushNote(),
  toMessage: (err, fallback) => actionError(err, fallback),
})
// 文件夹的创建与重命名
const {
  creatingUnder,
  createDraft,
  renamingId,
  renameDraft,
  startCreate: startCreateRaw,
  cancelCreate,
  submitCreate: submitCreateRaw,
  startRename: startRenameRaw,
  cancelRename,
  submitRename,
} = useFolderEditing({
  busy,
  error,
  expand,
  selectFolder: (id) => {
    selectedFolder.value = id
  },
  onSaved: async () => {
    ui.foldersChanged()
    await refresh()
  },
  actionError,
})

/** 顶部「新建文件夹」：建在根目录，不跟随当前选中的目录。 */
function startCreateRoot(): void {
  selectedFolder.value = null
  void startCreateRaw(null)
}

/** 菜单里点「新建子文件夹」：先关菜单再进入创建态。 */
function startCreate(parentId: string | null): Promise<void> {
  menuFolderId.value = null
  return startCreateRaw(parentId)
}

/** 菜单里点「重命名」：先关菜单再进入编辑态。 */
function startRename(folder: Folder): Promise<void> {
  menuFolderId.value = null
  return startRenameRaw(folder)
}

// 文件夹图标
const {
  iconFolderId,
  open: startChangeIconRaw,
  toggle: toggleIconPicker,
  close: closeIconPicker,
  save: saveIcon,
  upload: uploadIcon,
} = useFolderIcon({
  busy,
  error,
  onSaved: async () => {
    ui.foldersChanged()
    await refresh()
  },
  actionError,
})

/** 菜单里点「更改图标」：先关菜单再开面板。 */
function startChangeIcon(folder: Folder): void {
  menuFolderId.value = null
  startChangeIconRaw(folder)
}


/** 模板里用的提交入口。 */
function submitCreate(): Promise<void> {
  return submitCreateRaw()
}
/** 新建笔记时的目标目录（未选中时交给后端默认归入收件箱）。 */
const targetFolderId = computed(() => selectedFolder.value)

/** 当前拖拽中的节点与可放置位置。 */

const menuFolderId = ref<string | null>(null)
/** 待确认的删除目标。 */
const pendingDelete = ref<{
  kind: 'note' | 'folder'
  id: string
  name: string
  message: string
} | null>(null)
const deleting = ref(false)

let refreshTimer: ReturnType<typeof setTimeout> | undefined

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
          <FilePlus aria-hidden="true" />
        </button>
        <button class="icon-btn" type="button" title="新建文件夹" aria-label="新建文件夹" @click="startCreateRoot">
          <FolderPlus aria-hidden="true" />
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
          >
            <template #picker>
              <IconPicker
                v-if="iconFolderId === row.folder.id"
                :open="true"
                :disabled="busy"
                @select="(value: string | null) => saveIcon(row.folder, value)"
                @upload="(file: File) => uploadIcon(row.folder, file)"
                @close="closeIconPicker"
              />
            </template>
          </FolderTreeNode>

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
          @open="router.push(noteTarget(row.note))"
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
