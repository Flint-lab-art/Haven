<script setup lang="ts">
/** 右侧未选中任何条目时的极简空状态。文案由路由 meta 提供。 */
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const title = computed(() => String(route.meta.emptyTitle ?? '选择一篇笔记'))
const text = computed(() => String(route.meta.emptyText ?? '从左侧列表选择，或新建一篇。'))
</script>

<template>
  <div class="detail-empty">
    <p class="detail-empty__title">{{ title }}</p>
    <p class="detail-empty__text">{{ text }}</p>
  </div>
</template>
