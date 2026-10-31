import { describe, expect, it } from 'vitest'
import { EMOJI_CHOICES, EMOJI_GROUPS, searchEmojiGroups } from '@/utils/emoji'

/** 内置 emoji（docs/v4/frontend/frontend.md 3.3）。 */
describe('emoji', () => {
  it('数量在 300 上下', () => {
    expect(EMOJI_CHOICES.length).toBeGreaterThanOrEqual(280)
    expect(EMOJI_CHOICES.length).toBeLessThanOrEqual(400)
  })

  it('分组都有名称且非空', () => {
    for (const group of EMOJI_GROUPS) {
      expect(group.label).toBeTruthy()
      expect(group.items.length).toBeGreaterThan(0)
    }
  })

  it('扁平数组等于各组拼接', () => {
    const flat = EMOJI_GROUPS.flatMap((g) => g.items)
    expect(EMOJI_CHOICES).toEqual(flat)
  })

  it('没有空字符串或重复项', () => {
    expect(EMOJI_CHOICES.every((e) => e.length > 0)).toBe(true)
    expect(new Set(EMOJI_CHOICES).size).toBe(EMOJI_CHOICES.length)
  })

  it('每项都是非 ASCII 的 emoji', () => {
    for (const e of EMOJI_CHOICES) {
      expect(e.codePointAt(0)).toBeGreaterThan(0x2000)
    }
  })

  it('空关键字返回全部分组', () => {
    expect(searchEmojiGroups('')).toHaveLength(EMOJI_GROUPS.length)
    expect(searchEmojiGroups('   ')).toHaveLength(EMOJI_GROUPS.length)
  })

  it('按分组名搜索', () => {
    const result = searchEmojiGroups('技术')
    expect(result).toHaveLength(1)
    expect(result[0].label).toBe('技术')
  })

  it('没有匹配返回空数组', () => {
    expect(searchEmojiGroups('不存在的分类')).toEqual([])
  })
})
