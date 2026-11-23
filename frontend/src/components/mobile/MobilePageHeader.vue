<script setup lang="ts">
/**
 * 移动端页面头部：iOS 风格的「大标题」。
 *
 * 行为：
 * - 页面在顶部时，标题是 28px 的大字，周围留白充足；
 * - 往下滚动时，标题缩小并吸附在顶部，变成一行紧凑的导航栏；
 * - 滚回顶部时恢复。
 *
 * 实现用纯 CSS 的滚动驱动动画（`animation-timeline: scroll()`），
 * 不监听 `scroll` 事件——滚动回调会掉帧，而这条动画跑在合成线程上。
 * 浏览器不支持时（旧 Safari）退化为静态大标题，不影响可用性。
 *
 * 结构约定：
 * - 本组件必须是滚动容器 `.m-main` 的**第一个子元素**；
 * - `animation-timeline: scroll(nearest block)` 找到的滚动容器就是 `.m-main`
 *   （往上的最近祖先里有 overflow 的那个）。中间多套一层普通 div 会失效。
 */
defineProps<{
  title: string
}>()
</script>

<template>
  <header class="m-page-head">
    <div class="m-page-head__row">
      <slot name="lead" />
      <h1 class="m-page-head__title">{{ title }}</h1>
      <slot name="trail" />
    </div>
  </header>
</template>
