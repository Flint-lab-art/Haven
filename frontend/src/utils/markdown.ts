/**
 * Markdown 渲染（阅读态用）。
 *
 * 存储格式是原始 Markdown 文本（docs/backend/data-model.md 的 notes.content）。
 * 所有 HTML 都经过 DOMPurify 过滤，避免笔记里的 <script>、onerror 等被执行。
 */
import { marked, type Tokens } from 'marked'
import DOMPurify from 'dompurify'
import { highlightCode, escapeHtml, normalizeLanguage } from './highlight'

marked.setOptions({
  gfm: true,
  // 不开启 breaks：Markdown 的单换行在渲染时通常应视为空格，
  // 开启会在输出里插入 <br />，导致「读出来再存回去」这类往返把正文改脏。
  breaks: false,
})

// 代码块语法高亮：marked 会把 renderer 的 code 交给这里
const renderer = new marked.Renderer()
renderer.code = ({ text, lang }: Tokens.Code): string => {
  const language = normalizeLanguage(lang)
  const highlighted = highlightCode(text, language)
  const langClass = language ? ` class="language-${escapeHtml(language)}"` : ''
  return (
    '<div class="code-block-wrap">' +
    (language ? `<span class="code-lang">${escapeHtml(language)}</span>` : '') +
    `<pre><code${langClass}>${highlighted}</code></pre>` +
    '</div>'
  )
}

marked.use({ renderer })

/** 把 Markdown 转成可安全插入的 HTML。 */
export function renderMarkdown(source: string): string {
  if (!source.trim()) return ''
  const raw = marked.parse(source, { async: false }) as string
  return DOMPurify.sanitize(raw, {
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
