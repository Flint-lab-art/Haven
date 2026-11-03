/**
 * 任务列表复选框（编辑态与阅读态共用）。
 *
 * 存储格式仍是 Markdown 原文的 `- [ ]` / `- [x]`：
 * - 编辑态由 Milkdown 的 `@milkdown/components` list-item-block 渲染 `<li>`，
 *   勾选写回 `list_item.attrs.checked`，再序列化回 Markdown；
 * - 阅读态由 marked 输出 `<input type="checkbox">`，这里换成同款只读方块。
 *
 * 两处用同一套 DOM/CSS，保证「编辑时点的方框」和「读的时候看到的方框」长得一样。
 */

/**
 * 单条列表项的方块标识。
 *
 * 作为 `<span>` 内嵌在 `<li>` 里，**不能带可聚焦/可点击语义**，
 * 否则会被 ProseMirror 当成不可编辑内容；点击判定由容器负责。
 */
export const checkboxClass = 'task-check'

/** 复选框状态：`null` 表示不是任务项（普通无序列表）。 */
export type CheckboxState = boolean | null

/** 生成一个方块；勾选与否只差一个 class。 */
export function checkboxHtml(checked: boolean): string {
  return `<span class="${checkboxClass}${checked ? ` ${checkboxClass}--checked` : ''}" aria-hidden="true"></span>`
}

/**
 * 阅读态：把 marked 输出的 `<input type="checkbox" disabled [checked]>` 换成方块。
 *
 * 必须在 DOMPurify **之前**做：`<input>` 在 sanitize 时会被整个删掉，
 * 连 `checked` 属性一起丢失，事后无法判断是否已勾选。
 * 这里只替换 marked 固定生成的标签形态，不引入任何用户可控的属性。
 */
export function renderTaskCheckboxes(html: string): string {
  return html.replace(/<li>\s*<input\b[^>]*\btype="checkbox"[^>]*>/g, (match) => {
    const checked = /\bchecked(=""|(?=[\s>]))/.test(match)
    return `<li>${checkboxHtml(checked)}`
  })
}

/**
 * 点击位置是否落在某一行任务项的方块上。
 *
 * 只处理「列表项的第一段」上的方块：点在正文里不该被当成勾选。
 * 返回该行的位置与当前状态，交给调用方决定怎么改。
 */
export interface CheckboxHit {
  /** 承载 checked 属性的列表项位置（ProseMirror 文档坐标）。 */
  pos: number
  checked: boolean
}

/**
 * 判断一次指针事件是否点中了编辑器的任务方块。
 *
 * `view.dom` 是 `.ProseMirror` 根节点；从方块往上找到最近的 `<li>`，
 * 再用 ProseMirror 的 `posAtDOM` 换算坐标。
 */
export function hitTestCheckbox(
  event: MouseEvent,
  root: HTMLElement,
  posAtDOM: (node: Node, offset: number) => number,
  nodeAt: (pos: number) => { attrs: Record<string, unknown> } | null,
): CheckboxHit | null {
  const target = event.target as HTMLElement | null
  const box = target?.closest?.(`.${checkboxClass}`) as HTMLElement | null
  if (!box || !root.contains(box)) return null

  // 方块外面还包着 .milkdown-icon（与 li 共用 .label 这个 class），
  // 所以向上找最近的 li，而不是只看直接父元素
  const li = box.closest('li')
  if (!li || !root.contains(li)) return null

  let pos: number
  try {
    pos = posAtDOM(li, 0) - 1
  } catch {
    return null
  }
  const node = nodeAt(pos)
  if (!node) return null
  const checked = node.attrs.checked
  // 不是任务项（普通列表）或位置对不上就不接管
  if (typeof checked !== 'boolean') return null
  return { pos, checked }
}
