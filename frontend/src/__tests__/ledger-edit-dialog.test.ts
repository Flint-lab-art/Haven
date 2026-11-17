import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import LedgerEditDialog from '@/components/ledger/LedgerEditDialog.vue'

/**
 * 记账编辑弹窗。
 *
 * 从 LedgerView 拆出来后，交互契约变成「v-model:open + @saved(updated)」，
 * 父组件不再持有表单状态。这里固定住三条：
 * 1. 打开时表单预填该条目的值
 * 2. 只提交真正变化的字段（避免无谓写库）
 * 3. 金额非法时给出错误且不发请求
 */
const updateLedgerEntry = vi.fn()
vi.mock('@/api/ledger', () => ({
  updateLedgerEntry: (...args: unknown[]) => updateLedgerEntry(...args),
}))

const entry = {
  id: 'entry-1',
  type: 'expense' as const,
  amount_cents: 2550,
  category: '餐饮' as const,
  note: '午饭',
  occurred_at: '2026-11-17T12:00:00+08:00',
  batch_id: 'b1',
  created_at: '2026-11-17T12:00:00+08:00',
}

describe('LedgerEditDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    updateLedgerEntry.mockResolvedValue({ ...entry, amount_cents: 3000 })
  })

  function mountDialog() {
    return mount(LedgerEditDialog, { props: { open: true, entry } })
  }

  it('打开时表单预填条目的分类、金额与时间', async () => {
    const wrapper = mountDialog()
    await flushPromises()

    expect(wrapper.find('select').element.value).toBe('餐饮')
    const inputs = wrapper.findAll('input')
    expect((inputs[0].element as HTMLInputElement).value).toBe('25.5')
    expect((inputs[1].element as HTMLInputElement).value).toContain('2026-11-17T12:00')
  })

  it('只提交变化的字段', async () => {
    const wrapper = mountDialog()
    await flushPromises()

    // 只把金额从 25.5 改成 30
    await wrapper.findAll('input')[0].setValue('30')
    await wrapper.get('.btn--primary').trigger('click')
    await flushPromises()

    expect(updateLedgerEntry).toHaveBeenCalledWith('entry-1', { amount_cents: 3000 })
    expect(wrapper.emitted('saved')?.[0]?.[0]).toMatchObject({ amount_cents: 3000 })
    expect(wrapper.emitted('update:open')?.[0]).toEqual([false])
  })

  it('没有任何变化时直接关闭，不发请求', async () => {
    const wrapper = mountDialog()
    await flushPromises()

    await wrapper.get('.btn--primary').trigger('click')
    await flushPromises()

    expect(updateLedgerEntry).not.toHaveBeenCalled()
    expect(wrapper.emitted('update:open')?.[0]).toEqual([false])
  })

  it('金额非法时显示错误且不发请求', async () => {
    const wrapper = mountDialog()
    await flushPromises()

    await wrapper.findAll('input')[0].setValue('0')
    await wrapper.get('.btn--primary').trigger('click')
    await flushPromises()

    expect(wrapper.find('.notice--error').exists()).toBe(true)
    expect(updateLedgerEntry).not.toHaveBeenCalled()
    // 弹窗不应关闭，让用户改
    expect(wrapper.emitted('update:open')).toBeUndefined()
  })

  it('保存失败时把错误显示出来，弹窗保持打开', async () => {
    updateLedgerEntry.mockRejectedValueOnce(new Error('网络错误'))

    const wrapper = mountDialog()
    await flushPromises()

    await wrapper.findAll('input')[0].setValue('40')
    await wrapper.get('.btn--primary').trigger('click')
    await flushPromises()

    expect(wrapper.find('.notice--error').text()).toContain('网络错误')
    expect(wrapper.emitted('update:open')).toBeUndefined()
  })

  it('open 为 false 时不渲染内容', () => {
    const wrapper = mount(LedgerEditDialog, { props: { open: false, entry } })
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false)
  })
})
