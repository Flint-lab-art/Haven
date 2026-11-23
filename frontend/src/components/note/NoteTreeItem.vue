<script setup lang="ts">
/**
 * 笔记树的一行。
 *
 * 和 `FolderTreeNode` 一样只做渲染与事件转发：点击跳转、拖拽状态、
 * 删除的忙碌态都由父组件决定。组件本身无状态。
 */
import { computed } from 'vue'
import type { NoteSummary } from '@/api/notes'
import { noteIndent } from '@/utils/tree'
import { FileText, Trash2 } from 'lucide-vue-next'


const props = withDefaults(
  defineProps<{
    note: NoteSummary
    /** 树深度，决定缩进。 */
    depth: number
    /** 是否为当前打开的笔记。 */
    active: boolean
    /** 正在拖拽的行。 */
    dragging: boolean
    /** 拖放指示：落在本行的上方 / 下方。 */
    dropPosition: 'before' | 'after' | null
    /** 删除进行中时禁用行内按钮。 */
    busy?: boolean
  }>(),
  { busy: false },
)

const emit = defineEmits<{
  /** 打开笔记。 */
  open: []
  /** 删除笔记。 */
  remove: []
  dragstart: [event: DragEvent]
  dragover: [event: DragEvent]
  drop: [event: DragEvent]
  dragend: []
}>()

const indent = computed(() => noteIndent(props.depth))
</script>

<template>
  <div
    class="tree-row tree-row--note"
    :class="{
      'tree-row--active': active,
      'tree-row--dragging': dragging,
      'tree-row--drop-before': dropPosition === 'before',
      'tree-row--drop-after': dropPosition === 'after',
    }"
    role="treeitem"
    tabindex="0"
    draggable="true"
    :style="{ paddingLeft: indent }"
    @click="emit('open')"
    @keydown.enter.self.prevent="emit('open')"
    @dragstart="emit('dragstart', $event)"
    @dragover.prevent="emit('dragover', $event)"
    @drop.prevent="emit('drop', $event)"
    @dragend="emit('dragend')"
  >
    <FileText class="tree-icon" aria-hidden="true" />
    <span class="tree-name">{{ note.title }}</span>

    <button
      class="icon-btn tree-action tree-action--danger"
      type="button"
      title="删除笔记"
      aria-label="删除笔记"
      :disabled="busy"
      @click.stop="emit('remove')"
    >
      <Trash2 aria-hidden="true" />
    </button>
  </div>
</template>
