<script setup lang="ts">
/**
 * 固定极简工具栏（docs-ai/v7/frontend/ui-design.md 7.5.1）。
 *
 * 只放图标 / 短标签，所有动作走 TipTap 的 chain().focus()，
 * 不直接改 DOM。按钮的选中态统一用 editor.isActive() 判断。
 */
import { ref, type Component } from 'vue'
import {
  AlignCenter,
  AlignLeft,
  AlignRight,
  Bold,
  ChevronsUpDown,
  CodeXml,
  Image,
  Italic,
  List,
  ListChecks,
  ListOrdered,
  Minus,
  Quote,
  Strikethrough,
  Table,
} from 'lucide-vue-next'
import type { Editor } from '@tiptap/vue-3'
import { pickImage } from '@/utils/editor-image'

const props = defineProps<{ editor: Editor }>()

const colorInput = ref<HTMLInputElement | null>(null)

function chain() {
  return props.editor.chain().focus()
}

function toggleHeading(level: 1 | 2 | 3): void {
  chain().toggleHeading({ level }).run()
}

function setColor(event: Event): void {
  const value = (event.target as HTMLInputElement).value
  chain().setColor(value).run()
}

function pickColor(): void {
  colorInput.value?.click()
}

/**
 * 图标动作表：工具栏右半段的纯图标按钮。
 *
 * 用一张表而不是 13 段重复模板——新增一个动作只需要加一行，
 * 标题同时作为 title / aria-label，占位与尺寸由 .tb-btn--icon 统一。
 */
type IconAction = {
  title: string
  icon: Component
  run: () => void
  active?: () => boolean
}

const iconActions: IconAction[] = [
  { title: '左对齐', icon: AlignLeft, run: () => chain().setTextAlign('left').run(), active: () => props.editor.isActive({ textAlign: 'left' }) },
  { title: '居中', icon: AlignCenter, run: () => chain().setTextAlign('center').run(), active: () => props.editor.isActive({ textAlign: 'center' }) },
  { title: '右对齐', icon: AlignRight, run: () => chain().setTextAlign('right').run(), active: () => props.editor.isActive({ textAlign: 'right' }) },
  { title: '无序列表', icon: List, run: () => chain().toggleBulletList().run(), active: () => props.editor.isActive('bulletList') },
  { title: '有序列表', icon: ListOrdered, run: () => chain().toggleOrderedList().run(), active: () => props.editor.isActive('orderedList') },
  { title: '任务列表', icon: ListChecks, run: () => chain().toggleTaskList().run(), active: () => props.editor.isActive('taskList') },
  { title: '引用', icon: Quote, run: () => chain().toggleBlockquote().run(), active: () => props.editor.isActive('blockquote') },
  { title: '代码块', icon: CodeXml, run: () => chain().toggleCodeBlock().run(), active: () => props.editor.isActive('codeBlock') },
  { title: '插入表格', icon: Table, run: () => chain().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run() },
  { title: '插入折叠块', icon: ChevronsUpDown, run: () => chain().setDetails().run() },
  { title: '插入图片', icon: Image, run: () => void pickImage(props.editor) },
  { title: '分割线', icon: Minus, run: () => chain().setHorizontalRule().run() },
]
</script>

<template>
  <div class="editor-toolbar" role="toolbar" aria-label="格式">
    <div class="editor-toolbar__group">
      <button
        type="button"
        class="tb-btn"
        title="正文"
        :class="{ 'is-active': editor.isActive('paragraph') }"
        @mousedown.prevent
        @click="chain().setParagraph().run()"
      >
        正文
      </button>
      <button
        v-for="level in ([1, 2, 3] as const)"
        :key="level"
        type="button"
        class="tb-btn"
        :title="`${level} 级标题`"
        :class="{ 'is-active': editor.isActive('heading', { level }) }"
        @mousedown.prevent
        @click="toggleHeading(level)"
      >
        H{{ level }}
      </button>
    </div>

    <span class="editor-toolbar__sep" />

    <div class="editor-toolbar__group">
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="加粗"
        :class="{ 'is-active': editor.isActive('bold') }"
        @mousedown.prevent
        @click="chain().toggleBold().run()"
      >
        <Bold aria-hidden="true" />
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="斜体"
        :class="{ 'is-active': editor.isActive('italic') }"
        @mousedown.prevent
        @click="chain().toggleItalic().run()"
      >
        <Italic aria-hidden="true" />
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="删除线"
        :class="{ 'is-active': editor.isActive('strike') }"
        @mousedown.prevent
        @click="chain().toggleStrike().run()"
      >
        <Strikethrough aria-hidden="true" />
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="行内代码"
        :class="{ 'is-active': editor.isActive('code') }"
        @mousedown.prevent
        @click="chain().toggleCode().run()"
      >
        <CodeXml aria-hidden="true" />
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="文字颜色"
        @mousedown.prevent
        @click="pickColor"
      >
        <span class="tb-color-dot" />
      </button>
      <input ref="colorInput" class="tb-color-input" type="color" aria-label="文字颜色" @input="setColor" />
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="高亮"
        :class="{ 'is-active': editor.isActive('highlight') }"
        @mousedown.prevent
        @click="chain().toggleHighlight().run()"
      >
        <span class="tb-highlight-dot">A</span>
      </button>
    </div>

    <span class="editor-toolbar__sep" />

    <!-- 图标按钮：28px 见方，与左侧文字按钮同高；aria-label 兼作无障碍名 -->
    <div class="editor-toolbar__group">
      <button
        v-for="item in iconActions"
        :key="item.title"
        type="button"
        class="tb-btn tb-btn--icon"
        :title="item.title"
        :aria-label="item.title"
        :aria-pressed="item.active ? item.active() : undefined"
        :class="{ 'is-active': item.active ? item.active() : false }"
        @mousedown.prevent
        @click="item.run()"
      >
        <component :is="item.icon" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>
