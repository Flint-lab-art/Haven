/**
 * 代码块语法高亮（编辑态由 lowlight 负责，阅读态由这里负责）。
 *
 * 七期重置了语言范围：只用 highlight.js 的 common 集，
 * 不再维护 63 种语言、别名表和 Caddyfile 自定义语法
 * （docs-ai/v7/frontend/frontend.md 第六节）。
 */
import hljs from 'highlight.js/lib/common'

/** 把一段代码高亮成 HTML；语言未知时按纯文本输出（不做自动猜测）。 */
export function highlightCode(code: string, language?: string | null): string {
  const lang = normalizeLanguage(language)
  if (!lang) return escapeHtml(code)

  if (hljs.getLanguage(lang)) {
    try {
      return hljs.highlight(code, { language: lang, ignoreIllegals: true }).value
    } catch {
      return escapeHtml(code)
    }
  }
  return escapeHtml(code)
}

/** 转义 HTML，作为兜底。 */
export function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

/**
 * 语言名归一：去空白、转小写、全角字母转半角。
 *
 * highlight.js 的 common 集自带常用别名（js / ts / sh / html 等），
 * 这里不再维护 v6 的别名表。
 */
export function normalizeLanguage(language?: string | null): string {
  return (language ?? '')
    .trim()
    .toLowerCase()
    .replace(/[\uFF21-\uFF3A\uFF41-\uFF5A]/g, (ch) =>
      String.fromCharCode(ch.charCodeAt(0) - 0xfee0),
    )
}

/** 代码块左上角显示的语言名。 */
export function displayLanguage(language?: string | null): string {
  return normalizeLanguage(language)
}
