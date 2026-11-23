import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import LedgerEntryDialog from '@/components/ledger/LedgerEntryDialog.vue'
import type { Account, Category } from '@/api/ledger'

/**
 * 守住记账弹窗的字段可得性契约。
 *
 * 支出/收入模式下「账户」是唯一账户控件；切到转账后同一位置变成「转出账户」，
 * 再加上「转入账户」。aria-label 必须跟着标签一起变，否则：
 * - 屏幕阅读器读不出来这是哪个账户；
 * - E2E 的 getByLabel('账户') 会同时命中两个控件，报 strict mode violation。
 */
const accounts: Account[] = [
  { id: 'a1', name: '工资卡', icon: '', type: 'bank', initial_balance_cents: 0, balance_cents: 0, sort_order: 0, archived: false },
  { id: 'a2', name: '微信', icon: '', type: 'ewallet', initial_balance_cents: 0, balance_cents: 0, sort_order: 1, archived: false },
]

const categories: Category[] = [
  { id: 1, parent_id: null, name: '餐饮', icon: '🍜', kind: 'expense', sort_order: 1, children: [] },
]

async function mountDialog() {
  const wrapper = mount(LedgerEntryDialog, {
    props: { entry: null, accounts, categories },
    attachTo: document.body,
  })
  await nextTick()
  return wrapper
}

function labeledSelect(label: string): HTMLSelectElement | undefined {
  return Array.from(document.querySelectorAll('select')).find(
    (el) => el.getAttribute('aria-label') === label,
  ) as HTMLSelectElement | undefined
}

describe('LedgerEntryDialog 账户字段契约', () => {
  it('支出模式下只有一个「账户」控件', async () => {
    const wrapper = await mountDialog()

    expect(labeledSelect('账户')).toBeTruthy()
    expect(labeledSelect('转出账户')).toBeUndefined()
    expect(labeledSelect('转入账户')).toBeUndefined()
    wrapper.unmount()
  })

  it('切到转账后「账户」变成「转出账户」，并出现「转入账户」', async () => {
    const wrapper = await mountDialog()

    const transferTab = Array.from(document.querySelectorAll('[role="tab"]')).find(
      (el) => el.textContent?.trim() === '转账',
    ) as HTMLElement
    transferTab.click()
    await nextTick()

    expect(labeledSelect('账户')).toBeUndefined()
    expect(labeledSelect('转出账户')).toBeTruthy()
    expect(labeledSelect('转入账户')).toBeTruthy()
    wrapper.unmount()
  })
})