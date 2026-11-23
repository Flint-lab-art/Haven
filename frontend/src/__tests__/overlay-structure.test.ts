import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { defineComponent, h, nextTick } from 'vue'
import { readFileSync } from 'node:fs'
import path from 'node:path'
import {
  DialogContent,
  DialogOverlay,
  DialogPortal,
  DialogRoot,
} from 'reka-ui'

/**
 * 守住一条结构契约：弹层内容必须自己定位，不能指望遮罩当父容器。
 *
 * Reka 把 Overlay 和 Content 平级挂在 body 下。之前我们沿用了「遮罩包内容」
 * 的写法（`display: grid; place-items: center`），结果内容不居中、还被
 * `z-index: 100` 的遮罩整块盖住——表现是整页变灰、点不动。
 */

// jsdom 不加载项目的 style.css，这里显式注入后按选择器查规则。
const styleSource = readFileSync(path.resolve(process.cwd(), 'src/style.css'), 'utf8')

function ensureStyles(): void {
  if (document.getElementById('haven-style')) return
  const style = document.createElement('style')
  style.id = 'haven-style'
  style.textContent = styleSource
  document.head.append(style)
}

function css(selector: string, prop: string): string {
  ensureStyles()
  for (const sheet of Array.from(document.styleSheets)) {
    let rules: CSSRuleList
    try {
      rules = sheet.cssRules
    } catch {
      continue
    }
    for (const rule of Array.from(rules)) {
      if (rule instanceof CSSStyleRule && rule.selectorText === selector) {
        const value = rule.style.getPropertyValue(prop)
        if (value) return value
      }
    }
  }
  return ''
}

const Pairs = [
  { content: '.modal', backdrop: '.modal-backdrop' },
  { content: '.version-dialog', backdrop: '.version-overlay' },
  { content: '.folder-pick', backdrop: '.folder-pick-backdrop' },
  { content: '.m-sheet', backdrop: '.m-sheet-backdrop' },
  { content: '.m-picker', backdrop: '.m-picker-backdrop' },
  { content: '.m-granularity-sheet', backdrop: '.m-picker-backdrop' },
]

describe('弹层结构契约', () => {
  it('Reka 把 Overlay 和 Content 作为兄弟节点挂到 body 下', async () => {
    const Host = defineComponent({
      render() {
        return h(DialogRoot, { open: true }, () => [
          h(DialogPortal, () => [
            h(DialogOverlay, { class: 'probe-backdrop' }),
            h(DialogContent, { class: 'probe-content' }, () => 'x'),
          ]),
        ])
      },
    })
    const wrapper = mount(Host, { attachTo: document.body })
    await nextTick()
    await nextTick()

    const content = document.querySelector('.probe-content') as HTMLElement
    const backdrop = document.querySelector('.probe-backdrop') as HTMLElement

    expect(content).not.toBeNull()
    expect(backdrop).not.toBeNull()
    // 关键：内容不在遮罩里面
    expect(backdrop.contains(content)).toBe(false)
    expect(content.parentElement).toBe(document.body)

    wrapper.unmount()
  })

  it('每个弹层内容都有自己的定位，且不被遮罩压住', () => {
    for (const pair of Pairs) {
      const position = css(pair.content, 'position')
      expect(position, `${pair.content} 需要自己定位（position: fixed/absolute）`).toMatch(
        /^(fixed|absolute)$/,
      )

      const contentZ = parseInt(css(pair.content, 'z-index') || '0', 10)
      const backdropZ = parseInt(css(pair.backdrop, 'z-index') || '0', 10)
      // 同级挂载时后出现的在上层；但若遮罩 z-index 更高，内容就被盖住了
      expect(contentZ, `${pair.content} 的 z-index 不能低于遮罩`).toBeGreaterThanOrEqual(backdropZ)
    }
  })

  it('遮罩不再依赖 flex/grid 给内容定位', () => {
    for (const pair of Pairs) {
      expect(css(pair.backdrop, 'display'), `${pair.backdrop} 不应再是 flex/grid 容器`).not.toMatch(
        /^(grid|flex)$/,
      )
    }
  })
})