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
import { $prose, getMarkdown, replaceAll } from '@milkdown/utils'
import { Plugin, PluginKey, type EditorState, type Transaction } from '@milkdown/prose/state'
import { Decoration, DecorationSet } from '@milkdown/prose/view'
import type { Node as ProseNode } from '@milkdown/prose/model'
import { highlightCode } from '@/utils/highlight'

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
/** 文档是否为空，用于显示占位提示。 */
const empty = ref(!props.modelValue.trim())
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
        empty.value = !markdown.trim()
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
    .use(highlightPlugin())
    .use(activeBlockPlugin())
    .create()

  if (props.autofocus) {
    editor.action((ctx) => {
      ctx.get(editorViewCtx).focus()
    })
  }

  emit('ready')
}

/** highlight.js 输出里的一对标签及其覆盖的文本偏移。 */
interface TokenRange {
  start: number
  end: number
  className: string
}

/**
 * 把 highlight.js 的 HTML 反解析成「纯文本偏移 + class 名」。
 *
 * 不直接用 innerHTML：那会替换文本节点，破坏 ProseMirror 的文档模型。
 * 这里只取每个 <span class="hljs-xxx"> 覆盖的文本区间，再用 Decoration.inline
 * 套同样的 class，文本本身仍由 ProseMirror 管理。
 */
function tokenRanges(html: string): { text: string; ranges: TokenRange[] } {
  const doc = new DOMParser().parseFromString(`<div>${html}</div>`, 'text/html')
  const root = doc.body.firstElementChild
  const ranges: TokenRange[] = []
  let offset = 0

  const walk = (node: Node, classNames: string[]): void => {
    if (node.nodeType === Node.TEXT_NODE) {
      const value = node.nodeValue ?? ''
      if (value && classNames.length) {
        const className = classNames.filter((c) => c.startsWith('hljs-')).join(' ')
        if (className) {
          ranges.push({ start: offset, end: offset + value.length, className })
        }
      }
      offset += value.length
      return
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return
    const el = node as HTMLElement
    const next = el.className ? [...classNames, ...el.className.split(/\s+/)] : classNames
    el.childNodes.forEach((child) => walk(child, next))
  }

  root?.childNodes.forEach((child) => walk(child, []))
  return { text: root?.textContent ?? '', ranges }
}

/**
 * 代码块语法高亮。
 *
 * 用 inline decoration 给代码块里的 token 套 hljs class；
 * 文档内容保持纯文本，编辑与保存完全不受影响。
 */
function highlightPlugin() {
  const key = new PluginKey('code-highlight')

  const build = (doc: ProseNode): DecorationSet => {
    const decorations: Decoration[] = []

    doc.descendants((node: ProseNode, pos: number) => {
      if (node.type.name !== 'code_block' && node.type.name !== 'fence') return true

      const language = (node.attrs.language as string | undefined) ?? ''
      const raw = node.textContent
      if (!raw) return true

      const { ranges } = tokenRanges(highlightCode(raw, language))
      for (const range of ranges) {
        if (range.start >= range.end) continue
        decorations.push(
          Decoration.inline(pos + 1 + range.start, pos + 1 + range.end, {
            class: range.className,
          }),
        )
      }
      return false
    })

    return DecorationSet.create(doc, decorations)
  }

  const plugin = new Plugin<DecorationSet>({
    key,
    state: {
      init: (_config, state: EditorState) => build(state.doc),
      apply: (tr: Transaction, old: DecorationSet) => (tr.docChanged ? build(tr.doc) : old),
    },
    props: {
      decorations(state: EditorState) {
        return key.getState(state)
      },
    },
  })

  return $prose(() => plugin)
}

/**
 * 当前段落高亮。
 *
 * 光标所在的那一个顶层块（段落、标题、列表项等）加一层极淡的背景，
 * 帮助在长文里定位。用 node decoration 而不是改 DOM，文档内容不受影响。
 *
 * 选区跨多个块时不加高亮——那时「当前段落」没有意义。
 */
function activeBlockPlugin() {
  const key = new PluginKey('active-block')

  /** 光标所在块的起始位置；选区跨越多个块时返回 null。 */
  const resolveBlockPos = (state: EditorState): number | null => {
    const { selection } = state
    const { $from, $to } = selection
    // 顶层块的直接子节点；$from.depth > 0 表示在某个块内部
    if ($from.depth === 0) return null
    const fromBlock = $from.before(1)
    const toBlock = $to.before(1)
    if (fromBlock !== toBlock) return null
    return fromBlock
  }

  const build = (state: EditorState): DecorationSet => {
    const pos = resolveBlockPos(state)
    if (pos === null) return DecorationSet.empty
    const node = state.doc.nodeAt(pos)
    if (!node) return DecorationSet.empty

    // 代码块自带底色，再叠一层会脏，跳过
    if (node.type.name === 'code_block' || node.type.name === 'fence') {
      return DecorationSet.empty
    }

    const decoration = Decoration.node(pos, pos + node.nodeSize, {
      class: 'is-active-block',
    })
    return DecorationSet.create(state.doc, [decoration])
  }

  const plugin = new Plugin<DecorationSet>({
    key,
    state: {
      init: (_config, state: EditorState) => build(state),
      // 只在选区或文档变化时重建，避免每次按键都全量扫描
      apply: (tr: Transaction, old: DecorationSet, _oldState: EditorState, newState: EditorState) =>
        tr.selectionSet || tr.docChanged ? build(newState) : old,
    },
    props: {
      decorations(state: EditorState) {
        return key.getState(state)
      },
    },
  })

  return $prose(() => plugin)
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

/** 当前文档里的 H1–H3 元素，按文档顺序排列，供右侧大纲定位。 */
function headingElements(): HTMLElement[] {
  if (!container.value) return []
  return Array.from(container.value.querySelectorAll<HTMLElement>('h1, h2, h3'))
}

/** 滚动到第 index 个标题（0 基，对应 headingElements 的顺序）。 */
function scrollToHeading(index: number): void {
  headingElements()[index]?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

defineExpose({ sync, headingElements, scrollToHeading })

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
    <div ref="container" class="editor-surface milkdown" :data-empty="empty ? 'true' : 'false'"></div>
  </div>
</template>
