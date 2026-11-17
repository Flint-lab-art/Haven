<script setup lang="ts">
/** 通用确认弹窗：替代浏览器 window.confirm，保持项目内的视觉与交互。 */
import { nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'

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

const cancelButton = ref<HTMLButtonElement | null>(null)

function onKeydown(event: KeyboardEvent): void {
  if (!props.open) return
  if (event.key !== 'Escape') return
  event.preventDefault()
  if (!props.busy) emit('cancel')
}

watch(
  () => props.open,
  async (open) => {
    if (!open) return
    await nextTick()
    cancelButton.value?.focus()
  },
)

onMounted(() => document.addEventListener('keydown', onKeydown))
onBeforeUnmount(() => document.removeEventListener('keydown', onKeydown))
</script>

<template>
  <div v-if="open" class="modal-backdrop" role="presentation" @click.self="!busy && emit('cancel')">
    <div class="modal modal--confirm" role="alertdialog" aria-modal="true" :aria-label="title">
      <h2 class="modal__title">{{ title }}</h2>
      <p class="confirm__message">{{ message }}</p>

      <div class="modal__actions">
        <button ref="cancelButton" class="btn" type="button" :disabled="busy" @click="emit('cancel')">
          取消
        </button>
        <button class="btn btn--danger-solid" type="button" :disabled="busy" @click="emit('confirm')">
          {{ busy ? '处理中…' : confirmText }}
        </button>
      </div>
    </div>
  </div>
</template>
