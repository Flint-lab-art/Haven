<script setup lang="ts">
/**
 * 可左滑删除的列表行（移动端）。
 *
 * 交互按 iOS 习惯：
 * - 左滑露出一块红色「删除」；
 * - 露出后点这一行别处会收回，而不是误触打开编辑；
 * - 点「删除」才真正触发删除（不做「滑到底直接删」，
 *   记账数据误删比多点一次更麻烦）。
 */
import { computed, onMounted, ref } from 'vue'
import { useSwipe } from '@/composables/useSwipe'

const props = defineProps<{
  /** 是否已经有别的行处于展开状态。 */
  open: boolean
}>()

const emit = defineEmits<{
  /** 请求展开 / 收起本行。 */
  toggle: [open: boolean]
  /** 点删除。 */
  remove: []
  /** 点行本身（未滑开时）。 */
  tap: []
}>()

/** 删除区宽度（px）。 */
const ACTION_WIDTH = 76

/** 拖动过程中的实时位移（px，0 ~ -ACTION_WIDTH）。 */
const dragX = ref(0)

const { attach, swiping } = useSwipe({
  onMove: (dx) => {
    // 只允许向左滑；已经展开时允许向右滑回去
    const base = props.open ? -ACTION_WIDTH : 0
    const next = base + dx
    dragX.value = Math.min(0, Math.max(-ACTION_WIDTH, next))
  },
  onEnd: (direction) => {
    if (direction === 'left') {
      emit('toggle', true)
    } else if (direction === 'right') {
      emit('toggle', false)
    }
    // 松手后回到「完全展开」或「完全收起」，不做半吊子状态
    dragX.value = 0
  },
})

/** 行内容层的横向位移。 */
const translateX = computed(() => {
  if (dragX.value !== 0) return dragX.value
  return props.open ? -ACTION_WIDTH : 0
})

const dragging = ref(false)

function onMoveStart(): void {
  dragging.value = true
}

function onMoveEnd(): void {
  dragging.value = false
}

function onClick(): void {
  // 横滑过程中松手会触发 click，这里要挡掉
  if (swiping.value) return
  if (props.open) {
    emit('toggle', false)
    return
  }
  emit('tap')
}

function onDelete(): void {
  emit('remove')
}

/**
 * 用普通模板 ref + onMounted 绑定原生事件。
 *
 * 之前用函数式 ref（`:ref="(el) => bind(el)"`），
 * 它在重渲染时会先传 null 再传新节点，而 useSwipe 的 attach 里会先 detach，
 * 结果监听器在部分时机被摘掉，表现为「滑了没反应」。
 */
const contentEl = ref<HTMLElement | null>(null)

onMounted(() => {
  if (contentEl.value) attach(contentEl.value)
})
</script>

<template>
  <div class="m-swipe">
    <div class="m-swipe__action" :style="{ width: ACTION_WIDTH + 'px' }">
      <button type="button" class="m-swipe__btn" @click="onDelete">删除</button>
    </div>

    <div
      ref="contentEl"
      class="m-swipe__content"
      :class="{ 'm-swipe__content--dragging': dragging }"
      :style="{ transform: `translateX(${translateX}px)` }"
      @touchstart="onMoveStart"
      @touchend="onMoveEnd"
      @touchcancel="onMoveEnd"
      @click="onClick"
    >
      <slot />
    </div>
  </div>
</template>
