import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createApp, effectScope, ref } from 'vue'
import { isValidMonth, useLedgerData } from '@/composables/useLedgerData'

/**
 * 记账月度数据：月份校验与请求竞态。
 *
 * 竞态是最容易漏的：快速切月份时旧请求可能后返回，
 * 会把上一个月的明细盖到当前月份上。
 */
vi.mock('@/api/ledger', () => ({
  getSummary: vi.fn(),
  listEntries: vi.fn(),
}))

const { getSummary, listEntries } = await import('@/api/ledger')

function setup() {
  const month = ref('2026-01')
  const typeFilter = ref<'' | 'expense' | 'income' | 'transfer'>('')
  const categoryId = ref<number | null>(null)
  const accountId = ref<string | null>(null)
  const error = ref('')

  const scope = effectScope()
  let api!: ReturnType<typeof useLedgerData>

  const app = createApp({
    setup() {
      api = useLedgerData({
        month,
        typeFilter,
        categoryId,
        accountId,
        error,
        messageOf: (_err, fallback) => fallback,
      })
      return () => null
    },
  })
  scope.run(() => app.mount(document.createElement('div')))

  return { api, month, typeFilter, categoryId, accountId, error, scope }
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

    expect(getSummary).not.toHaveBeenCalled()
    expect(listEntries).not.toHaveBeenCalled()
  })

  it('加载汇总与明细', async () => {
    const { api } = setup()
    vi.mocked(getSummary).mockResolvedValue({ month: '2026-01' } as never)
    vi.mocked(listEntries).mockResolvedValue({ items: [{ id: 'e1' }], total: 1 } as never)

    await api.reload()

    expect(api.summary.value).toMatchObject({ month: '2026-01' })
    expect(api.entries.value).toHaveLength(1)
    expect(api.total.value).toBe(1)
  })

  it('分类筛选会带进查询条件', async () => {
    const { api, categoryId } = setup()
    vi.mocked(getSummary).mockResolvedValue({} as never)
    vi.mocked(listEntries).mockResolvedValue({ items: [], total: 0 } as never)

    categoryId.value = 102
    await api.reload()

    const query = vi.mocked(listEntries).mock.calls[0][0] as Record<string, unknown>
    expect(query.category_id).toBe(102)
  })

  it('收支方向与账户也会带进查询条件', async () => {
    const { api, typeFilter, accountId } = setup()
    vi.mocked(getSummary).mockResolvedValue({} as never)
    vi.mocked(listEntries).mockResolvedValue({ items: [], total: 0 } as never)

    typeFilter.value = 'income'
    accountId.value = 'acc-1'
    await api.reload()

    const query = vi.mocked(listEntries).mock.calls[0][0] as Record<string, unknown>
    expect(query.type).toBe('income')
    expect(query.account_id).toBe('acc-1')
    // 不限分类时不该带 category_id，否则后端会按空值过滤
    expect(query.category_id).toBeUndefined()
  })

  it('按月份带上下界', async () => {
    const { api, month } = setup()
    month.value = '2026-03'
    vi.mocked(getSummary).mockResolvedValue({} as never)
    vi.mocked(listEntries).mockResolvedValue({ items: [], total: 0 } as never)

    await api.reload()

    const query = vi.mocked(listEntries).mock.calls[0][0] as Record<string, unknown>
    const from = new Date(query.from as string)
    const to = new Date(query.to as string)
    expect(from.getMonth()).toBe(2) // 3 月
    expect(from.getDate()).toBe(1)
    expect(to.getMonth()).toBe(3) // 下个月 1 号
    expect(to.getDate()).toBe(1)
  })

  it('快速切月份时丢弃过期响应', async () => {
    const { api, month } = setup()
    vi.mocked(getSummary).mockResolvedValue({} as never)

    // 第一次请求（1 月）挂起
    let resolveJan!: (v: unknown) => void
    vi.mocked(listEntries).mockImplementationOnce(
      () => new Promise((resolve) => (resolveJan = resolve as (v: unknown) => void)),
    ) as never
    const janPromise = api.loadEntries()

    // 切到 2 月并立即完成
    month.value = '2026-02'
    vi.mocked(listEntries).mockResolvedValueOnce({
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

  it('applyEntry 就地替换、removeEntry 就地移除', async () => {
    const { api } = setup()
    vi.mocked(getSummary).mockResolvedValue({} as never)
    vi.mocked(listEntries).mockResolvedValue({
      items: [
        { id: 'e1', category_name: '午餐' },
        { id: 'e2', category_name: '打车' },
      ],
      total: 2,
    } as never)
    await api.reload()

    api.applyEntry({ id: 'e1', category_name: '晚餐' } as never)
    expect(api.entries.value[0]).toMatchObject({ category_name: '晚餐' })

    api.removeEntry('e1')
    expect(api.entries.value.map((e) => e.id)).toEqual(['e2'])
    expect(api.total.value).toBe(1)
  })
})
