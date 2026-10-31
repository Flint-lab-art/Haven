/**
 * 行级 DIFF，用于历史版本浮层（docs/v2/frontend/frontend.md 5.2）。
 *
 * 基准固定为「选中版本 ↔ 当前内容」：回答「这个旧版本和我现在写的差在哪」。
 * 只做按行比较，不引入第三方 DIFF 库；正文是 Markdown 纯文本，行级足够。
 */

export type DiffKind = 'same' | 'added' | 'removed'

export interface DiffLine {
  kind: DiffKind
  /** 该行内容（不含换行符）。 */
  text: string
  /** 在「旧版本」里的行号（1 基）；新增行没有。 */
  oldLine?: number
  /** 在「当前内容」里的行号（1 基）；删除行没有。 */
  newLine?: number
}

/**
 * 比较两个文本，返回按顺序排列的 DIFF 行。
 *
 * @param oldText 旧版本正文（快照）
 * @param newText 当前编辑器正文
 */
export function diffLines(oldText: string, newText: string): DiffLine[] {
  const oldLines = splitLines(oldText)
  const newLines = splitLines(newText)

  // LCS 表：dp[i][j] = oldLines[i:] 与 newLines[j:] 的最长公共子序列长度
  const dp: number[][] = Array.from({ length: oldLines.length + 1 }, () =>
    new Array<number>(newLines.length + 1).fill(0),
  )
  for (let i = oldLines.length - 1; i >= 0; i -= 1) {
    for (let j = newLines.length - 1; j >= 0; j -= 1) {
      dp[i][j] =
        oldLines[i] === newLines[j]
          ? dp[i + 1][j + 1] + 1
          : Math.max(dp[i + 1][j], dp[i][j + 1])
    }
  }

  const out: DiffLine[] = []
  let i = 0
  let j = 0
  while (i < oldLines.length && j < newLines.length) {
    if (oldLines[i] === newLines[j]) {
      out.push({ kind: 'same', text: oldLines[i], oldLine: i + 1, newLine: j + 1 })
      i += 1
      j += 1
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      out.push({ kind: 'removed', text: oldLines[i], oldLine: i + 1 })
      i += 1
    } else {
      out.push({ kind: 'added', text: newLines[j], newLine: j + 1 })
      j += 1
    }
  }
  while (i < oldLines.length) {
    out.push({ kind: 'removed', text: oldLines[i], oldLine: i + 1 })
    i += 1
  }
  while (j < newLines.length) {
    out.push({ kind: 'added', text: newLines[j], newLine: j + 1 })
    j += 1
  }
  return out
}

/** 统计各类行数，供浮层顶部展示「+2 −1」。 */
export function diffStats(lines: DiffLine[]): { added: number; removed: number } {
  let added = 0
  let removed = 0
  for (const line of lines) {
    if (line.kind === 'added') added += 1
    if (line.kind === 'removed') removed += 1
  }
  return { added, removed }
}

/** 按行切分；空串视为 0 行，末尾换行不额外产生空行。 */
function splitLines(text: string): string[] {
  if (text === '') return []
  const normalized = text.replace(/\r\n/g, '\n')
  const lines = normalized.split('\n')
  if (lines.length > 0 && lines[lines.length - 1] === '') {
    lines.pop()
  }
  return lines
}
