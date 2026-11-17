/**
 * 笔记树的数据层。
 *
 * 负责「拉数据 + 算树结构」：加载文件夹与全部笔记、按 parent 分组、
 * 按展开状态拍平成行、维护当前选中目录。完全不涉及交互（拖拽、菜单、图标），
 * 那部分由组件与 `useTreeDrag` 负责。
 */
import { computed, ref, type ComputedRef, type Ref } from 'vue'
import { listFolders, type Folder } from '@/api/folders'
import { listNotes, type NoteSummary } from '@/api/notes'

/** 分页上限 100，内部循环取完所有笔记。 */
const PAGE_SIZE = 100

/** 树里的一行：文件夹或笔记，附带深度。 */
export type TreeRow =
  | { kind: 'folder'; folder: Folder; depth: number }
  | { kind: 'note'; note: NoteSummary; depth: number }

export interface NoteTree {
  folders: Ref<Folder[]>
  notes: Ref<NoteSummary[]>
  loading: Ref<boolean>
  error: Ref<string>
  selectedFolder: Ref<string | null>
  expanded: Ref<Set<string>>
  /** parent_id -> 子文件夹。拖拽排序需要取同级列表。 */
  childrenMap: ComputedRef<Map<string | null, Folder[]>>
  /** folder_id -> 笔记。拖拽排序需要取同级列表。 */
  notesMap: ComputedRef<Map<string | null, NoteSummary[]>>
  /** 按展开状态拍平的行，供渲染与键盘导航。 */
  rows: ComputedRef<TreeRow[]>
  /** 当前可见的笔记顺序。 */
  visibleNotes: ComputedRef<NoteSummary[]>
  /** 顶部标题：当前目录名或「收件箱」。 */
  panelTitle: ComputedRef<string>
  /** 真实收件箱 id。 */
  inboxFolderId: ComputedRef<string | null>
  /** 重新加载文件夹与笔记，并修正失效的选中项。 */
  refresh: () => Promise<void>
  /** 展开某个文件夹。 */
  expand: (id: string) => void
}

/** 一次性拉完全部笔记（个人使用量级足够）。 */
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

/**
 * @param onFolderGone 选中/正在设置图标的文件夹消失时回调（用于关掉图标面板等）
 */
export function useNoteTree(onFolderGone?: (validIds: Set<string>) => void): NoteTree {
  const folders = ref<Folder[]>([])
  const notes = ref<NoteSummary[]>([])
  const loading = ref(true)
  const error = ref('')
  /** 当前选中的文件夹 id；加载完成后默认选中收件箱。 */
  const selectedFolder = ref<string | null>(null)
  const expanded = ref<Set<string>>(new Set())

  /** parent_id -> 子文件夹（收件箱优先，再按 sort_order、name）。 */
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

  /** folder_id -> 笔记（目录内按 sort_order，更新时间兜底）。 */
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

  /** 把树按当前展开状态拍平成行。 */
  const rows = computed<TreeRow[]>(() => {
    const out: TreeRow[] = []
    const visited = new Set<string>()

    const walk = (parent: string | null, depth: number): void => {
      for (const folder of childrenMap.value.get(parent) ?? []) {
        // 数据成环时及时退出
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

  const visibleNotes = computed<NoteSummary[]>(() =>
    rows.value.filter((row): row is { kind: 'note'; note: NoteSummary; depth: number } => row.kind === 'note')
      .map((row) => row.note),
  )

  const inboxFolderId = computed(() => folders.value.find((folder) => folder.is_inbox)?.id ?? null)

  const panelTitle = computed(() => {
    if (!selectedFolder.value) return '收件箱'
    return folders.value.find((folder) => folder.id === selectedFolder.value)?.name ?? '收件箱'
  })

  function expand(id: string): void {
    if (expanded.value.has(id)) return
    expanded.value = new Set([...expanded.value, id])
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
        if (selectedFolder.value) expand(selectedFolder.value)
      }
      // 清掉已经不存在的展开项，避免集合无限增长
      expanded.value = new Set([...expanded.value].filter((id) => ids.has(id)))
      onFolderGone?.(ids)
    } catch {
      error.value = '笔记加载失败，请稍后重试'
    } finally {
      loading.value = false
    }
  }

  return {
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
  }
}
