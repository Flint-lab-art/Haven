/** 从 Markdown 原文提取 H1–H3 标题，供阅读态 / 编辑态的大纲使用。 */
export interface OutlineItem {
  level: number
  text: string
}

export function extractHeadings(markdown: string): OutlineItem[] {
  const items: OutlineItem[] = []
  let inFence = false

  for (const raw of markdown.split(/\r?\n/)) {
    const line = raw.trimEnd()
    if (/^\s*(```|~~~)/.test(line)) {
      inFence = !inFence
      continue
    }
    if (inFence) continue

    const match = /^(#{1,3})\s+(.+?)\s*#*\s*$/.exec(line)
    if (!match) continue

    const text = match[2]
      .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
      .replace(/[*_~`]/g, '')
      .trim()
    if (text) items.push({ level: match[1].length, text })
  }
  return items
}
