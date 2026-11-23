<script setup lang="ts">
/**
 * 通用确认弹窗：替代浏览器 window.confirm，保持项目内的视觉与交互。
 *
 * 行为交给 Reka UI 的 AlertDialog：焦点陷阱、Esc、打开时聚焦、
 * 关闭后焦点归还触发元素、背景滚动锁定都由它处理。
 * 外观仍然是我们自己的 `.modal` 系列类，所以主题不需要额外适配。
 */
import { AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogOverlay, AlertDialogPortal, AlertDialogRoot, AlertDialogTitle } from 'reka-ui'

const props = withDefaults(
  defineProps<{
    open: boolean
    title: string
    message: string
    confirmText?: string
    busy?: boolean
  }>(),
  { confirmText: '删除', busy: false },
)

const emit = defineEmits<{
  confirm: []
  cancel: []
}>()

/**
 * 「确认」路径的标记。
 *
 * Reka 的 AlertDialogAction 本身就是 DialogClose：点它会在同一个事件里先走
 * DialogClose 的 onClick（触发 `update:open(false)`），再走我们挂的 @click。
 * 所以 onOpenChange 一定会早于 onConfirm 执行——如果在这里同步发 cancel，
 * 父组件（`@cancel="pendingDelete = null"`）会先把待处理目标清掉，
 * 随后 confirm 处理函数读到 null 直接返回，删除静默失效。
 *
 * 解决办法：把 cancel 的判定推迟到微任务，等本轮事件里的 @click 都跑完，
 * 看到 actionTaken 就跳过。这样与两个处理器的执行顺序无关。
 */
let actionTaken = false

/** 关闭时（Esc / 点遮罩 / 任一侧按钮）统一收口，避免同一轮重复发两次 cancel。 */
function onOpenChange(open: boolean): void {
  if (open) return
  queueMicrotask(() => {
    if (actionTaken) {
      actionTaken = false
      return
    }
    if (!props.busy) emit('cancel')
  })
}

function onConfirm(): void {
  if (props.busy) return
  actionTaken = true
  emit('confirm')
}

function onCancel(): void {
  if (props.busy) return
  actionTaken = true
  emit('cancel')
}
</script>

<template>
  <AlertDialogRoot :open="open" @update:open="onOpenChange">
    <AlertDialogPortal>
      <AlertDialogOverlay class="modal-backdrop" />
      <AlertDialogContent class="modal modal--confirm">
        <AlertDialogTitle class="modal__title">{{ title }}</AlertDialogTitle>
        <AlertDialogDescription class="confirm__message">{{ message }}</AlertDialogDescription>

        <div class="modal__actions">
          <AlertDialogCancel as-child :disabled="busy">
            <button class="btn" type="button" :disabled="busy" @click="onCancel">取消</button>
          </AlertDialogCancel>
          <AlertDialogAction as-child>
            <button class="btn btn--danger-solid" type="button" :disabled="busy" @click="onConfirm">
              {{ busy ? '处理中…' : confirmText }}
            </button>
          </AlertDialogAction>
        </div>
      </AlertDialogContent>
    </AlertDialogPortal>
  </AlertDialogRoot>
</template>
