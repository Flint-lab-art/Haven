import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import {
  EXPENSE_CATEGORIES,
  INCOME_CATEGORIES,
  LEDGER_CATEGORIES,
  categoriesForType,
  categoryColor,
  categoryTone,
  currentMonth,
  formatSignedYuan,
  formatYuan,
  fromLocalDateTimeInput,
  monthRange,
  parseYuanToCents,
  shiftMonth,
  toLocalDateTimeInput,
} from '@/utils/ledger'

/**
 * 记账页路由与展示工具。
 *
 * 路由部分验证 /ledger 在私有域、需要登录、没有中间列表栏；
 * 工具部分验证「分」的格式化、金额输入和月份边界。
 */
const auth = { initialized: true, isLoggedIn: false, refresh: vi.fn(async () => {}) }

vi.mock('@/stores/auth', () => ({ useAuthStore: () => auth }))

async function loadRouter() {
  vi.resetModules()
  const mod = await import('@/router/index')
  return mod.default
}

beforeEach(() => {
  vi.spyOn(window, 'scrollTo').mockImplementation(() => {})
  setActivePinia(createPinia())
  auth.initialized = true
  auth.isLoggedIn = false
})

afterEach(() => {
  vi.clearAllMocks()
})

describe('记账路由', () => {
  it('未登录访问 /ledger 跳登录并保留 redirect', async () => {
    const router = await loadRouter()

    await router.push('/ledger')
    expect(router.currentRoute.value.name).toBe('login')
    expect(router.currentRoute.value.query.redirect).toBe('/ledger')
  })

  it('已登录可以进入 /ledger，且 section 为 ledger、无列表栏', async () => {
    auth.isLoggedIn = true
    const router = await loadRouter()

    await router.push('/ledger')
    expect(router.currentRoute.value.name).toBe('ledger')
    expect(router.currentRoute.value.meta.section).toBe('ledger')
    expect(router.currentRoute.value.meta.noList).toBe(true)
  })

  it('公开域不注册 /ledger', async () => {
    const router = await loadRouter()
    const publicRoutes = router
      .getRoutes()
      .filter((record) => record.path.startsWith('/public'))
      .map((record) => String(record.name ?? ''))
    expect(publicRoutes).not.toContain('ledger')
  })
})

describe('记账展示工具', () => {
  it('分类保持单层，支出与收入使用各自的大类', () => {
    expect(EXPENSE_CATEGORIES).toEqual(['餐饮', '购物', '交通', '居家', '娱乐', '医疗', '未分类'])
    expect(INCOME_CATEGORIES).toEqual(['工资', '奖金', '报销', '退款', '红包', '其他收入'])
    expect(LEDGER_CATEGORIES).toHaveLength(13)
    expect(categoriesForType('expense')).toEqual(EXPENSE_CATEGORIES)
    expect(categoriesForType('income')).toEqual(INCOME_CATEGORIES)
    // 老数据里方向与分类不匹配时，把原值补进选项，避免静默改分类
    expect(categoriesForType('income', '未分类')).toEqual([...INCOME_CATEGORIES, '未分类'])
    expect(categoryTone('餐饮')).toBe('food')
    expect(categoryTone('交通')).toBe('transit')
    expect(categoryTone('工资')).toBe('salary')
    expect(categoryTone('退款')).toBe('refund')
    expect(categoryTone('未知')).toBe('other')
    // 图表用的颜色与列表色阶一一对应
    expect(categoryColor('餐饮')).toBe('var(--warning)')
    expect(categoryColor('工资')).toBe('var(--success)')
    expect(categoryColor('未知')).toBe('var(--label-3)')
  })

  it('分格式化为元，整数不显示小数', () => {
    expect(formatYuan(1200)).toBe('¥12')
    expect(formatYuan(128600)).toBe('¥1,286')
    expect(formatYuan(1234)).toBe('¥12.34')
    expect(formatSignedYuan('expense', 1200)).toBe('-¥12')
    expect(formatSignedYuan('income', 10000)).toBe('+¥100')
  })

  it('金额输入支持 ¥ / 元 / 块 与两位小数', () => {
    expect(parseYuanToCents('12')).toBe(1200)
    expect(parseYuanToCents('12.5')).toBe(1250)
    expect(parseYuanToCents('¥32')).toBe(3200)
    expect(parseYuanToCents('32元')).toBe(3200)
    expect(parseYuanToCents('0.01')).toBe(1)
    expect(parseYuanToCents('12.345')).toBeNull()
    expect(parseYuanToCents('abc')).toBeNull()
    expect(parseYuanToCents('')).toBeNull()
  })

  it('月份加减跨年', () => {
    expect(shiftMonth('2026-11', 1)).toBe('2026-12')
    expect(shiftMonth('2026-12', 1)).toBe('2027-01')
    expect(shiftMonth('2026-01', -1)).toBe('2025-12')
    expect(currentMonth(new Date(2026, 10, 13))).toBe('2026-11')
  })

  it('月份区间带本地时区偏移，且为左闭右开', () => {
    const range = monthRange('2026-11')
    expect(range.from).toMatch(/^2026-11-01T00:00:00[+-]\d{2}:\d{2}$/)
    expect(range.to).toMatch(/^2026-12-01T00:00:00[+-]\d{2}:\d{2}$/)
    expect(new Date(range.from).getDate()).toBe(1)
    expect(new Date(range.to).getMonth()).toBe(11)
  })

  it('datetime-local 与带时区 ISO 互转', () => {
    const input = toLocalDateTimeInput('2026-11-13T12:30:00+08:00')
    expect(input).toBe('2026-11-13T12:30')

    const iso = fromLocalDateTimeInput('2026-11-13T12:30')
    expect(iso).toMatch(/^2026-11-13T12:30:00[+-]\d{2}:\d{2}$/)
    expect(fromLocalDateTimeInput('2026-11-13')).toBeNull()
  })
})