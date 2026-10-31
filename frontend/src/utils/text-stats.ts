/**
 * 正文字数统计。
 *
 * 规则（混合中英文的常见口径）：
 * - 中日韩字符每个算 1 个字；
 * - 连续的拉丁字母 / 数字算 1 个字（按单词计）；
 * - Markdown 标记符号（# * ` - > 等）与空白不计入。
 *
 * 只做展示用途，不参与保存或权限判断。
 */

/** 中日韩文字与全角标点所在的字符区间。 */
const CJK = /[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]/g

/** 连续的拉丁字母或数字（一个英文单词算 1）；带点的标识符如 console.log 也整体算 1。 */
const LATIN_WORD = /[A-Za-z0-9]+(?:[.'’_-][A-Za-z0-9]+)*/g

/**
 * 去掉不影响字数的 Markdown 语法噪音，避免把 `**`、`#` 数进去。
 * 只做粗略清理，不追求解析器的严谨性。
 */
function stripMarkdown(text: string): string {
  return (
    text
      // 代码块围栏
      .replace(/^```.*$/gm, '')
      // 行内代码的反引号
      .replace(/`/g, '')
      // 标题、引用、列表、任务框标记
      .replace(/^[ \t]*(?:#{1,6}|>|[-*+]|\d+\.)[ \t]+/gm, '')
      .replace(/^[ \t]*-[ \t]\[[ xX]\][ \t]+/gm, '')
      // 强调符号
      .replace(/[*_~]{1,3}/g, '')
      // 图片 ![alt](url) 整个去掉；必须放在链接规则之前，
      // 否则会先被当成链接、把 alt 文字留下
      .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
      // 链接 [文字](url) 只保留文字
      .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
  )
}

/**
 * 统计一段 Markdown 的字数。
 *
 * 中文字符逐字计数，英文与数字按单词计数，两者相加。
 */
export function countWords(markdown: string): number {
  if (!markdown) return 0
  const text = stripMarkdown(markdown)
  const cjk = text.match(CJK)?.length ?? 0
  const latin = text.replace(CJK, ' ').match(LATIN_WORD)?.length ?? 0
  return cjk + latin
}

/**
 * 把字数换算成阅读时长文案，按中文阅读速度 300 字/分钟估算。
 * 不足 1 分钟显示「不到 1 分钟」。
 */
export function formatReadingTime(words: number): string {
  if (words <= 0) return '还没有内容'
  const minutes = Math.ceil(words / 300)
  return minutes <= 1 ? '不到 1 分钟' : `${minutes} 分钟`
}
