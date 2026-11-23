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

function onOpenChange(open: boolean): void {
  if (!open && !props.busy) emit('cancel')
}

function onConfirm(): void {
  if (props.busy) return
  emit('confirm')
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
            <button class="btn" type="button" :disabled="busy" @click="emit('cancel')">取消</button>
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
