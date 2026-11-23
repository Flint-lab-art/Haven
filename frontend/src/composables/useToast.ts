/**
 * 全局提示条的调用入口。
 *
 * 组件 `<ToastHost />` 只在 App.vue 里挂一次；任何地方 `import { toast }` 就能用：
 *
 * ```ts
 * toast.success('账户已更新')
 * toast.error('保存失败，请重试')
 * ```
 *
 * 为什么不用 `ref + setTimeout`（以前 SettingsAccounts / SettingsBudget 的做法）：
 * 定时器分散在各页面里，切页面就会泄漏，而且样式各写一套。
 */
import { ref } from 'vue'
import type { ToastObject } from 'reka-ui'

/** toast 携带的附加数据（Reka 的泛型 T 必须是对象）。 */
export interface ToastMeta {
  tone: 'success' | 'error' | 'warning'
}

export type ToastTone = ToastMeta['tone']

/** 全局单一队列：id 单调递增，便于调试时对应。 */
let seq = 0
export const toastItems = ref<ToastObject<ToastMeta>[]>([])

const timers = new Map<string, number>()

function push(text: string, tone: ToastTone): void {
  const id = `t${++seq}`
  toastItems.value.push({
    id,
    description: text,
    data: { tone },
    type: 'foreground',
    open: true,
  } as ToastObject<ToastMeta>)

  // 收起时间：错误留久一点，成功短一点
  const ms = tone === 'error' ? 4000 : tone === 'warning' ? 3200 : 2600
  timers.set(
    id,
    window.setTimeout(() => dismiss(id), ms),
  )
}

function dismiss(id: string): void {
  const item = toastItems.value.find((t) => t.id === id)
  if (!item) return
  item.open = false
  const timer = timers.get(id)
  if (timer) window.clearTimeout(timer)
  timers.delete(id)
  // Presence 播完 closed 动画后再移除节点
  window.setTimeout(() => {
    toastItems.value = toastItems.value.filter((t) => t.id !== id)
  }, 200)
}

export const toast = {
  success(text: string): void {
    push(text, 'success')
  },
  error(text: string): void {
    push(text, 'error')
  },
  warning(text: string): void {
    push(text, 'warning')
  },
  dismiss,
  items: toastItems,
}
