<script setup lang="ts">
/**
 * Haven 品牌图形：港口拱门 + H。
 *
 * 三个变体只服务于不同显示尺寸，不是三个不同的 logo：
 * - standard：28–40px（公开顶栏、展开侧边栏、登录页）
 * - compact：20–24px（Mini 侧边栏）
 * - small：16–32px（favicon）
 *
 * 统一使用 currentColor，外层用 --brand (#1F2A44) 上色。
 */
withDefaults(
  defineProps<{
    variant?: 'standard' | 'compact' | 'small'
    size?: number
  }>(),
  { variant: 'standard', size: 24 },
)
</script>

<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 64 64"
    fill="currentColor"
    aria-hidden="true"
    focusable="false"
  >
    <!-- 标准版：顶部港口拱 + H，底部两脚向内收成书页 -->
    <g v-if="variant === 'standard'">
      <path d="M9 32A23 23 0 0 1 55 32V33H45V32A13 13 0 0 0 19 32V33H9Z" />
      <path d="M9 32H19V45C19 49.5 22 52 26 52H15C11.5 52 9 49.5 9 46Z" />
      <path d="M55 32H45V45C45 49.5 42 52 38 52H49C52.5 52 55 49.5 55 46Z" />
      <rect x="18" y="34" width="28" height="8" rx="3" />
    </g>

    <!-- 紧凑版：去掉书页脚，加粗笔画，适配 20–24px -->
    <g v-else-if="variant === 'compact'">
      <path d="M10 30A22 22 0 0 1 54 30V31H44V30A12 12 0 0 0 20 30V31H10Z" />
      <path d="M10 30H20V50C20 52.5 17.5 54 15 54C12.5 54 10 52.5 10 50Z" />
      <path d="M54 30H44V50C44 52.5 46.5 54 49 54C51.5 54 54 52.5 54 50Z" />
      <rect x="19" y="36" width="26" height="8" rx="3" />
    </g>

    <!-- 小尺寸版：更粗的拱与竖笔，16px 下仍然清晰 -->
    <g v-else>
      <path d="M8 32A24 24 0 0 1 56 32V33H44V32A12 12 0 0 0 20 32V33H8Z" />
      <path d="M8 32H20V50C20 52.5 17.5 54 14 54C10.5 54 8 52.5 8 50Z" />
      <path d="M56 32H44V50C44 52.5 46.5 54 50 54C53.5 54 56 52.5 56 50Z" />
      <rect x="19" y="35" width="26" height="10" rx="3" />
    </g>
  </svg>
</template>
