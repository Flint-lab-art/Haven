<script setup lang="ts">
/**
 * 文件夹树的一行。
 *
 * 只负责渲染与把交互转成事件；是否展开、拖拽状态、菜单与图标面板的开关
 * 全部由父组件 `NoteListPanel` 持有——这一层没有自己的状态。
 */
import { computed } from 'vue'
import type { Folder } from '@/api/folders'
import { folderIndent, isImageIcon } from '@/utils/tree'
import { BRAND_ICONS, brandColor, type BrandIcon } from '@/utils/brand-icons'

const props = defineProps<{
  folder: Folder
  /** 树深度，决定缩进。 */
  depth: number
  /** 是否展开（决定箭头方向与 aria-expanded）。 */
  expanded: boolean
  /** 是否为当前选中目录。 */
  selected: boolean
  /** 正在拖拽的行（folder:<id>）。 */
  dragging: boolean
  /** 拖放指示：落在本行的上方 / 下方 / 内部。 */
  dropPosition: 'before' | 'after' | 'inside' | null
  /** 正在重命名时显示输入框。 */
  renaming: boolean
  /** 重命名的草稿值（v-model）。 */
  renameDraft: string
}>()

const emit = defineEmits<{
  /** 点击名称：选中并展开直属笔记。 */
  select: []
  /** 折叠 / 展开。 */
  toggle: []
  /** 右键或 ... 按钮。 */
  menu: []
  /** 点击图标按钮：打开图标面板。 */
  'change-icon': []
  /** 在此文件夹新建笔记。 */
  'create-note': []
  /** 新建子文件夹。 */
  'create-child': []
  /** 重命名：进入编辑态。 */
  'start-rename': []
  /** 重命名的回车 / 失焦：提交。 */
  'submit-rename': []
  /** 重命名的 Esc：取消。 */
  'cancel-rename': []
  /** 重命名草稿变化。 */
  'update:renameDraft': [value: string]
  /** 拖拽事件：原样上抛交给父组件的状态机。 */
  dragstart: [event: DragEvent]
  dragover: [event: DragEvent]
  drop: [event: DragEvent]
  dragend: []
}>()

const indent = computed(() => folderIndent(props.depth))

/** 图标是不是品牌 logo 的 key（如 go / python）。 */
function asBrand(icon: string | null | undefined): BrandIcon | undefined {
  if (!icon || isImageIcon(icon)) return undefined
  return BRAND_ICONS.find((it) => it.key === icon)
}

/** 图片加载失败时退回默认图标，不显示破图。 */
function onIconError(event: Event): void {
  ;(event.target as HTMLImageElement).style.display = 'none'
}
</script>

<template>
  <div
    class="tree-row tree-row--folder"
    :class="{
      'tree-row--selected': selected,
      'tree-row--dragging': dragging,
      'tree-row--drop-before': dropPosition === 'before',
      'tree-row--drop-after': dropPosition === 'after',
      'tree-row--drop-inside': dropPosition === 'inside',
    }"
    role="treeitem"
    :aria-expanded="expanded"
    :draggable="!folder.is_inbox"
    :style="{ paddingLeft: indent }"
    @click="emit('select')"
    @contextmenu.prevent="emit('menu')"
    @dragstart="emit('dragstart', $event)"
    @dragover.prevent="emit('dragover', $event)"
    @drop.prevent="emit('drop', $event)"
    @dragend="emit('dragend')"
  >
    <button
      class="tree-toggle"
      type="button"
      :aria-label="expanded ? '折叠文件夹' : '展开文件夹'"
      @click.stop="emit('toggle')"
    >
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        :class="{ 'tree-chevron--open': expanded }"
        aria-hidden="true"
      >
        <path d="m9 6 6 6-6 6" />
      </svg>
    </button>

    <button
      class="tree-icon-btn"
      type="button"
      :title="`更改「${folder.name}」的图标`"
      :aria-label="`更改「${folder.name}」的图标`"
      @click.stop="emit('change-icon')"
    >
      <img
        v-if="isImageIcon(folder.icon)"
        class="tree-icon tree-icon--image"
        :src="folder.icon!"
        alt=""
        aria-hidden="true"
        @error="onIconError"
      />
      <span
        v-else-if="asBrand(folder.icon)"
        class="tree-icon tree-icon--brand"
        :style="{ '--brand-color': brandColor(asBrand(folder.icon)!) }"
        aria-hidden="true"
        v-html="asBrand(folder.icon)!.svg"
      ></span>
      <span v-else-if="folder.icon" class="tree-icon tree-icon--emoji" aria-hidden="true">
        {{ folder.icon }}
      </span>
      <svg
        v-else
        class="tree-icon"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.7"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      </svg>
    </button>

    <input
      v-if="renaming"
      :value="renameDraft"
      class="input tree-rename"
      type="text"
      aria-label="文件夹名"
      @input="emit('update:renameDraft', ($event.target as HTMLInputElement).value)"
      @click.stop
      @keydown.enter.prevent="emit('submit-rename')"
      @keydown.esc.prevent="emit('cancel-rename')"
      @blur="emit('submit-rename')"
    />
    <span v-else class="tree-name">{{ folder.name }}</span>

    <button
      class="icon-btn tree-action"
      type="button"
      title="在此文件夹新建笔记"
      aria-label="在此文件夹新建笔记"
      @click.stop="emit('create-note')"
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
        <path d="M6 3h7l5 5v13H6z" />
        <path d="M13 3v5h5" />
        <path d="M12 12v5M9.5 14.5h5" />
      </svg>
    </button>
    <button
      class="icon-btn tree-action"
      type="button"
      title="新建子文件夹"
      aria-label="新建子文件夹"
      @click.stop="emit('create-child')"
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
        <path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
        <path d="M12 11v5M9.5 13.5h5" />
      </svg>
    </button>
    <button
      class="icon-btn tree-more"
      type="button"
      title="更多操作"
      aria-label="更多操作"
      @click.stop="emit('menu')"
    >
      <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <circle cx="5" cy="12" r="1.6" />
        <circle cx="12" cy="12" r="1.6" />
        <circle cx="19" cy="12" r="1.6" />
      </svg>
    </button>
  </div>
</template>
