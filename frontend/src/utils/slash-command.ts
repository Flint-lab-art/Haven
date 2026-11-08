import { Extension, type Editor } from '@tiptap/core'
import Suggestion, {
  type SuggestionKeyDownProps,
  type SuggestionOptions,
  type SuggestionProps,
} from '@tiptap/suggestion'
import { VueRenderer } from '@tiptap/vue-3'
import {
  computePosition,
  flip,
  offset,
  shift,
  type VirtualElement,
} from '@floating-ui/dom'
import EditorSlashMenu from '@/components/EditorSlashMenu.vue'
import { pickImage } from './editor-image'

export interface SlashItem {
  title: string
  hint: string
  aliases: string[]
  run: (editor: Editor) => void
}

const ITEMS: SlashItem[] = [
  {
    title: '正文',
    hint: '普通段落',
    aliases: ['text', 'p'],
    run: (editor) => editor.chain().focus().setParagraph().run(),
  },
  {
    title: '一级标题',
    hint: 'H1',
    aliases: ['h1', 'heading', 'title'],
    run: (editor) => editor.chain().focus().toggleHeading({ level: 1 }).run(),
  },
  {
    title: '二级标题',
    hint: 'H2',
    aliases: ['h2', 'heading'],
    run: (editor) => editor.chain().focus().toggleHeading({ level: 2 }).run(),
  },
  {
    title: '三级标题',
    hint: 'H3',
    aliases: ['h3', 'heading'],
    run: (editor) => editor.chain().focus().toggleHeading({ level: 3 }).run(),
  },
  {
    title: '无序列表',
    hint: '列表',
    aliases: ['ul', 'list', 'bullet'],
    run: (editor) => editor.chain().focus().toggleBulletList().run(),
  },
  {
    title: '有序列表',
    hint: '1. 2. 3.',
    aliases: ['ol', 'number', 'ordered'],
    run: (editor) => editor.chain().focus().toggleOrderedList().run(),
  },
  {
    title: '任务列表',
    hint: '可勾选',
    aliases: ['task', 'todo', 'check'],
    run: (editor) => editor.chain().focus().toggleTaskList().run(),
  },
  {
    title: '引用',
    hint: 'blockquote',
    aliases: ['quote', 'blockquote'],
    run: (editor) => editor.chain().focus().toggleBlockquote().run(),
  },
  {
    title: '代码块',
    hint: '带高亮',
    aliases: ['code', 'pre'],
    run: (editor) => editor.chain().focus().toggleCodeBlock().run(),
  },
  {
    title: '表格',
    hint: '3 × 3',
    aliases: ['table', 'grid'],
    run: (editor) =>
      editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run(),
  },
  {
    title: '折叠块',
    hint: 'details',
    aliases: ['details', 'toggle', 'fold'],
    run: (editor) => editor.chain().focus().setDetails().run(),
  },
  {
    title: '图片',
    hint: '上传',
    aliases: ['image', 'img', 'picture'],
    run: (editor) => pickImage(editor),
  },
  {
    title: '分割线',
    hint: 'hr',
    aliases: ['hr', 'divider', 'line'],
    run: (editor) => editor.chain().focus().setHorizontalRule().run(),
  },
]

export function filterSlashItems(query: string): SlashItem[] {
  const q = query.trim().toLowerCase()
  if (!q) return ITEMS
  return ITEMS.filter(
    (item) =>
      item.title.toLowerCase().includes(q) ||
      item.aliases.some((alias) => alias.includes(q)),
  )
}

/** 把斜杠菜单挂到编辑器上（docs-ai/v7/frontend/frontend.md 第五节）。 */
export const SlashCommand = Extension.create({
  name: 'slashCommand',

  addOptions() {
    return {
      suggestion: {
        char: '/',
        startOfLine: true,
        allowSpaces: false,
        items: ({ query }: { query: string }) => filterSlashItems(query),
        command: ({
          editor,
          range,
          props,
        }: {
          editor: Editor
          range: { from: number; to: number }
          props: SlashItem
        }) => {
          editor.chain().focus().deleteRange(range).run()
          props.run(editor)
        },
        render: () => {
          let component: VueRenderer | null = null

          const destroy = (): void => {
            const el = component?.element as HTMLElement | null
            component?.destroy()
            component = null
            el?.remove()
          }

          const position = (props: SuggestionProps<SlashItem>): void => {
            const rect = props.clientRect?.()
            if (!rect || !component?.element) return

            const virtual: VirtualElement = {
              getBoundingClientRect: () => rect,
            }

            void computePosition(virtual, component.element as HTMLElement, {
              placement: 'bottom-start',
              strategy: 'fixed',
              middleware: [offset(8), flip(), shift({ padding: 8 })],
            }).then(({ x, y }) => {
              const el = component?.element as HTMLElement | null
              if (!el) return
              el.style.left = `${x}px`
              el.style.top = `${y}px`
            })
          }

          return {
            onStart: (props: SuggestionProps<SlashItem>) => {
              destroy()
              component = new VueRenderer(EditorSlashMenu, {
                props,
                editor: props.editor,
              })
              const el = component.element as HTMLElement | null
              if (el) {
                el.style.position = 'fixed'
                el.style.zIndex = '60'
                document.body.appendChild(el)
              }
              position(props)
            },
            onUpdate: (props: SuggestionProps<SlashItem>) => {
              component?.updateProps(props)
              position(props)
            },
            onKeyDown: (props: SuggestionKeyDownProps) => {
              if (props.event.key === 'Escape') {
                destroy()
                return true
              }
              return Boolean(
                (component?.ref as { onKeyDown?: (event: KeyboardEvent) => boolean } | null)
                  ?.onKeyDown?.(props.event),
              )
            },
            onExit: () => {
              destroy()
            },
          }
        },
      } as unknown as SuggestionOptions<SlashItem>,
    }
  },

  addProseMirrorPlugins() {
    return [Suggestion({ ...this.options.suggestion, editor: this.editor })]
  },
})
