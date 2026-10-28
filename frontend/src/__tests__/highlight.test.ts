import { describe, expect, it } from 'vitest'
import { highlightCode, normalizeLanguage, escapeHtml } from '@/utils/highlight'

describe('highlightCode', () => {
  it('按指定语言高亮', () => {
    const html = highlightCode('const x = 1', 'javascript')
    expect(html).toContain('hljs-')
    expect(html).toContain('1')
  })

  it('支持 go 与 typescript', () => {
    expect(highlightCode('func main() {}', 'go')).toContain('hljs-')
    expect(highlightCode('interface A { x: string }', 'ts')).toContain('hljs-')
  })

  it('未知语言退回自动识别且不抛错', () => {
    const html = highlightCode('SELECT * FROM users', 'not-a-language')
    expect(typeof html).toBe('string')
    expect(html.length).toBeGreaterThan(0)
  })

  it('源代码里的 HTML 被转义，不会注入', () => {
    const html = highlightCode('<script>alert(1)</script>', 'html')
    expect(html).not.toContain('<script>')
  })
})

describe('normalizeLanguage', () => {
  it('别名归一', () => {
    expect(normalizeLanguage('js')).toBe('javascript')
    expect(normalizeLanguage('ts')).toBe('typescript')
    expect(normalizeLanguage('golang')).toBe('go')
    expect(normalizeLanguage('SH')).toBe('bash')
    expect(normalizeLanguage('')).toBe('')
  })
})

describe('escapeHtml', () => {
  it('转义尖括号与引号', () => {
    expect(escapeHtml('<a href="x">')).toBe('&lt;a href=&quot;x&quot;&gt;')
  })
})
