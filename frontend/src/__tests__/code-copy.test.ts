import { describe, expect, it } from 'vitest'
import { renderHtml } from '@/utils/markdown'

describe('renderHtml 代码块复制按钮', () => {
  it('每个代码块生成一个复制按钮', () => {
    const html = renderHtml('<pre><code class="language-js">const a = 1</code></pre>')
    expect(html.match(/class="code-copy"/g)).toHaveLength(1)
    expect(html).toContain('data-state="idle"')
  })

  it('多个代码块各自生成按钮', () => {
    const html = renderHtml(
      '<pre><code class="language-js">a</code></pre><p>中间</p><pre><code class="language-go">b</code></pre>',
    )
    expect(html.match(/class="code-copy"/g)).toHaveLength(2)
  })

  it('普通段落不加复制按钮', () => {
    expect(renderHtml('<h1>标题</h1><p>正文</p>')).not.toContain('code-copy')
  })

  it('代码块里的尖括号按文本转义', () => {
    const html = renderHtml('<pre><code class="language-html">&lt;div&gt;x&lt;/div&gt;</code></pre>')
    expect(html).toContain('&lt;')
    expect(html).not.toContain('<div>x</div>')
  })
})
