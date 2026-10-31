import { describe, expect, it } from 'vitest'
import { countWords, formatReadingTime } from '@/utils/text-stats'

describe('countWords', () => {
  it('中文逐字计数', () => {
    expect(countWords('你好世界')).toBe(4)
  })

  it('英文按单词计数', () => {
    expect(countWords('hello world')).toBe(2)
    expect(countWords("don't stop")).toBe(2)
  })

  it('中英混排相加', () => {
    expect(countWords('Hello 世界')).toBe(3)
  })

  it('忽略 Markdown 标记', () => {
    expect(countWords('# 标题')).toBe(2)
    expect(countWords('**粗体**文本')).toBe(4)
    // 「列表项」+「第二项」= 6
    expect(countWords('- 列表项\n- 第二项')).toBe(6)
  })

  it('行内代码的反引号不计入', () => {
    expect(countWords('用 `console.log` 调试')).toBe(4)
  })

  it('链接只保留文字、图片整体忽略', () => {
    expect(countWords('[点我](https://example.com)')).toBe(2)
    expect(countWords('![图](a.png)')).toBe(0)
  })

  it('空内容为 0', () => {
    expect(countWords('')).toBe(0)
    expect(countWords('   \n\n')).toBe(0)
  })
})

describe('formatReadingTime', () => {
  it('空内容单独提示', () => {
    expect(formatReadingTime(0)).toBe('还没有内容')
  })

  it('不足 300 字显示不到 1 分钟', () => {
    expect(formatReadingTime(120)).toBe('不到 1 分钟')
    expect(formatReadingTime(300)).toBe('不到 1 分钟')
  })

  it('超过一分钟按分钟取整', () => {
    expect(formatReadingTime(301)).toBe('2 分钟')
    expect(formatReadingTime(1500)).toBe('5 分钟')
  })
})
