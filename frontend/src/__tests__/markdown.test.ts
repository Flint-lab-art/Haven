import { describe, expect, it } from 'vitest'
import { renderMarkdown, decorateLinks } from '@/utils/markdown'

describe('renderMarkdown', () => {
  it('渲染常见 Markdown 结构', () => {
    const html = renderMarkdown('# 标题\n\n**粗体** 与 `代码`\n\n- 一\n- 二\n\n> 引用\n\n```js\nx()\n```')
    expect(html).toContain('<h1')
    expect(html).toContain('<strong>')
    expect(html).toContain('<code>')
    expect(html).toContain('<li>')
    expect(html).toContain('<blockquote>')
    expect(html).toContain('<pre>')
  })

  it('空内容返回空串', () => {
    expect(renderMarkdown('')).toBe('')
    expect(renderMarkdown('   \n ')).toBe('')
  })

  it('过滤脚本与内联事件（XSS）', () => {
    const html = renderMarkdown('<script>alert(1)</script>\n\n<img src=x onerror="alert(2)">')
    expect(html).not.toContain('<script')
    expect(html).not.toContain('onerror')
  })

  it('不过滤正常内容里的尖括号文本', () => {
    const html = renderMarkdown('比较 a < b 和 c > d')
    expect(html).toContain('a &lt; b')
  })

  it('代码块带语法高亮与语言标签', () => {
    const html = renderMarkdown('```go\nfunc main() {}\n```')
    expect(html).toContain('code-block-wrap')
    expect(html).toContain('code-lang')
    expect(html).toContain('hljs-')
    expect(html).toContain('language-go')
  })

  it('高亮产生的 class 不会被 DOMPurify 过滤', () => {
    const html = renderMarkdown('```js\nconst a = 1\n```')
    expect(html).toMatch(/class="hljs-[a-z]+/)
  })

  it('不把单换行渲染成 <br>（避免往返把正文改脏）', () => {
    const html = renderMarkdown('第一行\n第二行')
    expect(html).not.toContain('<br')
  })
})

describe('decorateLinks', () => {
  it('给外链加 rel 与 target', () => {
    const out = decorateLinks('<p><a href="https://example.com">x</a></p>')
    expect(out).toContain('rel="noopener noreferrer"')
    expect(out).toContain('target="_blank"')
  })

  it('站内链接不变', () => {
    const out = decorateLinks('<p><a href="/login">x</a></p>')
    expect(out).toBe('<p><a href="/login">x</a></p>')
  })
})
