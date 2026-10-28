<script setup lang="ts">
/** 标签徽章（docs/frontend/frontend.md 第八节公共组件）。 */
import { RouterLink } from 'vue-router'

withDefaults(
  defineProps<{
    name: string
    /** 传入则渲染为跳转搜索的链接，否则是纯展示。 */
    to?: string
  }>(),
  { to: undefined },
)
</script>

<template>
  <RouterLink v-if="to" :to="to" class="tag">{{ name }}</RouterLink>
  <span v-else class="tag">{{ name }}</span>
</template>
