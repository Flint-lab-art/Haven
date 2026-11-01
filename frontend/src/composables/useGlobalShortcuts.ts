/**
 * 全局快捷键（docs/v6/frontend/frontend.md 第二节）。
 *
 * 规则：
 *   - 全部 preventDefault，劫持浏览器默认行为（保存网页、新建窗口）；
 *   - Cmd+S 只在编辑页生效，由调用方通过 `canSave` 决定；
 *   - 焦点在输入框 / 文本域 / 可编辑区时，不拦截 Cmd+S 与 Cmd+N；
 *   - Cmd+K 任何状态都拦截。
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

/** 当前焦点是否在可输入的元素里。 */
function isTypingTarget(target: EventTarget | null): boolean {
  const el = target as HTMLElement | null
  if (!el) return false
  const tag = el.tagName
  if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return true
  return el.isContentEditable
}

/** 注册全局快捷键，组件卸载时自动移除。 */
export function useGlobalShortcuts(handlers: ShortcutHandlers): void {
  function onKeydown(event: KeyboardEvent): void {
    // 只用 Cmd（macOS）或 Ctrl（其他平台），Shift / Alt 组合不处理
    if (!(event.metaKey || event.ctrlKey) || event.shiftKey || event.altKey) return

    const typing = isTypingTarget(event.target)

    switch (event.key.toLowerCase()) {
      case 'k':
        // 命令面板在任何状态下都能呼出
        event.preventDefault()
        handlers.onTogglePalette()
        return
      case 'n':
        if (typing) return
        event.preventDefault()
        handlers.onNewNote()
        return
      case 's':
        if (typing) return
        // 由调用方决定当前页面是否处理；不处理时交还给浏览器
        if (handlers.onSave()) {
          event.preventDefault()
        }
        return
      default:
    }
  }

  onMounted(() => document.addEventListener('keydown', onKeydown))
  onBeforeUnmount(() => document.removeEventListener('keydown', onKeydown))
}
