<script setup lang="ts">
/**
 * 所见即所得富文本编辑器（TipTap）。
 *
 * 依据 docs-ai/v7/frontend/frontend.md：
 * - 正文保存 `editor.getHTML()`；不再有 Milkdown 的 sync() / markdownUpdated；
 * - 扩展注册顺序与配置固定（CodeBlockLowlight 必须关掉 StarterKit 的 codeBlock）；
 * - 图片粘贴 / 拖拽走上传，正文只存相对 URL；
 * - 字数统计显示在编辑器底部。
 */
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { EditorContent, useEditor } from '@tiptap/vue-3'
import type { Editor } from '@tiptap/vue-3'
import { BubbleMenu } from '@tiptap/vue-3/menus'
import StarterKit from '@tiptap/starter-kit'
import { Color, TextStyle } from '@tiptap/extension-text-style'
import { Highlight } from '@tiptap/extension-highlight'
import { TextAlign } from '@tiptap/extension-text-align'
import { Typography } from '@tiptap/extension-typography'
import { CharacterCount, Placeholder } from '@tiptap/extensions'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import { createLowlight, common } from 'lowlight'
import { TaskList } from '@tiptap/extension-task-list'
import { TaskItem } from '@tiptap/extension-task-item'
import { Table, TableCell, TableHeader, TableRow } from '@tiptap/extension-table'
import { Image } from '@tiptap/extension-image'
import { Details, DetailsContent, DetailsSummary } from '@tiptap/extension-details'
import EditorToolbar from './EditorToolbar.vue'
import { CodeCopy } from '@/utils/tiptap-code-copy'
import { SlashCommand } from '@/utils/slash-command'
import { insertImageFiles } from '@/utils/editor-image'
import { isUploadableImage } from '@/api/uploads'

const props = defineProps<{
  modelValue: string
  autofocus?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  /** 编辑器就绪，父组件可以主动同步一次内容。 */
  ready: []
}>()

const lowlight = createLowlight(common)

const container = ref<HTMLDivElement | null>(null)
const characterCount = ref(0)
/** 回填内容时避免把程序化变更当成用户输入再抛出去。 */
let applyingExternal = false
/** 供 editorProps 里的异步回调使用，避免在 useEditor 初始化表达式里引用自身。 */
let editorInstance: Editor | undefined

const editor = useEditor({
  content: props.modelValue,
  extensions: [
    StarterKit.configure({ codeBlock: false }),
    TextStyle,
    Color,
    Highlight.configure({ multicolor: true }),
    TextAlign.configure({ types: ['heading', 'paragraph'] }),
    Typography,
    Placeholder.configure({ placeholder: '开始写作…' }),
    CodeBlockLowlight.configure({
      lowlight,
      HTMLAttributes: { class: 'hljs' },
    }),
    TaskList,
    TaskItem.configure({ nested: true }),
    Table.configure({ resizable: false }),
    TableRow,
    TableCell,
    TableHeader,
    Image.configure({ allowBase64: false }),
    Details,
    DetailsContent,
    DetailsSummary,
    CharacterCount,
    CodeCopy,
    SlashCommand,
  ],
  editorProps: {
    attributes: { class: 'tiptap' },
    handlePaste(_view, event) {
      return handleImageFiles(event.clipboardData?.files)
    },
    handleDrop(view, event, _slice, moved) {
      // 编辑器内部的拖动交给 TipTap，不要当成文件上传
      if (moved) return false
      const files = Array.from(event.dataTransfer?.files ?? [])
      if (!files.some(isUploadableImage)) return false
      event.preventDefault()
      const pos = view.posAtCoords({ left: event.clientX, top: event.clientY })?.pos
      if (editorInstance) void insertImageFiles(editorInstance, files, pos)
      return true
    },
  },
  onUpdate: ({ editor: instance }) => {
    characterCount.value = instance.storage.characterCount.characters()
    if (applyingExternal) return
    emit('update:modelValue', instance.getHTML())
  },
})

function handleImageFiles(list: FileList | undefined | null): boolean {
  if (!list) return false
  const files = Array.from(list)
  if (!files.some(isUploadableImage)) return false
  // handlePaste 里没有 preventDefault 的句柄，返回 true 即由 TipTap 接管；
  // 这里异步上传，上传期间编辑器保持原样。
  const instance = editor.value
  if (instance) void insertImageFiles(instance, files)
  return true
}

watch(
  editor,
  (instance) => {
    if (!instance) return
    editorInstance = instance
    characterCount.value = instance.storage.characterCount.characters()
    if (props.autofocus) {
      void nextTick(() => instance.commands.focus())
    }
    emit('ready')
  },
  { immediate: true },
)

// 外部值变化（切换笔记、版本还原）时整体替换。
watch(
  () => props.modelValue,
  (next) => {
    const instance = editor.value
    if (!instance) return
    if (instance.getHTML() === next) return

    applyingExternal = true
    instance.commands.setContent(next || '', { emitUpdate: false })
    characterCount.value = instance.storage.characterCount.characters()
    void nextTick(() => {
      applyingExternal = false
    })
  },
)

/**
 * 主动把编辑器当前 HTML 交回给父组件。
 *
 * TipTap 的 onUpdate 是异步派发的；保存前调用一次 sync，
 * 避免刚打完字立刻点保存时存进上一拍的内容。
 */
function sync(): void {
  if (!editor.value) return
  emit('update:modelValue', editor.value.getHTML())
}

function headingElements(): HTMLElement[] {
  if (!container.value) return []
  return Array.from(container.value.querySelectorAll<HTMLElement>('.tiptap h1, .tiptap h2, .tiptap h3'))
}

function scrollToHeading(index: number): void {
  headingElements()[index]?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

const count = computed(() => characterCount.value)

/** BubbleMenu 挂到 body，避免被 .editor-shell 的 overflow 裁掉。 */
const appendToBody = (): HTMLElement => document.body

function withEditor(action: (instance: Editor) => void): void {
  const instance = editor.value
  if (instance) action(instance)
}

function toggleBold(): void {
  withEditor((instance) => instance.chain().focus().toggleBold().run())
}

function toggleItalic(): void {
  withEditor((instance) => instance.chain().focus().toggleItalic().run())
}

function toggleStrike(): void {
  withEditor((instance) => instance.chain().focus().toggleStrike().run())
}

function toggleCode(): void {
  withEditor((instance) => instance.chain().focus().toggleCode().run())
}

function toggleHighlight(): void {
  withEditor((instance) => instance.chain().focus().toggleHighlight().run())
}

function setLink(): void {
  withEditor((instance) => {
    const href = window.prompt('链接地址')
    if (href) instance.chain().focus().setLink({ href }).run()
  })
}

const active = {
  bold: computed(() => editor.value?.isActive('bold') ?? false),
  italic: computed(() => editor.value?.isActive('italic') ?? false),
  strike: computed(() => editor.value?.isActive('strike') ?? false),
  code: computed(() => editor.value?.isActive('code') ?? false),
  highlight: computed(() => editor.value?.isActive('highlight') ?? false),
  link: computed(() => editor.value?.isActive('link') ?? false),
}

defineExpose({ sync, headingElements, scrollToHeading })

onMounted(() => {
  if (props.autofocus && editor.value) void nextTick(() => editor.value?.commands.focus())
})
</script>

<template>
  <div class="editor-shell">
    <EditorToolbar v-if="editor" :editor="editor" />

    <div ref="container" class="editor-surface">
      <EditorContent v-if="editor" :editor="editor" />
    </div>

    <div class="editor-footer">
      <span class="editor-char-count">{{ count }} 字符</span>
    </div>

    <BubbleMenu
      v-if="editor"
      :editor="editor"
      :options="{ placement: 'top', offset: 8 }"
      :append-to="appendToBody"
      class="editor-bubble"
    >
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="加粗"
        :class="{ 'is-active': active.bold.value }"
        @mousedown.prevent
        @click="toggleBold"
      >
        <strong>B</strong>
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="斜体"
        :class="{ 'is-active': active.italic.value }"
        @mousedown.prevent
        @click="toggleItalic"
      >
        <em>I</em>
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="删除线"
        :class="{ 'is-active': active.strike.value }"
        @mousedown.prevent
        @click="toggleStrike"
      >
        <s>S</s>
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="行内代码"
        :class="{ 'is-active': active.code.value }"
        @mousedown.prevent
        @click="toggleCode"
      >
        &lt;&gt;
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="高亮"
        :class="{ 'is-active': active.highlight.value }"
        @mousedown.prevent
        @click="toggleHighlight"
      >
        H
      </button>
      <button
        type="button"
        class="tb-btn tb-btn--icon"
        title="链接"
        :class="{ 'is-active': active.link.value }"
        @mousedown.prevent
        @click="setLink"
      >
        链
      </button>
    </BubbleMenu>
  </div>
</template>
