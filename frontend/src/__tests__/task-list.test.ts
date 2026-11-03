import { describe, expect, it } from 'vitest'
import { renderMarkdown } from '@/utils/markdown'
import { checkboxHtml, hitTestCheckbox, renderTaskCheckboxes } from '@/utils/task-list'

/** 任务列表方块：编辑态与阅读态共用一套 DOM（utils/task-list.ts）。 */
describe('checkboxHtml', () => {
  it('未勾选与勾选只差一个 class', () => {
    expect(checkboxHtml(false)).toBe('<span class="task-check" aria-hidden="true"></span>')
    expect(checkboxHtml(true)).toBe(
      '<span class="task-check task-check--checked" aria-hidden="true"></span>',
    )
  })
})

describe('renderTaskCheckboxes', () => {
  it('把 marked 的 checkbox input 换成方块，保留勾选状态', () => {
    const html =
      '<ul>\n<li><input disabled="" type="checkbox"> 未完成</li>\n' +
      '<li><input checked="" disabled="" type="checkbox"> 已完成</li>\n</ul>'
    const out = renderTaskCheckboxes(html)
    expect(out).toContain('<li><span class="task-check" aria-hidden="true"></span> 未完成</li>')
    expect(out).toContain(
      '<li><span class="task-check task-check--checked" aria-hidden="true"></span> 已完成</li>',
    )
    expect(out).not.toContain('<input')
  })

  it('属性顺序变化时仍能识别勾选（checked 在 type 之后）', () => {
    const out = renderTaskCheckboxes('<li><input disabled="" type="checkbox" checked=""> x</li>')
    expect(out).toContain('task-check--checked')
  })

  it('普通列表不受影响', () => {
    const html = '<ul>\n<li>一</li>\n<li>二</li>\n</ul>'
    expect(renderTaskCheckboxes(html)).toBe(html)
  })
})

describe('renderMarkdown 任务列表', () => {
  it('阅读态输出方块而不是被过滤掉的 input', () => {
    const html = renderMarkdown('- [ ] 未完成\n- [x] 已完成\n')
    expect(html).not.toContain('<input')
    expect(html).toContain('task-check')
    expect(html).toContain('task-check--checked')
    expect(html).toContain('未完成')
    expect(html).toContain('已完成')
  })

  it('普通无序 / 有序列表不出现方块', () => {
    expect(renderMarkdown('- 一\n- 二\n')).not.toContain('task-check')
    expect(renderMarkdown('1. 一\n2. 二\n')).not.toContain('task-check')
  })

  it('方块不会被 DOMPurify 过滤（class 与 aria-hidden 都保留）', () => {
    const html = renderMarkdown('- [x] 任务\n')
    expect(html).toContain('class="task-check task-check--checked"')
    expect(html).toContain('aria-hidden="true"')
  })
})

describe('hitTestCheckbox', () => {
  const makeRoot = (inner: string): HTMLElement => {
    const root = document.createElement('div')
    root.innerHTML = inner
    return root
  }

  // li 的位置是 1，posAtDOM(li, 0) 返回 2，减 1 得到列表项自身的位置
  const fakeLookup = (checked: boolean | null) => ({
    posAtDOM: () => 2,
    nodeAt: () => ({ attrs: { checked } }),
  })

  it('点在方块上返回列表项位置与当前状态', () => {
    // 真实结构是 li > .label-wrapper > .milkdown-icon > span.task-check：
    // 方块不在段落里，否则会干扰落光标
    const root = makeRoot(
      `<ul><li><div class="label-wrapper"><span class="milkdown-icon"><span class="task-check"></span></span></div><div class="content-dom"><p>文本</p></div></li></ul>`,
    )
    const box = root.querySelector('.task-check') as HTMLElement
    const hit = hitTestCheckbox(
      { target: box } as unknown as MouseEvent,
      root,
      fakeLookup(false).posAtDOM,
      fakeLookup(false).nodeAt,
    )
    expect(hit).toEqual({ pos: 1, checked: false })
  })

  it('点在正文而不是方块上时不接管', () => {
    const root = makeRoot(
      `<ul><li><div class="label-wrapper"><span class="milkdown-icon"><span class="task-check"></span></span></div><div class="content-dom"><p>文本</p></div></li></ul>`,
    )
    const text = root.querySelector('p') as HTMLElement
    const hit = hitTestCheckbox(
      { target: text } as unknown as MouseEvent,
      root,
      fakeLookup(false).posAtDOM,
      fakeLookup(false).nodeAt,
    )
    expect(hit).toBeNull()
  })

  it('普通列表项（checked 为 null）不接管', () => {
    const root = makeRoot(
      `<ul><li><div class="label-wrapper"><span class="milkdown-icon"><span class="task-check"></span></span></div><div class="content-dom"><p>文本</p></div></li></ul>`,
    )
    const box = root.querySelector('.task-check') as HTMLElement
    const hit = hitTestCheckbox(
      { target: box } as unknown as MouseEvent,
      root,
      fakeLookup(null).posAtDOM,
      fakeLookup(null).nodeAt,
    )
    expect(hit).toBeNull()
  })
})
