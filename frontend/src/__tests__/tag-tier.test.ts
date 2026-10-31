import { describe, expect, it } from 'vitest'

/**
 * 标签色阶的相对分档（docs/v3/frontend/frontend.md 8.2）。
 *
 * 与 TagsView 里的实现保持一致：拿最大引用数当基准按比例分档，
 * 保证数据量小的时候也能拉开色阶。
 */
const TIER_RATIO = [1, 0.5, 0.01] as const

function tier(count: number, max: number): 1 | 2 | 3 | 4 {
  if (max <= 0) return 4
  if (count >= max * TIER_RATIO[0]) return 1
  if (count >= max * TIER_RATIO[1]) return 2
  if (count >= max * TIER_RATIO[2]) return 3
  return 4
}

describe('标签色阶分档', () => {
  it('最大引用数为 2 时分出两档，不留空档', () => {
    expect(tier(2, 2)).toBe(1)
    expect(tier(1, 2)).toBe(2)
  })

  it('最大引用数为 1 时全部落在最高档', () => {
    expect(tier(1, 1)).toBe(1)
  })

  it('最大引用数为 10 时按比例分出三档', () => {
    expect(tier(10, 10)).toBe(1)
    expect(tier(5, 10)).toBe(2)
    expect(tier(4, 10)).toBe(3)
    expect(tier(1, 10)).toBe(3)
  })

  it('没有标签时不会命中高档', () => {
    expect(tier(0, 0)).toBe(4)
  })

  it('引用数越高端位越高（单调）', () => {
    const max = 20
    let prev = 0
    for (const count of [20, 15, 10, 5, 1]) {
      const t = tier(count, max)
      expect(t).toBeGreaterThanOrEqual(prev)
      prev = t
    }
  })
})
