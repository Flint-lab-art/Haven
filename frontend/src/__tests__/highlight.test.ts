import { describe, expect, it } from 'vitest'
import {
  displayLanguage,
  escapeHtml,
  highlightCode,
  normalizeLanguage,
} from '@/utils/highlight'

/** 代码高亮（docs/v6/frontend/frontend.md 第八节）。 */
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

  it('支持常用语言：java / python / rust / cpp / shell', () => {
    expect(highlightCode('public class A {}', 'java')).toContain('hljs-')
    expect(highlightCode('def f(x): return x', 'python')).toContain('hljs-')
    expect(highlightCode('fn main() {}', 'rust')).toContain('hljs-')
    expect(highlightCode('#include <vector>', 'cpp')).toContain('hljs-')
    expect(highlightCode('echo "hi"', 'sh')).toContain('hljs-')
  })

  it('支持配置文件格式：yaml / ini / toml', () => {
    expect(highlightCode('key: value', 'yaml')).toContain('hljs-')
    expect(highlightCode('[db]\nhost = localhost', 'ini')).toContain('hljs-')
    expect(highlightCode('[db]\nflag = true', 'toml')).toContain('hljs-')
  })

  it('支持额外注册的运维 / 构建语言', () => {
    expect(highlightCode('FROM golang:1.27\nRUN go build', 'dockerfile')).toContain('hljs-')
    expect(highlightCode('server {\n  listen 80;\n}', 'nginx')).toContain('hljs-')
    expect(highlightCode('Get-ChildItem | Where-Object { $_.Name }', 'powershell')).toContain('hljs-')
    expect(highlightCode('cmake_minimum_required(VERSION 3.20)', 'cmake')).toContain('hljs-')
    expect(highlightCode('plugins { id "java" }', 'gradle')).toContain('hljs-')
  })

  it('支持额外注册的语言', () => {
    expect(highlightCode('main :: IO ()\nmain = pure ()', 'haskell')).toContain('hljs-')
    expect(highlightCode('defmodule A do\nend', 'elixir')).toContain('hljs-')
    expect(highlightCode('object A extends App {}', 'scala')).toContain('hljs-')
    expect(highlightCode('void main() { print("x"); }', 'dart')).toContain('hljs-')
    expect(highlightCode('syntax = "proto3";', 'protobuf')).toContain('hljs-')
    expect(highlightCode('\\section{A}', 'latex')).toContain('hljs-')
    expect(highlightCode('let x = 1', 'fsharp')).toContain('hljs-')
  })

  it('别名走额外注册的语言', () => {
    expect(highlightCode('FROM scratch', 'docker')).toContain('hljs-')
    expect(highlightCode('$x = 1', 'ps1')).toContain('hljs-')
    expect(highlightCode('\\section{A}', 'tex')).toContain('hljs-')
    expect(highlightCode('syntax = "proto3";', 'proto')).toContain('hljs-')
  })

  it('Caddyfile 高亮（本地最小实现）', () => {
    const caddy = 'example.com {\n\treverse_proxy localhost:8080\n\ttls internal\n}'
    const html = highlightCode(caddy, 'caddyfile')
    // 指令名与站点地址
    expect(html).toContain('hljs-keyword')
    expect(html).toContain('example.com')
    expect(html).toContain('reverse_proxy')
    // 端口号
    expect(html).toContain('hljs-number')
  })

  it('Caddyfile：注释、占位符、环境变量、字符串、多地址', () => {
    const html = highlightCode(
      '# 注释\n{$DOMAIN:localhost} {\n\tredir https://x.com{uri}\n\trespond "hi" 502\n}',
      'caddyfile',
    )
    expect(html).toContain('hljs-comment')
    expect(html).toContain('hljs-variable')
    expect(html).toContain('hljs-template-variable')
    expect(html).toContain('hljs-string')
    expect(html).toContain('hljs-number')
  })

  it('Caddyfile：caddy 别名可用', () => {
    expect(highlightCode('example.com { }', 'caddy')).toContain('hljs-keyword')
  })

  it('html 与 xml 都能高亮（共用 xml 语法）', () => {
    const html = highlightCode('<div class="a">x</div>', 'html')
    expect(html).toContain('hljs-')
    expect(highlightCode('<root><a/></root>', 'xml')).toContain('hljs-')
  })

  it('未知语言按纯文本输出，不做自动猜测', () => {
    // 回退到 highlightAuto 会产出 hljs- span，正是要杜绝的行为（8.3）
    const html = highlightCode('SELECT * FROM users', 'not-a-language')
    expect(html).not.toContain('hljs-')
    expect(html).toBe('SELECT * FROM users')
  })

  it('不带语言名同样按纯文本，不猜测', () => {
    const html = highlightCode('const x = 1', '')
    expect(html).not.toContain('hljs-')
  })

  it('源代码里的 HTML 被转义，不会注入', () => {
    const html = highlightCode('<script>alert(1)</script>', 'html')
    expect(html).not.toContain('<script>')
  })

  it('未识别语言时的尖括号同样被转义', () => {
    const html = highlightCode('<script>x</script>', 'not-a-language')
    expect(html).not.toContain('<script>')
    expect(html).toContain('&lt;script&gt;')
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

  it('配置与标记类别名', () => {
    expect(normalizeLanguage('yml')).toBe('yaml')
    expect(normalizeLanguage('cfg')).toBe('ini')
    expect(normalizeLanguage('conf')).toBe('ini')
    expect(normalizeLanguage('html')).toBe('xml')
    expect(normalizeLanguage('htm')).toBe('xml')
    expect(normalizeLanguage('rs')).toBe('rust')
    expect(normalizeLanguage('py')).toBe('python')
  })

  it('全角字母归一（中文输入法常见）', () => {
    expect(normalizeLanguage('ｇｏ')).toBe('go')
    expect(normalizeLanguage('ＪＡＶＡ')).toBe('java')
  })

  it('首尾空白被去掉', () => {
    expect(normalizeLanguage('  go  ')).toBe('go')
  })
})

describe('displayLanguage', () => {
  it('html 标签仍显示 html，不显示成 xml', () => {
    expect(displayLanguage('html')).toBe('html')
    expect(displayLanguage('xml')).toBe('xml')
  })

  it('常见别名转成规范写法', () => {
    expect(displayLanguage('js')).toBe('javascript')
    expect(displayLanguage('ts')).toBe('typescript')
    expect(displayLanguage('yml')).toBe('yaml')
    expect(displayLanguage('py')).toBe('python')
  })
})

describe('escapeHtml', () => {
  it('转义尖括号与引号', () => {
    expect(escapeHtml('<a href="x">')).toBe('&lt;a href=&quot;x&quot;&gt;')
  })
})
