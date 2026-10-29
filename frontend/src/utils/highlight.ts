/**
 * 代码块语法高亮（编辑态与阅读态共用）。
 *
 * 用 highlight.js 的 common 语言集（约 40 种，覆盖常用语言），
 * 避免把全部 190+ 语言打进包里。主题在 style.css 里按 HIG 配色重写，
 * 不引入 highlight.js 自带的 CSS。
 */
import hljs from 'highlight.js/lib/common'

/** 把一段代码高亮成 HTML；语言未知时按纯文本输出。 */
export function highlightCode(code: string, language?: string | null): string {
  const lang = (language ?? '').trim().toLowerCase()

  if (lang && hljs.getLanguage(lang)) {
    try {
      return hljs.highlight(code, { language: lang, ignoreIllegals: true }).value
    } catch {
      // 落到下面的自动识别
    }
  }

  try {
    return hljs.highlightAuto(code).value
  } catch {
    return escapeHtml(code)
  }
}

/** 转义 HTML，作为兜底。 */
export function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

/** 语言别名归一：`js` → `javascript`，用于展示与高亮。 */
export function normalizeLanguage(language?: string | null): string {
  const lang = (language ?? '').trim().toLowerCase()
  const aliases: Record<string, string> = {
    js: 'javascript',
    ts: 'typescript',
    sh: 'bash',
    shell: 'bash',
    py: 'python',
    yml: 'yaml',
    golang: 'go',
    'c++': 'cpp',
    'c#': 'csharp',
  }
  return aliases[lang] ?? lang
}
