/**
 * Markdown 渲染（阅读态用）。
 *
 * 存储格式是原始 Markdown 文本（docs/backend/data-model.md 的 notes.content）。
 * 所有 HTML 都经过 DOMPurify 过滤，避免笔记里的 <script>、onerror 等被执行。
 */
import { marked } from 'marked'
import DOMPurify from 'dompurify'

marked.setOptions({
  gfm: true,
  // 不开启 breaks：Markdown 的单换行在渲染时通常应视为空格，
  // 开启会在输出里插入 <br />，导致「读出来再存回去」这类往返把正文改脏。
  breaks: false,
})

/** 把 Markdown 转成可安全插入的 HTML。 */
export function renderMarkdown(source: string): string {
  if (!source.trim()) return ''
  const raw = marked.parse(source, { async: false }) as string
  return DOMPurify.sanitize(raw, {
    // 不允许任何脚本、iframe、表单；站外链接统一加 rel
    FORBID_TAGS: ['script', 'style', 'iframe', 'form', 'input', 'object', 'embed'],
    FORBID_ATTR: ['style', 'onerror', 'onload', 'onclick'],
  })
}

/** 给渲染结果里的外链补 rel/target（DOMPurify 之后处理，避免被过滤）。 */
export function decorateLinks(html: string): string {
  return html.replace(
    /<a\s+([^>]*href="https?:\/\/[^"]*"[^>]*)>/g,
    '<a $1 target="_blank" rel="noopener noreferrer">',
  )
}
