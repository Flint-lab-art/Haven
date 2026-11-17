/**
 * 笔记树的纯函数工具。
 *
 * 这些逻辑原本散在 `NoteListPanel.vue`（1400+ 行）里，与响应式状态耦合，
 * 只能靠手点来验证。抽出来之后是纯函数，可以直接单测。
 */

/** 树的缩进：文件夹与笔记共用 16px 步长，笔记额外让出一列给「展开箭头」。 */
const INDENT_STEP = 16
const INDENT_BASE = 8
const NOTE_EXTRA = 26

/** 文件夹行的左内边距。 */
export function folderIndent(depth: number): string {
  return `${INDENT_BASE + depth * INDENT_STEP}px`
}

/** 笔记行的左内边距：比同级文件夹多让出箭头位置。 */
export function noteIndent(depth: number): string {
  return `${INDENT_BASE + depth * INDENT_STEP + NOTE_EXTRA}px`
}

/** 判断 candidateId 是否在 rootId 的子树里（含间接子节点）。 */
export function isFolderDescendant(
  folders: readonly { id: string; parent_id: string | null }[],
  rootId: string,
  candidateId: string,
): boolean {
  const parentOf = (id: string): string | null =>
    folders.find((folder) => folder.id === id)?.parent_id ?? null

  const seen = new Set<string>()
  let current = parentOf(candidateId)
  while (current) {
    if (current === rootId) return true
    // 数据异常成环时及时退出，避免死循环
    if (seen.has(current)) return false
    seen.add(current)
    current = parentOf(current)
  }
  return false
}

/** 拖动到行上时落在哪个位置：上 1/4 是「之前」，下 1/4 是「之后」，中间是「移入」。 */
export function folderDropPosition(
  clientY: number,
  rect: { top: number; height: number },
): 'before' | 'after' | 'inside' {
  const offset = clientY - rect.top
  if (offset < rect.height * 0.25) return 'before'
  if (offset > rect.height * 0.75) return 'after'
  return 'inside'
}

/** 笔记只能排序，所以只有「之前 / 之后」。 */
export function noteDropPosition(
  clientY: number,
  rect: { top: number; height: number },
): 'before' | 'after' {
  return clientY - rect.top < rect.height / 2 ? 'before' : 'after'
}

/** 拖拽起点是否落在可交互元素上（按钮、输入框、右键菜单）。 */
export function isInteractiveDragTarget(target: EventTarget | null): boolean {
  return target instanceof Element && target.closest('button, input, .tree-menu') !== null
}
