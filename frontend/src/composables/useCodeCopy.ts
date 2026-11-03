/**
 * 阅读态（`v-html` 渲染的 `.md-body`）的代码块复制按钮接线。
 *
 * `renderMarkdown` 已经在每个代码块里输出 `.code-copy` 按钮，
 * 这里只负责挂一次委托监听。事件委托是必要的：
 * `v-html` 的内容会被整体替换，逐个按钮绑事件会在重渲染后失效。
 *
 * 用法：
 *   const mdRef = ref<HTMLElement | null>(null)
 *   useCodeCopy(mdRef)
 */
import { onBeforeUnmount, onMounted, watch, type Ref } from 'vue'
import { installCodeCopyHandler } from '@/utils/clipboard'

export function useCodeCopy(root: Ref<HTMLElement | null>): void {
  let dispose: (() => void) | null = null

  const bind = (el: HTMLElement | null): void => {
    dispose?.()
    dispose = null
    if (el) dispose = installCodeCopyHandler(el)
  }

  onMounted(() => bind(root.value))
  // v-if 切换 / 内容重新渲染后，节点可能是新的
  watch(root, (el) => bind(el))

  onBeforeUnmount(() => {
    dispose?.()
    dispose = null
  })
}
