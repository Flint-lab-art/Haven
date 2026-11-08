import { describe, expect, it } from 'vitest'
import { displayLanguage, highlightCode, normalizeLanguage } from '@/utils/highlight'

describe('highlightCode', () => {
  it('高亮 common 集里的语言', () => {
    expect(highlightCode('const x = 1', 'javascript')).toContain('hljs-')
    expect(highlightCode('func main() {}', 'go')).toContain('hljs-')
    expect(highlightCode('public class A {}', 'java')).toContain('hljs-')
    expect(highlightCode('def f(x): return x', 'python')).toContain('hljs-')
    expect(highlightCode('fn main() {}', 'rust')).toContain('hljs-')
    expect(highlightCode('#include <vector>', 'cpp')).toContain('hljs-')
  })

  it('highlight.js 自带的别名可用（js / ts / sh / html）', () => {
    expect(highlightCode('const x = 1', 'js')).toContain('hljs-')
    expect(highlightCode('interface A { x: string }', 'ts')).toContain('hljs-')
    expect(highlightCode('echo "hi"', 'sh')).toContain('hljs-')
    expect(highlightCode('<div class="a">x</div>', 'html')).toContain('hljs-')
  })

  it('未知语言按纯文本输出，不自动猜测', () => {
    const html = highlightCode('SELECT * FROM users', 'not-a-language')
    expect(html).toBe('SELECT * FROM users')
    expect(html).not.toContain('hljs-')
  })

  it('空语言按纯文本输出', () => {
    expect(highlightCode('const x = 1', '')).toBe('const x = 1')
  })

  it('转义用户代码里的 HTML', () => {
    const html = highlightCode('<script>alert(1)</script>', 'not-a-language')
    expect(html).toContain('&lt;script&gt;')
  })
})

describe('normalizeLanguage', () => {
  it('去空白并转小写', () => {
    expect(normalizeLanguage('  GO  ')).toBe('go')
    expect(normalizeLanguage('SH')).toBe('sh')
  })

  it('全角字母归一', () => {
    expect(normalizeLanguage('ｇｏ')).toBe('go')
    expect(normalizeLanguage('ＪＡＶＡ')).toBe('java')
  })
})

describe('displayLanguage', () => {
  it('显示用户写的小写语言名', () => {
    expect(displayLanguage('html')).toBe('html')
    expect(displayLanguage('js')).toBe('js')
    expect(displayLanguage('  Go ')).toBe('go')
  })
})
