/**
 * 把 Markdown 原文压成纯文本，用于列表摘要。
 *
 * content_preview 是后端按原文截断的 Markdown，直接展示会看到 #、*、> 等符号。
 * 这里只做轻量剥离，不追求完整 Markdown 解析；截断导致的半个语法也能退化处理。
 */
export function stripMarkdownPreview(source: string): string {
  return source
    // 代码块整体去掉（列表里展示代码通常没有意义）
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/~~~[\s\S]*?~~~/g, ' ')
    // 行内代码保留内容，去掉反引号
    .replace(/`([^`]*)`/g, '$1')
    // 图片 / 链接保留可读文本
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/\[([^\]]+)\]\[[^\]]*\]/g, '$1')
    // 自动链接先还原成 URL，再统一清 HTML 标签
    .replace(/<((?:https?:\/\/|mailto:)[^>]+)>/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    // 标题 / 引用 / 列表 / 分隔线标记
    .replace(/^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$/gm, '$1')
    .replace(/^\s{0,3}>\s?/gm, '')
    .replace(/^\s{0,3}(?:[-*+]|\d+[.)])\s+/gm, '')
    .replace(/^\[[ xX]\]\s*/gm, '')
    .replace(/^\s{0,3}([-*_])(?:\s*\1){2,}\s*$/gm, ' ')
    .replace(/^\s*(?:=+|-+)\s*$/gm, ' ')
    // 残余的行内标记
    .replace(/[*_~]/g, '')
    .replace(/`/g, '')
    .replace(/\\/g, '')
    // 表格竖线等纯装饰符号
    .replace(/\|/g, ' ')
    // 压平空白
    .replace(/\s+/g, ' ')
    .trim()
}
