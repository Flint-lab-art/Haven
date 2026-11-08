import { Extension } from '@tiptap/core'
import type { Node as PMNode } from '@tiptap/pm/model'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import { Decoration, DecorationSet } from '@tiptap/pm/view'
import { copyText, flashCopyState } from '@/utils/clipboard'

const KEY = new PluginKey<DecorationSet>('codeCopy')

function build(doc: PMNode): DecorationSet {
  const decorations: Decoration[] = []

  doc.descendants((node, pos) => {
    if (node.type.name !== 'codeBlock') return true

    decorations.push(
      Decoration.widget(
        pos + 1,
        () => {
          const button = document.createElement('span')
          button.className = 'code-copy'
          button.setAttribute('contenteditable', 'false')
          button.setAttribute('role', 'button')
          button.setAttribute('aria-label', '复制代码')
          button.dataset.state = 'idle'
          button.dataset.pos = String(pos)
          button.textContent = '复制'
          // 不让点击把光标带进代码块
          button.addEventListener('mousedown', (event) => {
            event.preventDefault()
            event.stopPropagation()
          })
          return button
        },
        { side: -1, ignoreSelection: true, key: `code-copy-${pos}` },
      ),
    )
    return false
  })

  return DecorationSet.create(doc, decorations)
}

/**
 * 代码块右上角的复制按钮（编辑态）。
 *
 * 用 widget decoration 生成，按钮不进文档、不参与保存；
 * 行为与阅读态共用 clipboard.ts 的复制与反馈逻辑。
 */
export const CodeCopy = Extension.create({
  name: 'codeCopy',

  addProseMirrorPlugins() {
    return [
      new Plugin<DecorationSet>({
        key: KEY,
        state: {
          init: (_config, state) => build(state.doc),
          apply: (tr, old) => (tr.docChanged ? build(tr.doc) : old),
        },
        props: {
          decorations(state) {
            return KEY.getState(state)
          },
          handleDOMEvents: {
            click: (view, event) => {
              const target = event.target as HTMLElement | null
              const button = target?.closest?.('.code-copy') as HTMLElement | null
              if (!button || !view.dom.contains(button)) return false

              event.preventDefault()
              event.stopPropagation()
              if (button.dataset.state === 'busy') return true

              const pos = Number(button.dataset.pos)
              const node = Number.isFinite(pos) ? view.state.doc.nodeAt(pos) : null
              if (!node) return true

              button.dataset.state = 'busy'
              void copyText(node.textContent).then((ok) => {
                if (view.isDestroyed || !button.isConnected) return
                flashCopyState(button, ok)
              })
              return true
            },
          },
        },
      }),
    ]
  },
})
