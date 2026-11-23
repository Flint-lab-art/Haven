<script setup lang="ts">
/**
 * 全局提示条（toast）。
 *
 * 只在“页面里没有位置放反馈”的时候用：保存成功、操作失败、复制完成。
 * 编辑器的自动保存不弹 toast——那是行内状态，频率也太高。
 *
 * 外观走 `.toast` 系列类：无边框、--shadow-pop、圆角 r-xl，
 * 与弹层同一套浮起规则；状态用左侧 2px 竖条表达，不整块染色。
 */
import { ToastProvider, ToastRoot, ToastViewport } from 'reka-ui'
import type { ToastObject } from 'reka-ui'
import type { ToastMeta } from '@/composables/useToast'
import { toast } from '@/composables/useToast'

/** 关闭：交给队列收起，Presence 会播放 data-state=closed 的动画。 */
function close(item: ToastObject<ToastMeta>): void {
  toast.dismiss(item.id)
}
</script>

<template>
  <ToastProvider :duration="2600" label="通知">
    <!-- 气泡里只放一句文案：状态由左侧 2px 竖条表达，读屏靠 Root 的 aria 播报 -->
    <ToastRoot
      v-for="item in toast.items.value"
      :key="item.id"
      :toast="item"
      class="toast"
      :class="`toast--${item.data?.tone ?? 'success'}`"
      @update:open="(open: boolean) => !open && close(item)"
    >
      {{ item.description }}
    </ToastRoot>

    <ToastViewport class="toast-viewport" />
  </ToastProvider>
</template>
