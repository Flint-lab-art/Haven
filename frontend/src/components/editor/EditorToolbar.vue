<script setup lang="ts">
/**
 * 固定极简工具栏（docs-ai/v7/frontend/ui-design.md 7.5.1）。
 *
 * 只放图标 / 短标签，所有动作走 TipTap 的 chain().focus()，
 * 不直接改 DOM。按钮的选中态统一用 editor.isActive() 判断。
 */
import { ref } from 'vue'
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
        <strong>B</strong>
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="斜体"
        :class="{ 'is-active': editor.isActive('italic') }"
        @mousedown.prevent
        @click="chain().toggleItalic().run()"
      >
        <em>I</em>
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="删除线"
        :class="{ 'is-active': editor.isActive('strike') }"
        @mousedown.prevent
        @click="chain().toggleStrike().run()"
      >
        <s>S</s>
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="行内代码"
        :class="{ 'is-active': editor.isActive('code') }"
        @mousedown.prevent
        @click="chain().toggleCode().run()"
      >
        &lt;&gt;
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

    <div class="editor-toolbar__group">
      <button
        type="button"
        class="tb-btn"
        title="左对齐"
        :class="{ 'is-active': editor.isActive({ textAlign: 'left' }) }"
        @mousedown.prevent
        @click="chain().setTextAlign('left').run()"
      >
        ⬅
      </button>
      <button
        type="button"
        class="tb-btn"
        title="居中"
        :class="{ 'is-active': editor.isActive({ textAlign: 'center' }) }"
        @mousedown.prevent
        @click="chain().setTextAlign('center').run()"
      >
        ↔
      </button>
      <button
        type="button"
        class="tb-btn"
        title="右对齐"
        :class="{ 'is-active': editor.isActive({ textAlign: 'right' }) }"
        @mousedown.prevent
        @click="chain().setTextAlign('right').run()"
      >
        ➡
      </button>
    </div>

    <span class="editor-toolbar__sep" />

    <div class="editor-toolbar__group">
      <button
        type="button"
        class="tb-btn"
        title="无序列表"
        :class="{ 'is-active': editor.isActive('bulletList') }"
        @mousedown.prevent
        @click="chain().toggleBulletList().run()"
      >
        • 列表
      </button>
      <button
        type="button"
        class="tb-btn"
        title="有序列表"
        :class="{ 'is-active': editor.isActive('orderedList') }"
        @mousedown.prevent
        @click="chain().toggleOrderedList().run()"
      >
        1. 列表
      </button>
      <button
        type="button"
        class="tb-btn"
        title="任务列表"
        :class="{ 'is-active': editor.isActive('taskList') }"
        @mousedown.prevent
        @click="chain().toggleTaskList().run()"
      >
        ☑ 任务
      </button>
      <button
        type="button"
        class="tb-btn"
        title="引用"
        :class="{ 'is-active': editor.isActive('blockquote') }"
        @mousedown.prevent
        @click="chain().toggleBlockquote().run()"
      >
        引用
      </button>
    </div>

    <span class="editor-toolbar__sep" />

    <div class="editor-toolbar__group">
      <button
        type="button"
        class="tb-btn"
        title="代码块"
        :class="{ 'is-active': editor.isActive('codeBlock') }"
        @mousedown.prevent
        @click="chain().toggleCodeBlock().run()"
      >
        代码块
      </button>
      <button
        type="button"
        class="tb-btn"
        title="插入表格"
        @mousedown.prevent
        @click="chain().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()"
      >
        表格
      </button>
      <button
        type="button"
        class="tb-btn"
        title="插入折叠块"
        @mousedown.prevent
        @click="chain().setDetails().run()"
      >
        折叠
      </button>
      <button
        type="button"
        class="tb-btn"
        title="插入图片"
        @mousedown.prevent
        @click="pickImage(editor)"
      >
        图片
      </button>
      <button
        type="button"
        class="tb-btn"
        title="分割线"
        @mousedown.prevent
        @click="chain().setHorizontalRule().run()"
      >
        —
      </button>
    </div>
  </div>
</template>
