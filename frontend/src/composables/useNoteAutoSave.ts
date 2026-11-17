/**
 * 笔记编辑页的自动保存状态机。
 *
 * 这块逻辑原先埋在 `NoteEditView`（628 行）里，与编辑器、标签、文件夹混在一起，
 * 而且是最容易出错的部分：
 *
 * - 防抖保存（默认 1 秒）
 * - 保存进行中又触发保存 → 排队，结束后再跑一次
 * - 新建笔记首次保存后换成详情路由
 * - 笔记在目录树里被删除（404）→ 放弃保存并允许离开
 * - 空白新笔记不创建空记录
 *
 * 抽出来后这些分支可以单测，不用挂载整个编辑页。
 */
import { computed, nextTick, ref, watch, type Ref } from 'vue'
import { ApiError } from '@/api/client'
import { createNote, updateNote, type Note } from '@/api/notes'

/** 自动保存防抖间隔（毫秒）。 */
export const AUTOSAVE_DELAY = 1000

export type SaveState = 'idle' | 'dirty' | 'saving' | 'saved' | 'error'

export interface NoteDraft {
  title: Ref<string>
  content: Ref<string>
  folderId: Ref<string | null>
  selectedTagIds: Ref<string[]>
}

export interface AutoSaveOptions {
  noteId: Readonly<Ref<string>>
  isNew: Readonly<Ref<boolean>>
  draft: NoteDraft
  /** 当前笔记实体，创建/更新成功后写回。 */
  note: Ref<Note | null>
  /** 回填中：加载笔记时抑制保存。 */
  hydrating: Ref<boolean>
  /** 空白新笔记（标题、正文、标签都空）——不创建空记录。 */
  isBlankNewNote: Readonly<Ref<boolean>>
  /** 把编辑器里的最新 HTML 同步到 `content`（保存前调用）。 */
  syncEditor?: () => Promise<void> | void
  /** 新建笔记改地址前是否处于离开流程（此时不 replace 路由）。 */
  isLeaving: () => boolean
  /** 新建成功后换到详情页地址。 */
  replaceToDetail: (id: string) => Promise<void>
  /** 保存成功、且标签集合变化时刷新标签计数。 */
  onTagsChanged: () => Promise<void> | void
  /** 保存成功后通知外部（目录树、仪表盘等）。 */
  onSaved: () => void
  /** 非 ApiError 的兜底提示。 */
  onError: (err: unknown) => void
}

export interface AutoSave {
  saving: Ref<boolean>
  saveState: Ref<SaveState>
  /** 上次保存时的快照，用于判断是否有改动。 */
  lastSaved: Ref<string>
  /** 状态文案，供模板直接显示。 */
  statusText: Readonly<Ref<string>>
  /** 当前草稿的序列化快照。 */
  snapshot: () => string
  /** 安排一次防抖保存。 */
  schedule: () => void
  /** 立即保存；返回是否成功。 */
  save: (syncEditor?: boolean) => Promise<boolean>
  /** 把基线对齐到当前草稿（用于「放弃修改」等场景）。 */
  alignBaseline: () => void
  /** 取消待执行的防抖保存（关闭笔记、组件卸载时调用）。 */
  cancelPending: () => void
  /**
   * 只同步标签基线，不动其他字段。
   * 新建笔记时刚加的标签不应算作「未保存的改动」。
   */
  syncTagsBaseline: () => void
  /**
   * 只提交标签（新建标签后立刻挂到已保存的笔记上）。
   * 与 `save()` 共用 saving / saveState / 排队逻辑，避免两份状态机。
   */
  saveTagsOnly: () => Promise<boolean>
}

export function useNoteAutoSave(options: AutoSaveOptions): AutoSave {
  const { draft, note, hydrating } = options

  const saving = ref(false)
  const saveState = ref<SaveState>('idle')
  /**
   * 上次保存时的快照。
   * <p>
   * 初始值必须是「当前草稿」而不是空串：否则首次调用 `save()` 会认为有改动，
   * 页面一打开就发一次无意义的 PATCH。加载完成后由 `alignBaseline()` 再对齐一次。
   */
  const lastSaved = ref(snapshotOf())
  /** 上次保存时的标签集合；只有标签变化时才刷新标签计数。 */
  let lastSavedTags = JSON.stringify(draft.selectedTagIds.value)
  let saveTimer: ReturnType<typeof setTimeout> | undefined
  let savePending = false

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

  function snapshotOf(): string {
    return JSON.stringify({
      title: draft.title.value,
      content: draft.content.value,
      tags: draft.selectedTagIds.value,
      folder: draft.folderId.value,
    })
  }

  const snapshot = snapshotOf

  // 标题、正文、标签、文件夹任一变化都走同一个防抖保存
  watch(
    [draft.title, draft.content, draft.selectedTagIds, draft.folderId],
    () => {
      if (hydrating.value) return
      if (snapshot() === lastSaved.value) return
      schedule()
    },
    { deep: true },
  )

  function schedule(): void {
    saveState.value = 'dirty'
    if (saveTimer) clearTimeout(saveTimer)
    saveTimer = setTimeout(() => void save(), AUTOSAVE_DELAY)
  }

  function alignBaseline(): void {
    lastSaved.value = snapshot()
  }

  /** 建新笔记的请求体。 */
  function createPayload() {
    return {
      title: draft.title.value,
      content: draft.content.value,
      tag_ids: draft.selectedTagIds.value,
      folder_id: draft.folderId.value,
    }
  }

  /**
   * 更新笔记的请求体。
   *
   * 后端 PATCH 的语义是「字段缺省 = 不修改，clear_folder = 移到根目录」，
   * 所以没有文件夹时不能传 folder_id: null。
   */
  function updatePayload() {
    const targetFolder = draft.folderId.value
    return {
      title: draft.title.value,
      content: draft.content.value,
      tag_ids: draft.selectedTagIds.value,
      ...(targetFolder ? { folder_id: targetFolder } : { clear_folder: true }),
    }
  }

  async function save(syncEditor = false): Promise<boolean> {
    if (saveTimer) {
      clearTimeout(saveTimer)
      saveTimer = undefined
    }
    if (hydrating.value) return true

    if (syncEditor && options.syncEditor) {
      await options.syncEditor()
      await nextTick()
    }

    // 空白新笔记不创建空记录：把基线对齐，状态回到闲置
    if (options.isBlankNewNote.value) {
      alignBaseline()
      if (saveState.value !== 'idle') saveState.value = 'idle'
      return true
    }

    if (snapshot() === lastSaved.value) {
      if (saveState.value !== 'saved' && saveState.value !== 'idle') saveState.value = 'saved'
      return true
    }
    // 上一次保存还没结束：标记待保存，结束后再跑一次
    if (saving.value) {
      savePending = true
      return true
    }

    saving.value = true
    saveState.value = 'saving'

    const pending = snapshot()
    const tagKey = JSON.stringify(draft.selectedTagIds.value)
    try {
      if (options.isNew.value) {
        const created = await createNote(createPayload())
        note.value = created
        lastSaved.value = pending
        saveState.value = 'saved'
        options.onSaved()
        // 换成详情地址；路由监听会重新载入，hydrating 防止回填触发再次保存
        if (!options.isLeaving()) {
          await options.replaceToDetail(created.id)
        }
        lastSavedTags = tagKey
        await options.onTagsChanged()
        return true
      }

      const updated = await updateNote(options.noteId.value, updatePayload())
      note.value = updated
      lastSaved.value = pending
      saveState.value = 'saved'
      options.onSaved()
      // 标签计数变了：不再被使用的标签会从列表消失
      if (tagKey !== lastSavedTags) {
        lastSavedTags = tagKey
        await options.onTagsChanged()
      }
      return true
    } catch (err) {
      if (err instanceof ApiError && err.isNotFound) {
        // 笔记已在目录树里被删除：放弃本次保存，并允许离开
        alignBaseline()
        saveState.value = 'idle'
        return true
      }
      options.onError(err)
      saveState.value = 'error'
      return false
    } finally {
      saving.value = false
      if (savePending) {
        savePending = false
        if (snapshot() !== lastSaved.value) schedule()
      }
    }
  }

  function syncTagsBaseline(): void {
    lastSavedTags = JSON.stringify(draft.selectedTagIds.value)
    if (!lastSaved.value) return
    try {
      const saved = JSON.parse(lastSaved.value) as Record<string, unknown>
      saved.tags = draft.selectedTagIds.value
      lastSaved.value = JSON.stringify(saved)
    } catch {
      // 快照格式异常时忽略，下一次保存会以当前标签为准
    }
  }

  async function saveTagsOnly(): Promise<boolean> {
    if (saving.value) {
      savePending = true
      return true
    }

    saving.value = true
    saveState.value = 'saving'

    const pending = snapshot()
    const tagKey = JSON.stringify(draft.selectedTagIds.value)
    try {
      const updated = await updateNote(options.noteId.value, { tag_ids: draft.selectedTagIds.value })
      note.value = updated
      lastSaved.value = pending
      lastSavedTags = tagKey
      saveState.value = 'saved'
      options.onSaved()
      await options.onTagsChanged()
      return true
    } catch (err) {
      if (err instanceof ApiError && err.isNotFound) {
        alignBaseline()
        saveState.value = 'idle'
        return true
      }
      options.onError(err)
      saveState.value = 'error'
      await options.onTagsChanged()
      return false
    } finally {
      saving.value = false
      if (savePending) {
        savePending = false
        if (snapshot() !== lastSaved.value) schedule()
      }
    }
  }

  function cancelPending(): void {
    if (saveTimer) {
      clearTimeout(saveTimer)
      saveTimer = undefined
    }
  }

  return {
    saving,
    saveState,
    lastSaved,
    statusText,
    snapshot,
    schedule,
    save,
    alignBaseline,
    cancelPending,
    syncTagsBaseline,
    saveTagsOnly,
  }
}
