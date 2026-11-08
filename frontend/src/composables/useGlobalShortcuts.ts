/**
 * 全局快捷键（docs/v6/frontend/frontend.md 第二节）。
 *
 * 规则：
 *   - 全部 preventDefault，劫持浏览器默认行为（保存网页、新建窗口）；
 *   - Cmd+S 只在编辑页生效，由调用方通过 `onSave` 决定；
 *   - Cmd+S / Cmd+N 的分流按元素类型：
 *       · 笔记编辑器正文（.ProseMirror）→ Cmd+S 必须保存，Cmd+N 不拦；
 *       · input / textarea / select       → 两者都不拦；
 *       · 其它位置                         → 编辑页 Cmd+S 保存、全站 Cmd+N 新建；
 *   - Cmd+K 任何状态都拦截。
 *
 * 在**捕获阶段**监听：编辑器（TipTap / ProseMirror）会在冒泡阶段自己处理按键，
 * 不抢在前面的话，正文里按 Cmd+S 会被编辑器先吃掉或原样放给浏览器。
 */
import { onBeforeUnmount, onMounted } from 'vue'

export interface ShortcutHandlers {
  /** Cmd/Ctrl + K：切换命令面板。任何状态下都拦截。 */
  onTogglePalette: () => void
  /** Cmd/Ctrl + N：新建笔记。 */
  onNewNote: () => void
  /** Cmd/Ctrl + S：保存。返回 false 表示当前页面不处理，交给浏览器。 */
  onSave: () => boolean
}

/** 焦点所在的元素类型。 */
export type ShortcutTargetKind = 'editor' | 'field' | 'other'

/**
 * 判断焦点位置属于哪一类。
 *
 * 注意：编辑器正文是 contenteditable，但**不属于** `field`——
 * 它是笔记内容本身，Cmd+S 必须能保存。
 */
export function targetKind(target: EventTarget | null): ShortcutTargetKind {
  const el = target as HTMLElement | null
  if (!el) return 'other'

  // 编辑器正文：TipTap 里带 .ProseMirror，代码块内部还有可编辑的子节点
  if (el.closest?.('.ProseMirror')) return 'editor'

  const tag = el.tagName
  if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return 'field'

  // 其它 contenteditable（例如命令面板的输入框）按输入框处理。
  // 用属性判断而不是 isContentEditable：后者依赖布局计算，测试环境与部分场景下不可靠
  if (el.isContentEditable || el.closest?.('[contenteditable="true"]')) return 'field'

  return 'other'
}

/** 注册全局快捷键，组件卸载时自动移除。 */
export function useGlobalShortcuts(handlers: ShortcutHandlers): void {
  function onKeydown(event: KeyboardEvent): void {
    // 只用 Cmd（macOS）或 Ctrl（其他平台），Shift / Alt 组合不处理
    if (!(event.metaKey || event.ctrlKey) || event.shiftKey || event.altKey) return

    const kind = targetKind(event.target)

    switch (event.key.toLowerCase()) {
      case 'k':
        // 命令面板在任何状态下都能呼出
        event.preventDefault()
        handlers.onTogglePalette()
        return
      case 'n':
        if (kind !== 'other') return
        event.preventDefault()
        handlers.onNewNote()
        return
      case 's':
        // 编辑器正文照常保存；一次性输入控件交给浏览器
        if (kind === 'field') return
        // 由调用方决定当前页面是否处理；不处理时交还给浏览器
        if (handlers.onSave()) {
          event.preventDefault()
        }
        return
      default:
    }
  }

  // 捕获阶段：必须先于编辑器自己的键盘处理拿到事件
  onMounted(() => document.addEventListener('keydown', onKeydown, true))
  onBeforeUnmount(() => document.removeEventListener('keydown', onKeydown, true))
}
