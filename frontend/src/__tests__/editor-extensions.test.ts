import { describe, expect, it } from 'vitest'
import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { TextStyle, Color } from '@tiptap/extension-text-style'
import { Highlight } from '@tiptap/extension-highlight'
import { TextAlign } from '@tiptap/extension-text-align'
import { Typography } from '@tiptap/extension-typography'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import { createLowlight, common } from 'lowlight'
import { TaskList } from '@tiptap/extension-task-list'
import { TaskItem } from '@tiptap/extension-task-item'
import { Table, TableCell, TableHeader, TableRow } from '@tiptap/extension-table'
import { Image } from '@tiptap/extension-image'
import { Details, DetailsContent, DetailsSummary } from '@tiptap/extension-details'
import { CharacterCount, Placeholder } from '@tiptap/extensions'
import { CodeCopy } from '@/utils/tiptap-code-copy'
import { SlashCommand } from '@/utils/slash-command'

function makeEditor(): Editor {
  return new Editor({
    element: document.createElement('div'),
    content: '<p>hello</p>',
    extensions: [
      StarterKit.configure({ codeBlock: false }),
      TextStyle,
      Color,
      Highlight.configure({ multicolor: true }),
      TextAlign.configure({ types: ['heading', 'paragraph'] }),
      Typography,
      Placeholder.configure({ placeholder: '开始写作…' }),
      CodeBlockLowlight.configure({
        lowlight: createLowlight(common),
        HTMLAttributes: { class: 'hljs' },
      }),
      TaskList,
      TaskItem.configure({ nested: true }),
      Table.configure({ resizable: false }),
      TableRow,
      TableCell,
      TableHeader,
      Image.configure({ allowBase64: false }),
      Details,
      DetailsContent,
      DetailsSummary,
      CharacterCount,
      CodeCopy,
      SlashCommand,
    ],
  })
}

describe('TipTap 扩展注册', () => {
  it('所有扩展能同时注册并编辑普通段落', () => {
    const editor = makeEditor()
    expect(editor.getHTML()).toContain('hello')
    editor.destroy()
  })

  it('任务列表能读回 TipTap 结构', () => {
    const editor = makeEditor()
    editor.commands.setContent(
      '<ul data-type="taskList"><li data-type="taskItem" data-checked="true"><label><input type="checkbox" checked><span></span></label><div><p>任务</p></div></li></ul>',
    )
    const html = editor.getHTML()
    expect(html).toContain('data-type="taskList"')
    expect(html).toContain('data-checked="true"')
    editor.destroy()
  })

  it('表格与折叠块能读回', () => {
    const editor = makeEditor()
    editor.commands.setContent(
      '<table><tbody><tr><td><p>a</p></td></tr></tbody></table>' +
        '<details open><summary>标题</summary><div><p>内容</p></div></details>',
    )
    const html = editor.getHTML()
    expect(html).toContain('<table')
    expect(html).toContain('<details')
    expect(html).toContain('<summary>标题</summary>')
    editor.destroy()
  })

  it('代码块保留语言并输出 hljs class', () => {
    const editor = makeEditor()
    editor.commands.setContent('<pre><code class="language-go">func main() {}</code></pre>')
    const html = editor.getHTML()
    expect(html).toContain('language-go')
    expect(html).toContain('hljs')
    editor.destroy()
  })

  it('字数统计可用', () => {
    const editor = makeEditor()
    editor.commands.setContent('<p>你好 world</p>')
    expect(editor.storage.characterCount.characters()).toBeGreaterThan(0)
    editor.destroy()
  })
})
