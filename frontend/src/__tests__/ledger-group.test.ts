import { describe, expect, it } from 'vitest'
import {
  dayLabel,
  groupByDay,
  localDateKey,
  relativeDayLabel,
  weekdayOf,
} from '@/utils/ledger-group'
import type { LedgerEntry } from '@/api/ledger'

/**
 * 按天分组。
 *
 * 最容易被忽略的是**时区**：如果用 toISOString().slice(0,10) 取日期，
 * 东八区凌晨 0~8 点的记录会被分到前一天——用户记完当天的早饭，
 * 却在「昨天」那一组里看到它。
 */
function entry(overrides: Partial<LedgerEntry> & { occurred_at: string }): LedgerEntry {
  return {
    id: Math.random().toString(36).slice(2),
    type: 'expense',
    amount_cents: 1000,
    category: '餐饮',
    note: '',
    batch_id: 'b',
    created_at: overrides.occurred_at,
    ...overrides,
  }
}

describe('按天分组', () => {
  it('同一天归到一组，组内按时间倒序', () => {
    const groups = groupByDay([
      entry({ occurred_at: '2026-11-17T08:00:00+08:00' }),
      entry({ occurred_at: '2026-11-17T20:00:00+08:00' }),
      entry({ occurred_at: '2026-11-17T12:00:00+08:00' }),
    ])

    expect(groups).toHaveLength(1)
    expect(groups[0].items.map((e) => new Date(e.occurred_at).getHours())).toEqual([20, 12, 8])
  })

  it('组之间按日期倒序，最新的在前', () => {
    const groups = groupByDay([
      entry({ occurred_at: '2026-11-15T10:00:00+08:00' }),
      entry({ occurred_at: '2026-11-17T10:00:00+08:00' }),
      entry({ occurred_at: '2026-11-16T10:00:00+08:00' }),
    ])

    expect(groups.map((g) => g.date)).toEqual(['2026-11-17', '2026-11-16', '2026-11-15'])
  })

  it('分别统计当天支出与收入', () => {
    const groups = groupByDay([
      entry({ occurred_at: '2026-11-17T09:00:00+08:00', type: 'expense', amount_cents: 2500 }),
      entry({ occurred_at: '2026-11-17T19:00:00+08:00', type: 'income', amount_cents: 800000 }),
      entry({ occurred_at: '2026-11-17T20:00:00+08:00', type: 'expense', amount_cents: 1500 }),
    ])

    expect(groups[0].expenseCents).toBe(4000)
    expect(groups[0].incomeCents).toBe(800000)
  })

  it('带星期与日期标题', () => {
    const [group] = groupByDay([entry({ occurred_at: '2026-11-17T10:00:00+08:00' })])

    expect(group.label).toBe('11月17日')
    // 2026-11-17 是周二
    expect(group.weekday).toBe('周二')
  })

  it('非法时间被跳过而不是抛错', () => {
    const groups = groupByDay([entry({ occurred_at: 'not-a-date' })])
    expect(groups).toHaveLength(0)
  })
})

describe('本地日期键', () => {
  it('用本地时区取日期，不是 UTC', () => {
    // 东八区的 2026-11-17 00:30，转成 UTC 是 16 日 16:30。
    // 用 ISO 字符串截日期会得到 16 日，用户会看到「昨天」多了一笔。
    const key = localDateKey('2026-11-17T00:30:00+08:00')
    // 测试机时区不同结果也不同，这里只断言它与本地 Date 一致
    const d = new Date('2026-11-17T00:30:00+08:00')
    const expected = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    expect(key).toBe(expected)
  })

  it('与 ISO 截取结果不同（说明确实用了本地时区）', () => {
    // 仅当本机不在 UTC 时成立；CI 通常在 UTC，所以这条需要有条件地放宽
    const iso = '2026-11-17T00:30:00+08:00'
    const d = new Date(iso)
    if (d.getTimezoneOffset() === 0) {
      expect(localDateKey(iso)).toBe('2026-11-16')
      return
    }
    expect(localDateKey(iso)).not.toBe(d.toISOString().slice(0, 10))
  })
})

describe('日期标签', () => {
  it('dayLabel 输出中文月日', () => {
    expect(dayLabel('2026-11-05')).toBe('11月5日')
  })

  it('weekdayOf 输出星期', () => {
    expect(weekdayOf('2026-11-17')).toBe('周二')
    expect(weekdayOf('2026-11-22')).toBe('周日')
  })

  it('今天与昨天用相对标题，其余保持绝对日期', () => {
    const today = new Date(2026, 10, 17)
    expect(relativeDayLabel('11月17日', '2026-11-17', today)).toBe('今天')
    expect(relativeDayLabel('11月16日', '2026-11-16', today)).toBe('昨天')
    expect(relativeDayLabel('11月15日', '2026-11-15', today)).toBe('11月15日')
  })
})
