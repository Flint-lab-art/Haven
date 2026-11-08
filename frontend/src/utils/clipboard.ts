/**
 * 剪贴板（编辑态与阅读态共用）。
 *
 * 只处理「复制纯文本」这一件事，失败时返回 false，**不抛错、不弹窗**
 * （docs/v6/frontend/frontend.md 6.2）。
 */

/** 复制按钮的三种瞬时状态。 */
export type CopyState = 'idle' | 'copied' | 'failed'

/** 「已复制 / 复制失败」保持的时长（docs/v6/frontend/frontend.md 6.3）。 */
export const COPY_FEEDBACK_MS = 1500

/**
 * 复制纯文本。失败时返回 false，不抛错、不弹窗。
 *
 * 优先用异步 Clipboard API；在非安全上下文（http + 非 localhost）或旧浏览器上
 * 回退到 `<textarea> + execCommand`，再失败就静默返回 false。
 */
export async function copyText(text: string): Promise<boolean> {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text)
      return true
    }
  } catch {
    // 落到 execCommand 回退
  }

  try {
    const area = document.createElement('textarea')
    area.value = text
    // 放到视口外，避免页面跳动与选中高亮
    area.setAttribute('readonly', '')
    area.style.position = 'fixed'
    area.style.top = '-9999px'
    area.style.opacity = '0'
    document.body.appendChild(area)
    area.select()
    const ok = document.execCommand('copy')
    document.body.removeChild(area)
    return ok
  } catch {
    return false
  }
}

/**
 * 给代码块的复制按钮刷一次反馈：改成「已复制」/「复制失败」，1.5 秒后复原。
 *
 * 编辑态（ProseMirror widget）和阅读态（renderHtml 输出的 `<button>`）共用这一份，
 * 保证两处的文案与时长完全一致。
 */
export function flashCopyState(button: HTMLElement, ok: boolean): void {
  const previous = Number(button.dataset.timer)
  if (previous) window.clearTimeout(previous)

  button.dataset.state = ok ? 'copied' : 'failed'
  button.textContent = ok ? '已复制' : '复制失败'

  const timer = window.setTimeout(() => {
    if (!button.isConnected) return
    button.dataset.state = 'idle'
    button.dataset.timer = '0'
    button.textContent = '复制'
  }, COPY_FEEDBACK_MS)
  button.dataset.timer = String(timer)
}

/**
 * 阅读态的复制按钮委托：点击 `.code-copy` 时复制同级 `<pre>` 的文本。
 *
 * 返回解绑函数，供组件卸载时调用。没有按钮匹配时返回 null，调用方无需处理。
 */
export function installCodeCopyHandler(root: HTMLElement): () => void {
  const onClick = (event: Event): void => {
    const target = event.target as HTMLElement | null
    const button = target?.closest?.('.code-copy') as HTMLElement | null
    if (!button || !root.contains(button)) return

    const pre = button.parentElement?.querySelector('pre')
    if (!pre) return

    event.preventDefault()
    if (button.dataset.state === 'busy') return
    button.dataset.state = 'busy'
    void copyText(pre.textContent ?? '').then((ok) => flashCopyState(button, ok))
  }

  root.addEventListener('click', onClick)
  return () => root.removeEventListener('click', onClick)
}
