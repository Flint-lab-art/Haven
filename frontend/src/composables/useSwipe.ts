/**
 * 移动端横向滑动手势。
 *
 * 为什么不引库：每个手势只需几十行 touch 事件，引入 Swiper / VueUse
 * 反而要和现有的 scroll-snap、overflow 滚动打架。
 *
 * 只负责「算位移、判方向、报结果」，具体滑开后是什么样由组件决定。
 *
 * 关键取舍：**纵向占优时不拦截**。
 * 列表行既能横滑也能上下滚页面，如果无条件 `preventDefault`，
 * 手指稍微斜一点页面就滚不动了。所以先比方向，纵向直接放行。
 */
import { onBeforeUnmount, ref } from 'vue'

export interface SwipeOptions {
  /** 水平位移超过该值才算一次滑动。 */
  threshold?: number
  /** 横滑进行中回调，参数是当前水平位移（px，左负右正）。 */
  onMove?: (offsetX: number) => void
  /** 松手回调：direction 为 null 表示位移不够、视为点击。 */
  onEnd?: (direction: 'left' | 'right' | null, offsetX: number) => void
}

/** 判定方向时，水平位移要超过垂直位移的倍数。 */
const DIRECTION_RATIO = 1.2

export function useSwipe(options: SwipeOptions = {}) {
  const threshold = options.threshold ?? 12

  /** 是否处于横滑中（用于抑制 click）。 */
  const swiping = ref(false)

  let startX = 0
  let startY = 0
  let lastOffset = 0
  let active = false
  /** 已确认方向；null 表示还没判出来。 */
  let locked: 'horizontal' | 'vertical' | null = null
  let attachedNode: HTMLElement | null = null

  function reset(): void {
    active = false
    locked = null
    lastOffset = 0
    swiping.value = false
  }

  function onTouchStart(event: TouchEvent): void {
    if (event.touches.length !== 1) return
    startX = event.touches[0].clientX
    startY = event.touches[0].clientY
    lastOffset = 0
    active = true
    locked = null
    swiping.value = false
  }

  function onTouchMove(event: TouchEvent): void {
    if (!active || event.touches.length !== 1) return
    const dx = event.touches[0].clientX - startX
    const dy = event.touches[0].clientY - startY

    if (locked == null) {
      // 位移太小时还判不出方向，什么都不做
      if (Math.abs(dx) < threshold && Math.abs(dy) < threshold) return
      if (Math.abs(dy) > Math.abs(dx) * DIRECTION_RATIO) {
        // 纵向滑动：交给浏览器滚页面
        locked = 'vertical'
        active = false
        return
      }
      locked = 'horizontal'
      swiping.value = true
    }

    if (locked === 'horizontal') {
      lastOffset = dx
      options.onMove?.(dx)
    }
  }

  function onTouchEnd(): void {
    if (locked === 'horizontal') {
      const offset = lastOffset
      const direction: 'left' | 'right' | null =
        offset < -threshold ? 'left' : offset > threshold ? 'right' : null
      options.onEnd?.(direction, offset)
    }
    reset()
  }

  function onTouchCancel(): void {
    if (locked === 'horizontal') options.onEnd?.(null, 0)
    reset()
  }

  function attach(node: HTMLElement): void {
    detach()
    attachedNode = node
    node.addEventListener('touchstart', onTouchStart, { passive: true })
    node.addEventListener('touchmove', onTouchMove, { passive: true })
    node.addEventListener('touchend', onTouchEnd, { passive: true })
    node.addEventListener('touchcancel', onTouchCancel, { passive: true })
  }

  function detach(): void {
    if (!attachedNode) return
    attachedNode.removeEventListener('touchstart', onTouchStart)
    attachedNode.removeEventListener('touchmove', onTouchMove)
    attachedNode.removeEventListener('touchend', onTouchEnd)
    attachedNode.removeEventListener('touchcancel', onTouchCancel)
    attachedNode = null
  }

  onBeforeUnmount(detach)

  return { attach, detach, swiping, reset }
}
