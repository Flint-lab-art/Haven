/**
 * 笔记树的拖拽状态机。
 *
 * 从 `NoteListPanel` 抽出来：这部分是「谁在拖、拖到哪、能不能放」的纯状态逻辑，
 * 与数据和渲染都无关，抽成 composable 后可以单测。
 *
 * 约定：
 * - 拖拽源用 `{ kind, id }` 表达，`root` 是虚拟落点（树最下方的「移到根目录」）；
 * - 拖到文件夹上分 `before` / `after` / `inside` 三种落点；
 * - 拖到笔记上只有 `before` / `after`（笔记不支持挂子节点）。
 */
import { computed, ref } from 'vue'
import type { Folder } from '@/api/folders'
import type { NoteSummary } from '@/api/notes'
import {
  folderDropPosition,
  isFolderDescendant,
  isInteractiveDragTarget,
  noteDropPosition,
} from '@/utils/tree'

export type DragKind = 'folder' | 'note'

export interface DragState {
  kind: DragKind
  id: string
}

export type DropTarget =
  | { kind: 'folder'; id: string; position: 'before' | 'after' | 'inside' }
  | { kind: 'note'; id: string; position: 'before' | 'after' }
  | { kind: 'root' }

/**
 * @param folders 当前文件夹列表（用于判断「不能拖进自己的子树」）
 * @param busy 忙碌时禁止开始拖拽
 */
export function useTreeDrag(folders: () => readonly Folder[], busy: () => boolean) {
  const dragState = ref<DragState | null>(null)
  const dropTarget = ref<DropTarget | null>(null)

  const isDragging = (kind: DragKind, id: string): boolean =>
    dragState.value?.kind === kind && dragState.value.id === id

  const isDrop = (
    kind: DropTarget['kind'],
    id: string | null,
    position?: 'before' | 'after' | 'inside',
  ): boolean => {
    const target = dropTarget.value
    if (!target || target.kind !== kind) return false
    if (kind === 'root') return true
    if ('id' in target && target.id !== id) return false
    return position === undefined || ('position' in target && target.position === position)
  }

  function startFolderDrag(event: DragEvent, folder: Folder): void {
    // 收件箱固定根目录第一位，不参与拖拽
    if (folder.is_inbox || busy() || isInteractiveDragTarget(event.target)) {
      event.preventDefault()
      return
    }
    begin(event, 'folder', folder.id)
  }

  function startNoteDrag(event: DragEvent, note: NoteSummary): void {
    if (busy() || isInteractiveDragTarget(event.target)) {
      event.preventDefault()
      return
    }
    begin(event, 'note', note.id)
  }

  function begin(event: DragEvent, kind: DragKind, id: string): void {
    dragState.value = { kind, id }
    dropTarget.value = null
    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'move'
      event.dataTransfer.setData('text/plain', `${kind}:${id}`)
    }
  }

  function clearDrag(): void {
    dragState.value = null
    dropTarget.value = null
  }

  function onFolderDragOver(event: DragEvent, folder: Folder): void {
    const drag = dragState.value
    if (!drag) return
    event.preventDefault()
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'move'

    // 笔记拖到文件夹上永远是「放入」
    if (drag.kind === 'note') {
      dropTarget.value = { kind: 'folder', id: folder.id, position: 'inside' }
      return
    }

    // 不能拖进自己或自己的子树
    if (drag.id === folder.id || isFolderDescendant(folders(), drag.id, folder.id)) {
      dropTarget.value = null
      return
    }

    // 收件箱不参与排序，拖到它上面一律视为放入
    if (folder.is_inbox) {
      dropTarget.value = { kind: 'folder', id: folder.id, position: 'inside' }
      return
    }

    dropTarget.value = {
      kind: 'folder',
      id: folder.id,
      position: folderDropPosition(
        event.clientY,
        (event.currentTarget as HTMLElement).getBoundingClientRect(),
      ),
    }
  }

  function onNoteDragOver(event: DragEvent, note: NoteSummary): void {
    if (dragState.value?.kind !== 'note') {
      dropTarget.value = null
      return
    }
    if (dragState.value.id === note.id) {
      dropTarget.value = null
      return
    }
    event.preventDefault()
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'move'
    dropTarget.value = {
      kind: 'note',
      id: note.id,
      position: noteDropPosition(
        event.clientY,
        (event.currentTarget as HTMLElement).getBoundingClientRect(),
      ),
    }
  }

  function onRootDragOver(event: DragEvent): void {
    if (!dragState.value) return
    event.preventDefault()
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'move'
    dropTarget.value = { kind: 'root' }
  }

  /** 当前是否正在拖拽（模板里控制「移到根目录」提示条）。 */
  const dragging = computed(() => dragState.value !== null)

  return {
    dragState,
    dropTarget,
    dragging,
    isDragging,
    isDrop,
    startFolderDrag,
    startNoteDrag,
    clearDrag,
    onFolderDragOver,
    onNoteDragOver,
    onRootDragOver,
  }
}
