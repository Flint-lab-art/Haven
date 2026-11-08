/**
 * 正文 HTML 渲染（阅读态用）。
 *
 * 七期起 notes.content 存 TipTap 产出的 HTML（docs-ai/v7/api.md 第一节）。
 * 所有 HTML 必须先过 DOMPurify，再补代码高亮、复制按钮、只读复选框等阅读态增强。
 */
import DOMPurify from 'dompurify'
import { marked } from 'marked'
import { displayLanguage, highlightCode } from './highlight'

marked.setOptions({
  gfm: true,
  // 与 v1 一致：不开启 breaks，避免单换行被渲染成 <br>
  breaks: false,
})

const PURIFY_CONFIG = {
  // 不允许脚本、内联样式表、iframe、表单与嵌入对象。
  FORBID_TAGS: ['script', 'style', 'iframe', 'form', 'object', 'embed'],
  FORBID_ATTR: ['onerror', 'onload', 'onclick'],
  // 颜色 / 对齐写在内联 style 上；任务列表、表格、折叠块依赖 data-* 与这些属性。
  ADD_ATTR: [
    'class',
    'style',
    'open',
    'colspan',
    'rowspan',
    'start',
    'type',
    'checked',
    'disabled',
    'data-color',
    'data-type',
    'data-checked',
    'data-language',
  ],
  ADD_TAGS: ['details', 'summary', 'mark'],
}

/** 把正文 HTML 转成可安全插入的阅读态 HTML（笔记正文，七期起存 HTML）。 */
export function renderHtml(html: string): string {
  return sanitizeAndEnhance(html)
}

/**
 * 把 Markdown 转成阅读态 HTML。
 *
 * 只用于作品集正文：`portfolio_items.content` 仍是 Markdown（v3 范围），
 * 不随笔记正文一起改成 HTML（docs-ai/v7/frontend/frontend.md 第四节）。
 */
export function renderMarkdown(source: string): string {
  if (!source.trim()) return ''
  return sanitizeAndEnhance(marked.parse(source, { async: false }) as string)
}

function sanitizeAndEnhance(input: string): string {
  if (!input.trim()) return ''

  const clean = DOMPurify.sanitize(input, PURIFY_CONFIG) as string
  if (!clean.trim()) return ''

  const doc = new DOMParser().parseFromString(clean, 'text/html')

  decorateLinks(doc)
  normalizeTaskItems(doc)
  lockCheckboxes(doc)
  wrapTables(doc)
  decorateCodeBlocks(doc)

  return doc.body.innerHTML
}

/** 外链补 target / rel（在 DOMPurify 之后处理，避免被过滤）。 */
function decorateLinks(doc: Document): void {
  doc.querySelectorAll<HTMLAnchorElement>('a[href]').forEach((a) => {
    const href = a.getAttribute('href') ?? ''
    if (/^https?:\/\//i.test(href)) {
      a.target = '_blank'
      a.rel = 'noopener noreferrer'
    }
  })
}

/** 阅读态的复选框只读：没有保存通道，能点不能存会误导。 */
function lockCheckboxes(doc: Document): void {
  doc.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((input) => {
    input.disabled = true
    input.setAttribute('disabled', '')
  })
}

/**
 * 兼容旧转换命令产出的简化任务项：
 *   <li data-checked="true">文字</li>
 * 补成 TipTap 的完整结构，阅读态才有复选框。
 *
 * 新转换命令已经直接产出完整结构，这里对它们是 no-op。
 */
function normalizeTaskItems(doc: Document): void {
  doc.querySelectorAll<HTMLLIElement>('li[data-checked]').forEach((li) => {
    const hasLabel = Array.from(li.children).some((child) => child.tagName === 'LABEL')
    if (hasLabel) return

    const label = doc.createElement('label')
    const input = doc.createElement('input')
    input.type = 'checkbox'
    input.checked = li.dataset.checked === 'true'
    label.append(input, doc.createElement('span'))

    const div = doc.createElement('div')
    while (li.firstChild) {
      div.appendChild(li.firstChild)
    }

    li.append(label, div)
  })
}

/** 表格外面套一层横向滚动容器。 */
function wrapTables(doc: Document): void {
  doc.querySelectorAll('table').forEach((table) => {
    if (table.parentElement?.classList.contains('table-wrap')) return
    const wrap = doc.createElement('div')
    wrap.className = 'table-wrap'
    table.parentNode?.insertBefore(wrap, table)
    wrap.appendChild(table)
  })
}

/**
 * 代码块：用 highlight.js 重新上色，并补语言标签与复制按钮。
 *
 * TipTap 编辑器里的高亮是 decoration，getHTML() 不会把 hljs-* 写进正文，
 * 所以阅读态必须再跑一次（docs-ai/v7/frontend/frontend.md 第四节）。
 */
function decorateCodeBlocks(doc: Document): void {
  doc.querySelectorAll('pre').forEach((pre) => {
    const code = pre.querySelector('code')
    if (!code) return

    const langClass = Array.from(code.classList).find((name) => name.startsWith('language-'))
    const language = langClass ? langClass.slice('language-'.length) : ''
    const raw = code.textContent ?? ''

    code.innerHTML = highlightCode(raw, language)
    code.classList.add('hljs')
    pre.classList.add('hljs')

    // 已经包过就不再重复包（避免 renderHtml 被重复调用时嵌套）。
    if (pre.parentElement?.classList.contains('code-block-wrap')) return

    const wrap = doc.createElement('div')
    wrap.className = 'code-block-wrap'
    pre.parentNode?.insertBefore(wrap, pre)
    wrap.appendChild(pre)

    if (language) {
      const label = doc.createElement('span')
      label.className = 'code-lang'
      label.textContent = displayLanguage(language)
      wrap.appendChild(label)
    }

    const button = doc.createElement('button')
    button.type = 'button'
    button.className = 'code-copy'
    button.dataset.state = 'idle'
    button.textContent = '复制'
    wrap.appendChild(button)
  })
}
