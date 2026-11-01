import { describe, expect, it } from 'vitest'
import { BRAND_GROUPS, BRAND_ICONS, brandColor, searchBrandGroups, searchBrandIcons } from '@/utils/brand-icons'

/** 品牌图标库（docs/v4/frontend/frontend.md 第四节）。 */
describe('brand-icons', () => {
  it('每个图标都有 key、label 和合法的 SVG', () => {
    expect(BRAND_ICONS.length).toBeGreaterThan(30)
    for (const icon of BRAND_ICONS) {
      expect(icon.key).toBeTruthy()
      expect(icon.label).toBeTruthy()
      expect(icon.svg).toContain('<svg')
    }
  })

  it('key 唯一', () => {
    const keys = BRAND_ICONS.map((i) => i.key)
    expect(new Set(keys).size).toBe(keys.length)
  })

  it('每个图标都有品牌色', () => {
    for (const icon of BRAND_ICONS) {
      expect(icon.color).toMatch(/^#[0-9A-Fa-f]{6}$/)
    }
  })

  it('纯黑品牌色换成 currentColor，避免深色主题下看不见', () => {
    const black = BRAND_ICONS.filter((i) => i.color.toLowerCase() === '#000000')
    expect(black.length).toBeGreaterThan(0)
    for (const icon of black) {
      expect(brandColor(icon)).toBe('currentColor')
    }
  })

  it('有颜色的品牌保留原色', () => {
    const go = BRAND_ICONS.find((i) => i.key === 'go')!
    expect(brandColor(go)).toBe('#00ADD8')
  })

  it('包含常见语言', () => {
    const labels = BRAND_ICONS.map((i) => i.label)
    for (const name of ['Go', 'Python', 'Java', 'Rust', 'TypeScript', 'Vue']) {
      expect(labels).toContain(name)
    }
  })

  it('空关键字返回全部', () => {
    expect(searchBrandIcons('')).toHaveLength(BRAND_ICONS.length)
    expect(searchBrandIcons('   ')).toHaveLength(BRAND_ICONS.length)
  })

  it('按 key 搜索，大小写不敏感', () => {
    expect(searchBrandIcons('go').some((i) => i.key === 'go')).toBe(true)
    expect(searchBrandIcons('PYTHON').some((i) => i.key === 'python')).toBe(true)
  })

  it('按显示名搜索', () => {
    const result = searchBrandIcons('Java')
    expect(result.some((i) => i.label === 'Java')).toBe(true)
  })

  it('没有匹配时返回空数组', () => {
    expect(searchBrandIcons('zzzz-不存在')).toEqual([])
  })

  it('分组都有名称且非空，扁平数组等于各组拼接', () => {
    expect(BRAND_GROUPS.length).toBeGreaterThan(3)
    for (const g of BRAND_GROUPS) {
      expect(g.label).toBeTruthy()
      expect(g.items.length).toBeGreaterThan(0)
    }
    expect(BRAND_ICONS).toEqual(BRAND_GROUPS.flatMap((g) => g.items))
  })

  it('命中分类名时返回整组', () => {
    const result = searchBrandGroups('前端')
    expect(result).toHaveLength(1)
    expect(result[0].label).toBe('前端')
    expect(result[0].items.some((i) => i.key === 'vuedotjs')).toBe(true)
  })

  it('命中图标名时只返回命中的项，并保留原分组', () => {
    const result = searchBrandGroups('go')
    const keys = result.flatMap((g) => g.items.map((i) => i.key))
    expect(keys).toContain('go')
    // 分组标签仍然来自原始分组
    const langGroup = result.find((g) => g.items.some((i) => i.key === 'go'))
    expect(langGroup?.label).toBe('语言')
  })

  it('空搜索返回全部分组', () => {
    expect(searchBrandGroups('')).toHaveLength(BRAND_GROUPS.length)
  })
})
