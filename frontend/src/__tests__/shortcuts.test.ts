import { describe, expect, it } from 'vitest'
import { targetKind } from '@/composables/useGlobalShortcuts'

/**
 * 快捷键的分流依据（docs/v6/frontend/frontend.md 第二节规则 4）。
 *
 * 关键点：编辑器正文是 contenteditable，但必须算作 `editor` 而不是 `field`，
 * 否则 Cmd+S 在写笔记时会被直接放给浏览器（表现为「没劫持，浏览器弹出保存网页」）。
 */
describe('targetKind', () => {
  const make = (html: string): HTMLElement => {
    const root = document.createElement('div')
    root.innerHTML = html
    document.body.appendChild(root)
    return root
  }

  it('编辑器正文算 editor（ProseMirror）', () => {
    const root = make('<div class="ProseMirror"><p>正文</p></div>')
    expect(targetKind(root.querySelector('p'))).toBe('editor')
    expect(targetKind(root.querySelector('.ProseMirror'))).toBe('editor')
  })

  it('代码块内部也算 editor', () => {
    const root = make('<div class="ProseMirror"><pre><code><span>x</span></code></pre></div>')
    expect(targetKind(root.querySelector('span'))).toBe('editor')
  })

  it('input / textarea / select 算 field', () => {
    const root = make('<input><textarea></textarea><select></select>')
    expect(targetKind(root.querySelector('input'))).toBe('field')
    expect(targetKind(root.querySelector('textarea'))).toBe('field')
    expect(targetKind(root.querySelector('select'))).toBe('field')
  })

  it('其它 contenteditable 算 field（例如一次性输入框）', () => {
    const root = make('<div contenteditable="true"><span>输入中</span></div>')
    expect(targetKind(root.querySelector('span'))).toBe('field')
  })

  it('页面空白与按钮算 other', () => {
    const root = make('<button>保存</button><div class="list">列表</div>')
    expect(targetKind(root.querySelector('button'))).toBe('other')
    expect(targetKind(root.querySelector('.list'))).toBe('other')
    expect(targetKind(document.body)).toBe('other')
  })

  it('target 为空时算 other', () => {
    expect(targetKind(null)).toBe('other')
  })
})
