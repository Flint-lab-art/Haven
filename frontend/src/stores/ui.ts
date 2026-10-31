/**
 * 界面状态 store：三栏布局里跨栏共享的少量状态。
 *
 * - 中间列表面板与右侧详情区互不同步，用版本号在数据变更后通知对方刷新；
 * - 标签与作品集没有独立路由，用选中项把中栏（列表）与右栏（详情）连起来。
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'

/** 侧边栏折叠状态持久化在 localStorage（ui-design.md 8.2）。 */
const SIDEBAR_MIN_KEY = 'haven.ui.sidebarMini'

function readSidebarMini(): boolean {
  try {
    return window.localStorage.getItem(SIDEBAR_MIN_KEY) === '1'
  } catch {
    // 隐私模式 / 禁用存储时退回默认展开
    return false
  }
}

function writeSidebarMini(mini: boolean): void {
  try {
    window.localStorage.setItem(SIDEBAR_MIN_KEY, mini ? '1' : '0')
  } catch {
    // 存不进去不影响本次会话的折叠
  }
}

export const useUiStore = defineStore('ui', () => {
  /** 侧边栏 Mini 模式（仅图标）。 */
  const sidebarMini = ref(readSidebarMini())
  /** 笔记增删改后 +1，笔记列表监听它重新拉取。 */
  const notesVersion = ref(0)
  /** 标签增删后 +1。 */
  const tagsVersion = ref(0)
  /** 文件夹增删改后 +1。 */
  const foldersVersion = ref(0)
  /** 作品集增删改后 +1。 */
  const portfolioVersion = ref(0)
  /** 回收站增删改后 +1（docs/v2/frontend/frontend.md 第三节）。 */
  const trashVersion = ref(0)
  /** 最近一次在目录树里移动的笔记；编辑器据此同步 folder_id。 */
  const lastNoteMove = ref<{ id: string; folderId: string | null; seq: number } | null>(null)

  const selectedTagId = ref<string | null>(null)
  const selectedPortfolioId = ref<string | null>(null)
  const portfolioCreating = ref(false)
  /** 回收站里选中的笔记。 */
  const selectedTrashId = ref<string | null>(null)

  function notesChanged(): void {
    notesVersion.value += 1
  }

  function tagsChanged(): void {
    tagsVersion.value += 1
  }

  function foldersChanged(): void {
    foldersVersion.value += 1
  }

  /** 目录树里移动笔记后通知编辑器，避免下一次自动保存把 folder_id 写回旧值。 */
  function noteMoved(id: string, folderId: string | null): void {
    lastNoteMove.value = {
      id,
      folderId,
      seq: (lastNoteMove.value?.seq ?? 0) + 1,
    }
  }

  function portfolioChanged(): void {
    portfolioVersion.value += 1
  }

  function trashChanged(): void {
    trashVersion.value += 1
  }

  function selectTrash(id: string | null): void {
    selectedTrashId.value = id
  }

  function selectTag(id: string | null): void {
    selectedTagId.value = id
  }

  function selectPortfolio(id: string | null): void {
    selectedPortfolioId.value = id
    portfolioCreating.value = false
  }

  function startPortfolioCreate(): void {
    selectedPortfolioId.value = null
    portfolioCreating.value = true
  }

  function toggleSidebar(): void {
    sidebarMini.value = !sidebarMini.value
    writeSidebarMini(sidebarMini.value)
  }

  /**
   * 编辑器注册的「立即保存」回调。
   * 目录树里点公开/撤回时先把当前笔记的草稿落库，避免公开旧内容。
   */
  let noteFlush: (() => Promise<boolean>) | null = null

  function registerNoteFlush(fn: (() => Promise<boolean>) | null): void {
    noteFlush = fn
  }

  async function flushNote(): Promise<boolean> {
    return noteFlush ? noteFlush() : true
  }

  return {
    sidebarMini,
    notesVersion,
    tagsVersion,
    foldersVersion,
    portfolioVersion,
    lastNoteMove,
    selectedTagId,
    selectedPortfolioId,
    portfolioCreating,
    notesChanged,
    tagsChanged,
    foldersChanged,
    noteMoved,
    portfolioChanged,
    trashVersion,
    selectedTrashId,
    trashChanged,
    selectTrash,
    selectTag,
    selectPortfolio,
    startPortfolioCreate,
    toggleSidebar,
    registerNoteFlush,
    flushNote,
  }
})
