/** 从正文 HTML 提取 H1–H3 标题，供阅读态 / 编辑态的大纲使用。 */
export interface OutlineItem {
  level: number
  text: string
}

/**
 * 解析 HTML 正文里的 H1–H3。
 *
 * 七期起 notes.content 是 HTML；旧 Markdown 由一次性转换命令处理，
 * 阅读态不再保留 Markdown 解析分支。
 */
export function extractHeadings(html: string): OutlineItem[] {
  if (!html.trim()) return []
  if (typeof DOMParser === 'undefined') return []

  const doc = new DOMParser().parseFromString(html, 'text/html')
  return Array.from(doc.querySelectorAll<HTMLElement>('h1, h2, h3'))
    .map((el) => ({
      level: Number(el.tagName.slice(1)),
      text: (el.textContent ?? '').trim(),
    }))
    .filter((item) => item.text.length > 0)
}
