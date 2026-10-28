<script setup lang="ts">
/**
 * 所见即所得 Markdown 编辑器（Milkdown）。
 *
 * 存储格式仍是 Markdown 原文：编辑器内部是 ProseMirror 文档，
 * 通过 listener 的 markdownUpdated 同步回 markdown 字符串。
 *
 * 主题沿用站点样式（不引入 Nordic 主题），见 style.css 的 .milkdown 段。
 */
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { Editor, rootCtx, defaultValueCtx, editorViewCtx } from '@milkdown/core'
import { commonmark } from '@milkdown/preset-commonmark'
import { gfm } from '@milkdown/preset-gfm'
import { history } from '@milkdown/plugin-history'
import { listener, listenerCtx } from '@milkdown/plugin-listener'
import { clipboard } from '@milkdown/plugin-clipboard'
import { cursor } from '@milkdown/plugin-cursor'
import { trailing } from '@milkdown/plugin-trailing'
import { getMarkdown, replaceAll } from '@milkdown/utils'

const props = defineProps<{
  modelValue: string
  autofocus?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  /** 编辑器就绪，父组件可以主动同步一次内容。 */
  ready: []
}>()

const container = ref<HTMLDivElement | null>(null)
let editor: Editor | undefined
/** 回填内容时避免把程序化变更当成用户输入再抛出去。 */
let applyingExternal = false

async function build(): Promise<void> {
  if (!container.value) return

  editor = await Editor.make()
    .config((ctx) => {
      ctx.set(rootCtx, container.value!)
      ctx.set(defaultValueCtx, props.modelValue)
      ctx.get(listenerCtx).markdownUpdated((_ctx, markdown) => {
        if (applyingExternal) return
        emit('update:modelValue', markdown)
      })
    })
    .use(commonmark)
    .use(gfm)
    .use(history)
    // 粘贴 Markdown 时解析成对应块（否则会把 # 和 ** 当纯文本插进来）
    .use(clipboard)
    // 光标：划单词高亮、按住拖动选择等基础行为
    .use(cursor)
    // 文档末尾补一个空段落，方便在文末继续输入
    .use(trailing)
    .use(listener)
    .create()

  if (props.autofocus) {
    editor.action((ctx) => {
      ctx.get(editorViewCtx).focus()
    })
  }

  emit('ready')
}

/**
 * 主动把编辑器当前内容交回给父组件。
 *
 * markdownUpdated 是异步派发的：用户打完字立刻点保存时，父组件手里的
 * v-model 可能还是上一拍的值。保存前调用一次 sync，避免存进旧内容。
 */
function sync(): void {
  if (!editor) return
  emit('update:modelValue', editor.action(getMarkdown()))
}

defineExpose({ sync })

onMounted(build)

onBeforeUnmount(async () => {
  await editor?.destroy()
  editor = undefined
})

// 外部值变化（例如切换笔记、撤销后回填）时整体替换
watch(
  () => props.modelValue,
  (next) => {
    if (!editor) return
    // 内容一致时不重建，避免光标跳动
    const current = editor.action(getMarkdown())
    if (current === next) return

    applyingExternal = true
    editor.action(replaceAll(next, true))
    queueMicrotask(() => {
      applyingExternal = false
    })
  },
)
</script>

<template>
  <div class="editor-shell">
    <div ref="container" class="editor-surface milkdown"></div>
  </div>
</template>
