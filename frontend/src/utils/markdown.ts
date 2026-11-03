/**
 * Markdown 渲染（阅读态用）。
 *
 * 存储格式是原始 Markdown 文本（docs/backend/data-model.md 的 notes.content）。
 * 所有 HTML 都经过 DOMPurify 过滤，避免笔记里的 <script>、onerror 等被执行。
 */
import { marked, type Tokens } from 'marked'
import DOMPurify from 'dompurify'
import { highlightCode, escapeHtml, displayLanguage } from './highlight'
import { renderTaskCheckboxes } from './task-list'

marked.setOptions({
  gfm: true,
  // 不开启 breaks：Markdown 的单换行在渲染时通常应视为空格，
  // 开启会在输出里插入 <br />，导致「读出来再存回去」这类往返把正文改脏。
  breaks: false,
})

// 代码块语法高亮：marked 会把 renderer 的 code 交给这里
const renderer = new marked.Renderer()
renderer.code = ({ text, lang }: Tokens.Code): string => {
  const language = displayLanguage(lang)
  const highlighted = highlightCode(text, lang)
  const langClass = language ? ` class="language-${escapeHtml(language)}"` : ''
  // 复制按钮：点击时从同级的 <pre> 读纯文本，不在 DOM 里再存一份代码
  // （docs/v6/frontend/frontend.md 第六节）
  return (
    '<div class="code-block-wrap">' +
    (language ? `<span class="code-lang">${escapeHtml(language)}</span>` : '') +
    '<button type="button" class="code-copy" data-state="idle">复制</button>' +
    `<pre><code${langClass}>${highlighted}</code></pre>` +
    '</div>'
  )
}

marked.use({ renderer })

/** 把 Markdown 转成可安全插入的 HTML。 */
export function renderMarkdown(source: string): string {
  if (!source.trim()) return ''
  const raw = marked.parse(source, { async: false }) as string
  // 任务列表的 <input> 必须在 sanitize 之前换掉：DOMPurify 会把 input 整个删除，
  // 连 checked 一起丢掉，事后就分不清勾没勾了
  return DOMPurify.sanitize(renderTaskCheckboxes(raw), {
    // 不允许任何脚本、iframe、表单
    FORBID_TAGS: ['script', 'style', 'iframe', 'form', 'input', 'object', 'embed'],
    FORBID_ATTR: ['style', 'onerror', 'onload', 'onclick'],
    // highlight.js 输出 <span class="hljs-keyword"> 这类标签，需要保留 class
    ADD_ATTR: ['class'],
  })
}

/** 给渲染结果里的外链补 rel/target（DOMPurify 之后处理，避免被过滤）。 */
export function decorateLinks(html: string): string {
  return html.replace(
    /<a\s+([^>]*href="https?:\/\/[^"]*"[^>]*)>/g,
    '<a $1 target="_blank" rel="noopener noreferrer">',
  )
}
