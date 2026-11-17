/**
 * 文件夹的创建与重命名。
 *
 * 「新建文件夹」和「重命名」共用一个模式：进入编辑态 → 绑定草稿 → 提交时
 * 写库并刷新。这部分原先散在 `NoteListPanel` 里，与拖拽、图标面板混在一起。
 *
 * 组件只负责渲染输入框；状态与提交逻辑都在这里。
 */
import { nextTick, ref, type Ref } from 'vue'
import { createFolder, updateFolder, type Folder } from '@/api/folders'

export interface FolderEditing {
  /** undefined = 未在创建；null = 建在根目录；字符串 = 建在该文件夹下。 */
  creatingUnder: Ref<string | null | undefined>
  createDraft: Ref<string>
  renamingId: Ref<string | null>
  renameDraft: Ref<string>
  /** 进入创建态并聚焦输入框。 */
  startCreate: (parentId: string | null) => Promise<void>
  cancelCreate: () => void
  submitCreate: () => Promise<void>
  /** 进入重命名态并聚焦输入框。 */
  startRename: (folder: Folder) => Promise<void>
  cancelRename: () => void
  submitRename: (folder: Folder) => Promise<void>
}

export interface FolderEditingOptions {
  /** 是否正在提交（避免重复提交）。 */
  busy: Ref<boolean>
  /** 错误提示的写入目标。 */
  error: Ref<string>
  /** 展开某个文件夹（创建子文件夹时要让它可见）。 */
  expand: (id: string) => void
  /** 创建成功后选中新文件夹。 */
  selectFolder: (id: string | null) => void
  /** 提交成功后回调（刷新列表、通知其他面板）。 */
  onSaved: () => Promise<void> | void
  /** 把异常转成提示文案。 */
  actionError: (err: unknown, fallback: string) => string
}

export function useFolderEditing(options: FolderEditingOptions): FolderEditing {
  const creatingUnder = ref<string | null | undefined>(undefined)
  const createDraft = ref('')
  const renamingId = ref<string | null>(null)
  const renameDraft = ref('')

  async function startCreate(parentId: string | null): Promise<void> {
    creatingUnder.value = parentId
    createDraft.value = ''
    // 根目录输入框渲染在树的顶部，不受展开状态影响
    if (parentId) options.expand(parentId)
    await nextTick()
    document.querySelector<HTMLInputElement>('.tree-input .input')?.focus()
  }

  function cancelCreate(): void {
    creatingUnder.value = undefined
    createDraft.value = ''
  }

  async function submitCreate(): Promise<void> {
    const name = createDraft.value.trim()
    if (!name || options.busy.value) return

    options.busy.value = true
    options.error.value = ''
    const parentId = creatingUnder.value ?? null
    try {
      const created = await createFolder({ name, parent_id: parentId })
      creatingUnder.value = undefined
      createDraft.value = ''
      if (parentId) options.expand(parentId)
      options.selectFolder(created.id)
      await options.onSaved()
    } catch (err) {
      options.error.value = options.actionError(err, '创建文件夹失败')
    } finally {
      options.busy.value = false
    }
  }

  async function startRename(folder: Folder): Promise<void> {
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
    if (!name || options.busy.value) return
    if (name === folder.name) {
      cancelRename()
      return
    }

    options.busy.value = true
    options.error.value = ''
    try {
      await updateFolder(folder.id, { name })
      renamingId.value = null
      renameDraft.value = ''
      await options.onSaved()
    } catch (err) {
      options.error.value = options.actionError(err, '重命名失败')
    } finally {
      options.busy.value = false
    }
  }

  return {
    creatingUnder,
    createDraft,
    renamingId,
    renameDraft,
    startCreate,
    cancelCreate,
    submitCreate,
    startRename,
    cancelRename,
    submitRename,
  }
}
