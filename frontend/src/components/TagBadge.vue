<script setup lang="ts">
/** 标签徽章：可点击时跳搜索，否则纯展示。 */
import { RouterLink } from 'vue-router'

withDefaults(
  defineProps<{
    name: string
    /** 传入则渲染为可点击的标签链。 */
    to?: string
  }>(),
  { to: undefined },
)
</script>

<template>
  <RouterLink v-if="to" :to="to" class="tag">{{ name }}</RouterLink>
  <span v-else class="tag">{{ name }}</span>
</template>
