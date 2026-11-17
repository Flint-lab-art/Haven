import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * 明细行的两级分类控件：先选收支，再选分类。
 *
 * 关键约束：收支方向变了，分类必须跟着落到该方向的合法值，
 * 否则后端会以「分类与方向不一致」拒绝保存。
 */
vi.mock('@/api/ledger', () => ({
  getLedgerSummary: vi.fn(async () => ({
    month: '2026-11',
    total_expense_cents: 2000,
    total_income_cents: 0,
    total_count: 1,
    category_ranking: [],
    income_category_ranking: [],
    daily: [],
    recent: [],
  })),
  listLedgerEntries: vi.fn(async () => ({
    items: [
      {
        id: 'entry-1',
        type: 'expense',
        amount_cents: 2000,
        category: '餐饮',
        note: '午饭',
        occurred_at: '2026-11-17T12:00:00+08:00',
        batch_id: 'b',
        created_at: '2026-11-17T12:00:00+08:00',
      },
    ],
    total: 1,
  })),
  updateLedgerEntry: vi.fn(),
  createLedgerBatch: vi.fn(),
  quickParse: vi.fn(),
}))

const { updateLedgerEntry } = await import('@/api/ledger')
const LedgerView = (await import('@/views/private/LedgerView.vue')).default

describe('明细的两级分类', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setActivePinia(createPinia())
    vi.mocked(updateLedgerEntry).mockResolvedValue({} as never)
    // jsdom 环境可能没有 localStorage；组件已容错，这里给个空实现即可
    vi.stubGlobal('localStorage', {
      getItem: () => null,
      setItem: () => {},
    })
  })

  async function mountView() {
    const wrapper = mount(LedgerView)
    await flushPromises()
    return wrapper
  }

  it('每行有两个控件：收支方向（分段按钮）与具体分类', async () => {
    const wrapper = await mountView()
    const row = wrapper.find('.ledger-entry')
    expect(row.exists()).toBe(true)

    // 收支做成两枚按钮，一眼能看出是两选一
    const typeButtons = row.findAll('.ledger-entry__type-btn')
    expect(typeButtons.map((b) => b.text())).toEqual(['支', '收'])
    // 当前是支出，第一枚应为选中态
    expect(typeButtons[0].classes()).toContain('is-active')

    const catSelect = row.find('select.ledger-entry__cat')
    expect(catSelect.exists()).toBe(true)
  })

  it('分类下拉只列当前方向下的分类', async () => {
    const wrapper = await mountView()
    const options = wrapper
      .find('select.ledger-entry__cat')
      .findAll('option')
      .map((o) => o.text())

    expect(options).toContain('餐饮')
    expect(options).toContain('Token')
    // 收入分类不该出现在支出行的下拉里
    expect(options).not.toContain('工资')
  })

  it('点「收」把支出改成收入时，分类同时切到收入分类并发一次请求', async () => {
    const wrapper = await mountView()
    // 第二枚按钮是「收」
    await wrapper.findAll('.ledger-entry__type-btn')[1].trigger('click')
    await flushPromises()

    expect(updateLedgerEntry).toHaveBeenCalledTimes(1)
    const [, payload] = vi.mocked(updateLedgerEntry).mock.calls[0]
    expect(payload).toMatchObject({ type: 'income' })
    // 分类必须换成收入方向下的合法值，不能还是「餐饮」
    expect(payload.category).toBe('工资')
  })

  it('切换分类时不带上 type（避免多余字段）', async () => {
    const wrapper = await mountView()
    await wrapper.find('select.ledger-entry__cat').setValue('交通')
    await flushPromises()

    expect(updateLedgerEntry).toHaveBeenCalledWith('entry-1', { category: '交通' })
  })
})
