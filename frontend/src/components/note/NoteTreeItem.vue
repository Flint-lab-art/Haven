<script setup lang="ts">
/**
 * 笔记树的一行。
 *
 * 和 `FolderTreeNode` 一样只做渲染与事件转发：点击跳转、拖拽状态、
 * 发布/删除的忙碌态都由父组件决定。组件本身无状态。
 */
import { computed } from 'vue'
import type { NoteSummary } from '@/api/notes'
import { noteIndent } from '@/utils/tree'

const props = defineProps<{
  note: NoteSummary
  /** 树深度，决定缩进。 */
  depth: number
  /** 是否为当前打开的笔记。 */
  active: boolean
  /** 正在拖拽的行。 */
  dragging: boolean
  /** 拖放指示：落在本行的上方 / 下方。 */
  dropPosition: 'before' | 'after' | null
  /** 发布 / 撤回进行中时禁用行内按钮。 */
  busy: boolean
}>()

const emit = defineEmits<{
  /** 打开笔记。 */
  open: []
  /** 切换公开 / 私有。 */
  'toggle-visibility': []
  /** 删除笔记。 */
  remove: []
  dragstart: [event: DragEvent]
  dragover: [event: DragEvent]
  drop: [event: DragEvent]
  dragend: []
}>()

const indent = computed(() => noteIndent(props.depth))
const isPublic = computed(() => props.note.visibility === 'public')
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
    <svg
      class="tree-icon"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.7"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <path d="M6 3h7l5 5v13H6z" />
      <path d="M13 3v5h5" />
    </svg>
    <span class="tree-name">{{ note.title }}</span>

    <button
      class="icon-btn tree-action"
      type="button"
      :title="isPublic ? '撤回为私有' : '公开'"
      :aria-label="isPublic ? '撤回为私有' : '公开'"
      :disabled="busy"
      @click.stop="emit('toggle-visibility')"
    >
      <svg
        v-if="isPublic"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.7"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <rect x="5" y="10" width="14" height="10" rx="2" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3" />
      </svg>
      <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true">
        <circle cx="12" cy="12" r="9" />
        <path d="M3 12h18M12 3c2.5 2.4 3.8 5.6 3.8 9S14.5 18.6 12 21c-2.5-2.4-3.8-5.6-3.8-9S9.5 5.4 12 3z" />
      </svg>
    </button>

    <button
      class="icon-btn tree-action tree-action--danger"
      type="button"
      title="删除笔记"
      aria-label="删除笔记"
      :disabled="busy"
      @click.stop="emit('remove')"
    >
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.7"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <path d="M4 7h16" />
        <path d="M9 7V4h6v3" />
        <path d="M6 7l1 13h10l1-13" />
        <path d="M10 11v6M14 11v6" />
      </svg>
    </button>
  </div>
</template>
