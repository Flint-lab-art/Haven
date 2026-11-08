import { describe, expect, it } from 'vitest'
import { renderHtml, renderMarkdown } from '@/utils/markdown'

describe('renderHtml', () => {
  it('保留 TipTap 生成的标题与行内格式', () => {
    const html = renderHtml('<h1>标题</h1><p>正文 <strong>粗体</strong> 与 <code>代码</code></p>')
    expect(html).toContain('<h1>标题</h1>')
    expect(html).toContain('<strong>粗体</strong>')
    expect(html).toContain('<code>代码</code>')
  })

  it('空串返回空串', () => {
    expect(renderHtml('')).toBe('')
    expect(renderHtml('   \n ')).toBe('')
  })

  it('过滤脚本与内联事件', () => {
    const html = renderHtml('<script>alert(1)</script><img src="x" onerror="alert(2)">')
    expect(html).not.toContain('<script')
    expect(html).not.toContain('onerror')
    expect(html).not.toContain('alert(2)')
  })

  it('保留代码高亮需要的 class 与行内 style', () => {
    const html = renderHtml(
      '<p><span class="hljs-keyword" style="color: red">const</span> a = 1</p>',
    )
    expect(html).toContain('class="hljs-keyword"')
    expect(html).toContain('style="color: red"')
  })

  it('代码块重新高亮并加语言标签与复制按钮', () => {
    const html = renderHtml('<pre><code class="language-js">const a = 1</code></pre>')
    expect(html).toContain('code-block-wrap')
    expect(html).toContain('code-copy')
    expect(html).toContain('code-lang')
    expect(html).toContain('hljs-keyword')
  })

  it('保留表格、折叠块与任务列表结构', () => {
    const html = renderHtml(
      '<table><thead><tr><th>a</th></tr></thead><tbody><tr><td>1</td></tr></tbody></table>' +
        '<details open><summary>标题</summary><div><p>内容</p></div></details>' +
        '<ul data-type="taskList"><li data-type="taskItem" data-checked="true">' +
        '<label><input type="checkbox" checked><span></span></label><div><p>任务</p></div></li></ul>',
    )
    expect(html).toContain('table-wrap')
    expect(html).toContain('<details open="">')
    expect(html).toContain('data-type="taskList"')
    expect(html).toContain('data-checked="true"')
    expect(html).toContain('disabled=""')
  })

  it('兼容旧转换命令的简化任务项', () => {
    const html = renderHtml(
      '<ul data-type="taskList"><li data-type="taskItem" data-checked="true">旧任务</li></ul>',
    )
    expect(html).toContain('<label>')
    expect(html).toContain('type="checkbox"')
    expect(html).toContain('<div>旧任务</div>')
    expect(html).toContain('disabled=""')
  })

  it('外链补 target 与 rel', () => {
    const html = renderHtml('<p><a href="https://example.com">链接</a></p>')
    expect(html).toContain('target="_blank"')
    expect(html).toContain('rel="noopener noreferrer"')
  })
})

describe('renderMarkdown（作品集正文）', () => {
  it('仍把 Markdown 渲染成 HTML', () => {
    const html = renderMarkdown('# 标题\n\n**粗体** 与 `代码`')
    expect(html).toContain('<h1>标题</h1>')
    expect(html).toContain('<strong>粗体</strong>')
    expect(html).toContain('<code>代码</code>')
  })

  it('同样经过 DOMPurify', () => {
    const html = renderMarkdown('<script>alert(1)</script>\n\n正文')
    expect(html).not.toContain('<script')
    expect(html).toContain('正文')
  })
})
