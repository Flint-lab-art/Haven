import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createApp, effectScope, ref } from 'vue'
import type { LedgerCategory } from '@/api/ledger'
import { isValidMonth, useLedgerData } from '@/composables/useLedgerData'

/**
 * 记账月度数据：月份校验与请求竞态。
 *
 * 竞态是最容易漏的：快速切月份时旧请求可能后返回，
 * 会把上一个月的明细盖到当前月份上。
 */
vi.mock('@/api/ledger', () => ({
  getLedgerSummary: vi.fn(),
  listLedgerEntries: vi.fn(),
}))

const { getLedgerSummary, listLedgerEntries } = await import('@/api/ledger')

function setup() {
  const month = ref('2026-01')
  const typeFilter = ref<'' | 'expense' | 'income'>('')
  const categoryFilter = ref<LedgerCategory | ''>('')
  const error = ref('')

  const scope = effectScope()
  let api!: ReturnType<typeof useLedgerData>

  const app = createApp({
    setup() {
      api = useLedgerData({
        month,
        typeFilter,
        categoryFilter,
        error,
        messageOf: (_err, fallback) => fallback,
      })
      return () => null
    },
  })
  scope.run(() => app.mount(document.createElement('div')))

  return { api, month, typeFilter, categoryFilter, error, scope }
}

describe('isValidMonth', () => {
  it('接受 YYYY-MM', () => {
    expect(isValidMonth('2026-01')).toBe(true)
    expect(isValidMonth('2026-12')).toBe(true)
  })

  it('拒绝非法值', () => {
    expect(isValidMonth('')).toBe(false)
    expect(isValidMonth('abc')).toBe(false)
    expect(isValidMonth('2026-1')).toBe(false)
    expect(isValidMonth('26-01')).toBe(false)
  })
})

describe('useLedgerData', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('非法月份不发请求', async () => {
    const { api, month } = setup()
    month.value = 'abc'

    await api.reload()

    expect(getLedgerSummary).not.toHaveBeenCalled()
    expect(listLedgerEntries).not.toHaveBeenCalled()
  })

  it('加载汇总与明细', async () => {
    const { api } = setup()
    vi.mocked(getLedgerSummary).mockResolvedValue({ month: '2026-01' } as never)
    vi.mocked(listLedgerEntries).mockResolvedValue({ items: [{ id: 'e1' }], total: 1 } as never)

    await api.reload()

    expect(api.summary.value).toMatchObject({ month: '2026-01' })
    expect(api.entries.value).toHaveLength(1)
    expect(api.total.value).toBe(1)
  })

  it('分类筛选会带进查询条件', async () => {
    const { api, categoryFilter } = setup()
    vi.mocked(getLedgerSummary).mockResolvedValue({} as never)
    vi.mocked(listLedgerEntries).mockResolvedValue({ items: [], total: 0 } as never)

    categoryFilter.value = '餐饮'
    await api.reload()

    const query = vi.mocked(listLedgerEntries).mock.calls[0][0] as Record<string, unknown>
    expect(query.category).toBe('餐饮')
  })

  it('收支方向也会带进查询条件', async () => {
    const { api, typeFilter } = setup()
    vi.mocked(getLedgerSummary).mockResolvedValue({} as never)
    vi.mocked(listLedgerEntries).mockResolvedValue({ items: [], total: 0 } as never)

    typeFilter.value = 'income'
    await api.reload()

    const query = vi.mocked(listLedgerEntries).mock.calls[0][0] as Record<string, unknown>
    expect(query.type).toBe('income')
    // 不限方向时不该带 type，否则后端会按空串过滤
    expect(query.category).toBeUndefined()
  })

  it('快速切月份时丢弃过期响应', async () => {
    const { api, month } = setup()
    vi.mocked(getLedgerSummary).mockResolvedValue({} as never)

    // 第一次请求（1 月）挂起
    let resolveJan!: (v: unknown) => void
    vi.mocked(listLedgerEntries).mockImplementationOnce(
      () => new Promise((resolve) => (resolveJan = resolve as (v: unknown) => void)),
    ) as never
    const janPromise = api.loadEntries()

    // 切到 2 月并立即完成
    month.value = '2026-02'
    vi.mocked(listLedgerEntries).mockResolvedValueOnce({
      items: [{ id: 'feb' }],
      total: 1,
    } as never)
    await api.loadEntries()

    expect(api.entries.value).toEqual([{ id: 'feb' }])

    // 1 月的响应现在才回来：应该被丢弃
    resolveJan({ items: [{ id: 'jan' }], total: 9 })
    await janPromise

    expect(api.entries.value).toEqual([{ id: 'feb' }])
    expect(api.total.value).toBe(1)
  })

  it('applyEntry 就地替换一条明细', async () => {
    const { api } = setup()
    vi.mocked(getLedgerSummary).mockResolvedValue({} as never)
    vi.mocked(listLedgerEntries).mockResolvedValue({
      items: [{ id: 'e1', category: '餐饮' }],
      total: 1,
    } as never)
    await api.reload()

    api.applyEntry({ id: 'e1', category: '购物' } as never)

    expect(api.entries.value[0]).toMatchObject({ category: '购物' })
  })
})
