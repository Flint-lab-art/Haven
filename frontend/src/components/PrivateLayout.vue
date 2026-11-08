<script setup lang="ts">
/**
 * 私有域三栏布局（ui-design.md 第二节）。
 *
 * 左侧导航固定；中间列表由路由的具名视图 `list` 填充；右侧是默认视图。
 * 布局本身不随路由重建，所以从列表点开笔记时左、中两栏保持不动。
 */
import { computed, ref, watch } from 'vue'
import { RouterView, useRoute, useRouter } from 'vue-router'
import PrivateSidebar from './PrivateSidebar.vue'
import CommandPalette from './CommandPalette.vue'
import { useGlobalShortcuts } from '@/composables/useGlobalShortcuts'
import { useUiStore } from '@/stores/ui'

const route = useRoute()
const router = useRouter()
const ui = useUiStore()

/** 命令面板开关（docs/v6/frontend/frontend.md 第一节）。 */
const paletteOpen = ref(false)

useGlobalShortcuts({
  onTogglePalette: () => {
    paletteOpen.value = !paletteOpen.value
  },
  onNewNote: () => {
    paletteOpen.value = false
    void router.push({ name: 'note-create' })
  },
  // 只有编辑页处理 Cmd+S：取消自动保存计时器并立即保存
  onSave: () => {
    if (route.name !== 'note-detail' && route.name !== 'note-create') return false
    void ui.flushNote()
    return true
  },
})
const list = ref<HTMLElement | null>(null)
const detail = ref<HTMLElement | null>(null)

/**
 * 是否渲染中间列表栏。
 *
 * 首页与标签页是整页内容，不需要列表；路由里用 `meta.noList` 标记。
 * 不给标记的页面（笔记、搜索、作品集等）保持原样。
 */
const showList = computed(() => !route.meta.noList)

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

    <aside v-if="showList" ref="list" class="app__list">
      <RouterView name="list" />
    </aside>

    <main ref="detail" class="app__detail">
      <div class="detail-pane">
        <RouterView />
      </div>
    </main>

    <CommandPalette :open="paletteOpen" @close="paletteOpen = false" />
  </div>
</template>
