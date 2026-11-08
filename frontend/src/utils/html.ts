/**
 * 把 HTML 压成纯文本（字数统计、历史版本 DIFF 用）。
 *
 * 只做展示与比较，不参与保存或权限判断。
 */
export function stripHtml(html: string): string {
  if (!html) return ''
  if (typeof DOMParser === 'undefined') {
    return html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
  }
  const doc = new DOMParser().parseFromString(html, 'text/html')
  return (doc.body.textContent ?? '').replace(/\s+/g, ' ').trim()
}
