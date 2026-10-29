<script setup lang="ts">
/**
 * 私有域三栏布局（ui-design.md 第二节）。
 *
 * 左侧导航固定；中间列表由路由的具名视图 `list` 填充；右侧是默认视图。
 * 布局本身不随路由重建，所以从列表点开笔记时左、中两栏保持不动。
 */
import { ref, watch } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import PrivateSidebar from './PrivateSidebar.vue'

const route = useRoute()
const list = ref<HTMLElement | null>(null)
const detail = ref<HTMLElement | null>(null)

// 右侧是独立滚动容器：路由切换后回到顶部，避免沿用上一篇的滚动位置
watch(
  () => route.fullPath,
  () => detail.value?.scrollTo({ top: 0 }),
)

// 切换到另一个分区（笔记 / 搜索 / 标签…）时，中间列表也回到顶部
watch(
  () => route.meta.section,
  () => list.value?.scrollTo({ top: 0 }),
)
</script>

<template>
  <div class="app">
    <PrivateSidebar />

    <aside ref="list" class="app__list">
      <RouterView name="list" />
    </aside>

    <main ref="detail" class="app__detail">
      <div class="detail-pane">
        <RouterView />
      </div>
    </main>
  </div>
</template>
