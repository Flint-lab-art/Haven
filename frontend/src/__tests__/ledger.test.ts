import { describe, expect, it } from 'vitest'
import {
  accountTypeLabel,
  currentMonth,
  entryTypeLabel,
  formatSignedYuan,
  formatYuan,
  monthLabel,
  parseYuanToCents,
  shiftMonth,
} from '@/utils/ledger'

/**
 * 记账工具：金额格式化与解析、月份运算。
 *
 * 分类清单已入库（ledger_categories），不再有前端常量需要测。
 */

describe('formatYuan', () => {
  it('整数不显示小数', () => {
    expect(formatYuan(1200)).toBe('¥12')
    expect(formatYuan(100000)).toBe('¥1,000')
  })

  it('有角分时补两位', () => {
    expect(formatYuan(1250)).toBe('¥12.50')
    expect(formatYuan(1205)).toBe('¥12.05')
    expect(formatYuan(1)).toBe('¥0.01')
  })

  it('负数把符号放在 ¥ 前', () => {
    expect(formatYuan(-1200)).toBe('-¥12')
    expect(formatYuan(-2500)).toBe('-¥25')
  })

  it('零', () => {
    expect(formatYuan(0)).toBe('¥0')
  })
})

describe('formatSignedYuan', () => {
  it('收入带 +，支出带 −，转账不带符号', () => {
    expect(formatSignedYuan('income', 80000)).toBe('+¥800')
    expect(formatSignedYuan('expense', 2500)).toBe('-¥25')
    expect(formatSignedYuan('transfer', 100000)).toBe('¥1,000')
  })
})

describe('parseYuanToCents', () => {
  it('整数与小数', () => {
    expect(parseYuanToCents('12')).toBe(1200)
    expect(parseYuanToCents('12.5')).toBe(1250)
    expect(parseYuanToCents('12.50')).toBe(1250)
    expect(parseYuanToCents('0.01')).toBe(1)
  })

  it('容忍货币符号与空格', () => {
    expect(parseYuanToCents('¥12')).toBe(1200)
    expect(parseYuanToCents('12元')).toBe(1200)
    expect(parseYuanToCents(' 12 ')).toBe(1200)
  })

  it('精度不丢：0.1 + 0.2 这类输入走字符串拆分', () => {
    expect(parseYuanToCents('0.29')).toBe(29)
    expect(parseYuanToCents('19.99')).toBe(1999)
    expect(parseYuanToCents('1234.56')).toBe(123456)
  })

  it('非法输入返回 null', () => {
    expect(parseYuanToCents('')).toBeNull()
    expect(parseYuanToCents('abc')).toBeNull()
    expect(parseYuanToCents('12.345')).toBeNull()
    expect(parseYuanToCents('-5')).toBeNull()
  })
})

describe('月份运算', () => {
  it('currentMonth 补零', () => {
    expect(currentMonth(new Date(2026, 0, 15))).toBe('2026-01')
    expect(currentMonth(new Date(2026, 10, 15))).toBe('2026-11')
  })

  it('shiftMonth 跨年正确', () => {
    expect(shiftMonth('2026-01', -1)).toBe('2025-12')
    expect(shiftMonth('2026-12', 1)).toBe('2027-01')
    expect(shiftMonth('2026-11', -1)).toBe('2026-10')
    expect(shiftMonth('2026-11', 3)).toBe('2027-02')
  })

  it('monthLabel 转中文', () => {
    expect(monthLabel('2026-11')).toBe('2026 年 11 月')
    expect(monthLabel('2026-01')).toBe('2026 年 1 月')
  })
})

describe('类型标签', () => {
  it('账户类型', () => {
    expect(accountTypeLabel('cash')).toBe('现金')
    expect(accountTypeLabel('bank')).toBe('储蓄卡')
    expect(accountTypeLabel('credit')).toBe('信用卡')
    expect(accountTypeLabel('ewallet')).toBe('电子钱包')
  })

  it('流水类型', () => {
    expect(entryTypeLabel('expense')).toBe('支出')
    expect(entryTypeLabel('income')).toBe('收入')
    expect(entryTypeLabel('transfer')).toBe('转账')
  })
})
