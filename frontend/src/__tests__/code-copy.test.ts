import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest'
import { renderMarkdown } from '@/utils/markdown'
import { COPY_FEEDBACK_MS, copyText, flashCopyState, installCodeCopyHandler } from '@/utils/clipboard'

/** 代码块复制按钮（docs/v6/frontend/frontend.md 第六节）。 */
describe('renderMarkdown 代码块复制按钮', () => {
  it('每个代码块都带一个复制按钮', () => {
    const html = renderMarkdown('```js\nconst a = 1\n```')
    expect(html).toContain('class="code-copy"')
    expect(html).toContain('data-state="idle"')
    expect(html).toContain('>复制<')
  })

  it('多个代码块各带一个按钮', () => {
    const html = renderMarkdown('```js\na\n```\n\n```go\nb\n```')
    expect(html.match(/class="code-copy"/g)).toHaveLength(2)
  })

  it('语言标签在左上、按钮在右，二者都在代码块容器里', () => {
    const html = renderMarkdown('```ts\nconst a = 1\n```')
    expect(html).toContain('class="code-lang"')
    // 按钮必须位于 <pre> 之前，且与 pre 同属一个容器
    expect(html.indexOf('code-copy')).toBeLessThan(html.indexOf('<pre'))
  })

  it('按钮不会被 DOMPurify 过滤', () => {
    const html = renderMarkdown('```js\nx\n```')
    expect(html).toContain('<button type="button" class="code-copy"')
  })

  it('没有代码块时不出现按钮', () => {
    expect(renderMarkdown('# 标题\n\n正文')).not.toContain('code-copy')
  })
})

describe('copyText', () => {
  const original = navigator.clipboard

  afterEach(() => {
    Object.defineProperty(navigator, 'clipboard', { value: original, configurable: true })
    vi.restoreAllMocks()
  })

  it('优先用 Clipboard API', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'clipboard', { value: { writeText }, configurable: true })
    await expect(copyText('hello')).resolves.toBe(true)
    expect(writeText).toHaveBeenCalledWith('hello')
  })

  it('Clipboard API 抛错时静默降级，不向外抛', async () => {
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText: vi.fn().mockRejectedValue(new Error('denied')) },
      configurable: true,
    })
    // jsdom 没有 execCommand，回退也会失败，最终返回 false 而不是抛错
    await expect(copyText('hello')).resolves.toBe(false)
  })

  it('没有 Clipboard API 时同样不抛错', async () => {
    Object.defineProperty(navigator, 'clipboard', { value: undefined, configurable: true })
    await expect(copyText('hello')).resolves.toBe(false)
  })
})

describe('flashCopyState', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('成功时显示已复制并在 1.5 秒后复原', () => {
    const button = document.createElement('button')
    button.textContent = '复制'
    document.body.appendChild(button)

    flashCopyState(button, true)
    expect(button.dataset.state).toBe('copied')
    expect(button.textContent).toBe('已复制')

    vi.advanceTimersByTime(COPY_FEEDBACK_MS)
    expect(button.dataset.state).toBe('idle')
    expect(button.textContent).toBe('复制')
    button.remove()
  })

  it('失败时显示复制失败', () => {
    const button = document.createElement('button')
    document.body.appendChild(button)
    flashCopyState(button, false)
    expect(button.dataset.state).toBe('failed')
    expect(button.textContent).toBe('复制失败')
    button.remove()
  })

  it('连点只重置计时，不叠加', () => {
    const button = document.createElement('button')
    document.body.appendChild(button)

    flashCopyState(button, true)
    vi.advanceTimersByTime(1000)
    flashCopyState(button, true)
    // 第一次的计时器已被清掉，再等 1 秒仍应保持「已复制」
    vi.advanceTimersByTime(1000)
    expect(button.textContent).toBe('已复制')

    vi.advanceTimersByTime(COPY_FEEDBACK_MS)
    expect(button.textContent).toBe('复制')
    button.remove()
  })
})

describe('installCodeCopyHandler', () => {
  it('点击按钮复制同级 pre 的文本', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'clipboard', { value: { writeText }, configurable: true })

    const root = document.createElement('div')
    root.innerHTML =
      '<div class="code-block-wrap"><button type="button" class="code-copy">复制</button><pre><code>a\nb</code></pre></div>'
    document.body.appendChild(root)

    const dispose = installCodeCopyHandler(root)
    ;(root.querySelector('.code-copy') as HTMLElement).click()
    await Promise.resolve()
    await Promise.resolve()

    expect(writeText).toHaveBeenCalledWith('a\nb')
    dispose()
    root.remove()
  })

  it('解绑后不再响应点击', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'clipboard', { value: { writeText }, configurable: true })

    const root = document.createElement('div')
    root.innerHTML =
      '<div class="code-block-wrap"><button type="button" class="code-copy">复制</button><pre><code>x</code></pre></div>'
    document.body.appendChild(root)

    const dispose = installCodeCopyHandler(root)
    dispose()
    ;(root.querySelector('.code-copy') as HTMLElement).click()
    await Promise.resolve()

    expect(writeText).not.toHaveBeenCalled()
    root.remove()
  })
})
