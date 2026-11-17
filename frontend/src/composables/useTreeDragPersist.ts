import { type ComputedRef, type Ref } from 'vue'
import { updateFolder, type Folder } from '@/api/folders'
import { updateNote, type NoteSummary } from '@/api/notes'

/** parent_id / folder_id → 该目录下的文件夹或笔记（由 useNoteTree 计算）。 */
type Grouped<K, T> = ComputedRef<Map<K, T[]>>

/**
 * 拖拽落盘：把「拖到哪儿」翻译成一批 PATCH 请求。
 *
 * 这是笔记树里最复杂的一段逻辑，核心思想是**重编号**：
 * 1. 把被拖项从原列表移除、插入目标列表的目标位置
 * 2. 重新排列后，凡是 `sort_order` 与下标不一致的项都要更新
 * 3. 跨目录时，原目录也要顺带补齐（挪走一个后下标会断档）
 *
 * 只有真正变化的项才会发请求：一次拖拽常常只改两三项，
 * 全量 PATCH 会在目录里笔记很多时产生几十个请求。
 *
 * 单独成 composable 的原因：这段算法一旦出错，表现是「拖完顺序乱了」，
 * 不报错也不抛异常，必须靠测试盯住发出的请求（见 note-tree-drag-persist.test.ts）。
 */

/** 一次更新要发出的字段：排序号，加上可能的父节点变更。 */
interface FolderUpdate {
  id: string
  sort_order: number
  parent_id?: string | null
}

interface NoteUpdate {
  id: string
  sort_order: number
  folder_id?: string | null
}

/**
 * 把「目标父节点」翻译成更新请求里的字段。
 *
 * 后端 PATCH 的语义是：字段缺省 = 不修改，`clear_*` = 移到根目录。
 * 所以 undefined 表示没换父节点，null 表示移到根。
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

export interface TreeDragPersistOptions {
  /** 文件夹树（按 parent 分组）。 */
  childrenMap: Grouped<string | null, Folder>
  /** 笔记树（按 folder_id 分组）。 */
  notesMap: Grouped<string | null, NoteSummary>
  /** 当前正在编辑的笔记 id，用于移动前先落盘草稿。 */
  currentNoteId: Readonly<Ref<string>>
  /** 全局忙碌标记。 */
  busy: Ref<boolean>
  /** 错误提示写入处。 */
  error: Ref<string>
  /** 展开某个文件夹（移动成功后让目标可见）。 */
  expand: (id: string) => void
  /** 重新拉取整棵树。 */
  refresh: () => Promise<void>
  /** 文件夹结构变化后通知全局（用于其他页面刷新）。 */
  onFoldersChanged: () => void
  /** 当前笔记被移走时通知编辑器。 */
  onNoteMoved: (noteId: string, folderId: string | null) => void
  /** 移动当前笔记前，先把编辑器草稿落库。返回 false 表示放弃本次移动。 */
  flushCurrentNote: () => Promise<boolean>
  /** 把接口错误翻译成用户可读的文案。 */
  toMessage: (err: unknown, fallback: string) => string
}

export function useTreeDragPersist(options: TreeDragPersistOptions) {
  const {
    childrenMap,
    notesMap,
    currentNoteId,
    busy,
    error,
    expand,
    refresh,
    onFoldersChanged,
    onNoteMoved,
    flushCurrentNote,
    toMessage,
  } = options

  /** 同目录下的文件夹，排除正在移动的那个。 */
  const siblingFolders = (parentId: string | null, excludeId?: string): Folder[] =>
    (childrenMap.value.get(parentId) ?? []).filter((folder) => folder.id !== excludeId)

  /** 同目录下的笔记，排除正在移动的那篇。 */
  const siblingNotes = (parentId: string | null, excludeId?: string): NoteSummary[] =>
    (notesMap.value.get(parentId) ?? []).filter((note) => note.id !== excludeId)

  async function persistFolderMove(
    moving: Folder,
    destParent: string | null,
    insertIndex: number,
  ): Promise<void> {
    const sourceParent = moving.parent_id ?? null
    const sameParent = sourceParent === destParent

    const siblings = siblingFolders(destParent, moving.id)
    // 同一目录下不允许重名：后端有唯一约束，但前端先拦一下给出明确提示
    if (siblings.some((folder) => folder.name === moving.name)) {
      error.value = '同一目录下已有同名文件夹'
      return
    }

    const destList = siblings
    destList.splice(Math.max(0, Math.min(insertIndex, destList.length)), 0, moving)

    const updates: FolderUpdate[] = []
    destList.forEach((folder, index) => {
      const parentChanged = folder.id === moving.id && !sameParent
      // 收件箱不参与排序
      if (!folder.is_inbox && (folder.sort_order !== index || parentChanged)) {
        updates.push({
          id: folder.id,
          sort_order: index,
          ...(parentChanged ? { parent_id: destParent } : {}),
        })
      }
    })

    // 跨目录时原目录会空出一个位置，后面的项要整体前移
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
      onFoldersChanged()
      await refresh()
    } catch (err) {
      error.value = toMessage(err, '移动文件夹失败')
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

    const updates: NoteUpdate[] = []
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

    // 正在编辑这篇笔记时先把草稿落库，
    // 否则随后的自动保存会用旧 folder_id 覆盖掉这次移动。
    if (moving.id === currentNoteId.value) {
      const ok = await flushCurrentNote()
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
        onNoteMoved(moving.id, destParent)
      }
      await refresh()
    } catch (err) {
      error.value = toMessage(err, '移动笔记失败')
      await refresh()
    } finally {
      busy.value = false
    }
  }

  return {
    persistFolderMove,
    persistNoteMove,
    siblingFolders,
    siblingNotes,
  }
}
