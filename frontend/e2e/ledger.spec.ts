import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 记账（PC 端）：账户、两级分类、转账、预算。
 *
 * 造数据走 API，**用户可见结果用界面断言**。
 * 重点验三件事：
 * 1. 转账不计入收支统计（模型最容易出错的点）；
 * 2. 二级分类的支出能归到一级（预算与统计都靠这条）；
 * 3. 金额按整数分存储，小数不丢精度。
 */

/** 建一个可用账户，返回 id。 */
async function seedAccount(api: ReturnType<typeof createApi>, name = '工资卡', initial = 1_000_000) {
  return api.createAccount({ name, type: 'bank', initialBalanceCents: initial })
}

test('记一笔支出后出现在列表，月度汇总同步', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const account = await seedAccount(api)
  const lunch = await api.categoryIdByName('餐饮', '午餐')

  await page.goto('/ledger')
  await page.getByRole('button', { name: '记一笔' }).click()

  const dialog = page.getByRole('dialog', { name: '记一笔' })
  await expect(dialog).toBeVisible()

  // 选分类：点「餐饮」进下钻，再点「午餐」
  await dialog.getByRole('radio', { name: /餐饮/ }).click()
  await dialog.getByRole('radio', { name: /午餐/ }).click()

  await dialog.getByLabel('金额').fill('35')
  await dialog.getByLabel('账户').selectOption(account.id)
  await dialog.getByRole('button', { name: '保存' }).click()

  await expect(dialog).toBeHidden()

  // 列表出现这一笔
  await expect(page.locator('.ledger-list-row').filter({ hasText: '午餐' })).toHaveCount(1)
  // 汇总支出 = 35
  await expect(page.locator('.ledger-hero__item-value').first()).toContainText('35')

  // 落库确认
  const { items } = await api.ledgerEntries()
  expect(items).toHaveLength(1)
  expect(items[0]).toMatchObject({ type: 'expense', amount_cents: 3500, category_id: lunch })
})

test('转账两个账户一减一增，且不计入收支统计', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const bank = await seedAccount(api, '工资卡', 1_000_000)
  const wallet = await api.createAccount({ name: '微信', type: 'ewallet', initialBalanceCents: 0 })

  await page.goto('/ledger')
  await page.getByRole('button', { name: '记一笔' }).click()
  const dialog = page.getByRole('dialog', { name: '记一笔' })

  await dialog.getByRole('tab', { name: '转账' }).click()
  await dialog.getByLabel('金额').fill('1000')
  await dialog.getByLabel('转出账户').selectOption(bank.id)
  await dialog.getByLabel('转入账户').selectOption(wallet.id)
  await dialog.getByRole('button', { name: '保存' }).click()
  await expect(dialog).toBeHidden()

  // 列表里能看到转账
  await expect(page.locator('.ledger-list-row').filter({ hasText: '转账' })).toHaveCount(1)

  // 关键：支出与收入都还是 0
  await expect(page.locator('.ledger-hero__item-value').first()).toContainText('¥0')

  // 账户余额：工资卡 10000-1000，微信 +1000
  const res = await page.request.get('/api/ledger/accounts')
  expect(res.ok()).toBeTruthy()
  const list = (await res.json()) as { id: string; balance_cents: number }[]
  expect(list.find((a) => a.id === bank.id)?.balance_cents).toBe(900_000)
  expect(list.find((a) => a.id === wallet.id)?.balance_cents).toBe(100_000)
})

test('小数金额按分存储不丢精度', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const account = await seedAccount(api)
  const coffee = await api.categoryIdByName('餐饮', '零食饮料')

  await api.createLedgerEntry({ type: 'expense', amountCents: 2550, categoryId: coffee, accountId: account.id })

  await page.goto('/ledger')
  await expect(page.locator('.ledger-list-row')).toHaveCount(1)
  await expect(page.locator('.ledger-list-row__amount').first()).toContainText('25.50')

  const { items } = await api.ledgerEntries()
  expect(items[0].amount_cents).toBe(2550)
})

test('二级分类支出能归到一级，月度汇总按大类显示', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const account = await seedAccount(api)
  const lunch = await api.categoryIdByName('餐饮', '午餐')
  const snacks = await api.categoryIdByName('餐饮', '零食饮料')

  await api.createLedgerEntry({ type: 'expense', amountCents: 2000, categoryId: lunch, accountId: account.id })
  await api.createLedgerEntry({ type: 'expense', amountCents: 1000, categoryId: snacks, accountId: account.id })

  await page.goto('/ledger')
  // 两笔都在列表里，且都显示「餐饮」作为大类
  await expect(page.locator('.ledger-list-row')).toHaveCount(2)
  await expect(page.locator('.ledger-list-row').first()).toContainText('餐饮')

  // 汇总支出 = 30
  await expect(page.locator('.ledger-hero__item-value').first()).toContainText('30')
})

test('可以切换月份，上个月的记录不会混进本月', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const account = await seedAccount(api)
  const lunch = await api.categoryIdByName('餐饮', '午餐')

  // 建一笔上个月的
  const lastMonth = new Date()
  lastMonth.setMonth(lastMonth.getMonth() - 1)
  lastMonth.setDate(15)
  await api.createLedgerEntry({
    type: 'expense',
    amountCents: 9900,
    categoryId: lunch,
    accountId: account.id,
    occurredAt: lastMonth.toISOString(),
  })

  await page.goto('/ledger')
  // 本月没有记录
  await expect(page.locator('.empty__title').filter({ hasText: '这个月还没有记账' })).toBeVisible()

  // 切到上个月
  await page.getByRole('button', { name: '上个月' }).click()
  await expect(page.locator('.ledger-list-row')).toHaveCount(1)
})

test('编辑明细可改金额，保存后列表与汇总同步', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const account = await seedAccount(api)
  const lunch = await api.categoryIdByName('餐饮', '午餐')

  await api.createLedgerEntry({ type: 'expense', amountCents: 4000, categoryId: lunch, accountId: account.id })

  await page.goto('/ledger')
  // 2.5.0 起明细行本身是按钮：点整行进入编辑，行内不再有独立的「编辑」按钮
  await page.locator('.ledger-list-row').first().click()

  const dialog = page.getByRole('dialog', { name: '编辑' })
  await expect(dialog).toBeVisible()
  await dialog.getByLabel('金额').fill('60')
  await dialog.getByRole('button', { name: '保存' }).click()
  await expect(dialog).toBeHidden()

  await expect(page.locator('.ledger-list-row__amount').first()).toContainText('60')
  await expect(page.locator('.ledger-hero__item-value').first()).toContainText('60')

  const { items } = await api.ledgerEntries()
  expect(items[0].amount_cents).toBe(6000)
})

test('删除明细后列表清空', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const account = await seedAccount(api)
  const lunch = await api.categoryIdByName('餐饮', '午餐')
  await api.createLedgerEntry({ type: 'expense', amountCents: 1200, categoryId: lunch, accountId: account.id })

  await page.goto('/ledger')
  // 先点整行打开编辑弹窗，删除按钮在弹窗底部；再走一次二次确认
  await page.locator('.ledger-list-row').first().click()
  const dialog = page.getByRole('dialog', { name: '编辑' })
  await expect(dialog).toBeVisible()
  await dialog.getByRole('button', { name: '删除' }).click()
  await page.getByRole('alertdialog').getByRole('button', { name: '删除' }).click()

  await expect(page.locator('.ledger-list-row')).toHaveCount(0)
  const { total } = await api.ledgerEntries()
  expect(total).toBe(0)
})

test('支出与收入分别汇总，不混在一起', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const account = await seedAccount(api)
  const lunch = await api.categoryIdByName('餐饮', '午餐')

  await api.createLedgerEntry({ type: 'expense', amountCents: 3000, categoryId: lunch, accountId: account.id })
  // 收入：找收入一级下的「工资」
  const roots = await api.categories()
  const incomeRoot = roots.find((c) => c.kind === 'income')
  const salary = incomeRoot?.children.find((c) => c.name === '工资')?.id ?? incomeRoot!.id
  await api.createLedgerEntry({ type: 'income', amountCents: 800_000, categoryId: salary, accountId: account.id })

  await page.goto('/ledger')
  const stats = page.locator('.ledger-hero__item-value')
  await expect(stats.nth(0)).toContainText('30') // 支出
  await expect(stats.nth(1)).toContainText('8,000') // 收入
})

test('没有账户时给出引导，并能从设置建账户', async ({ authedPage: page }) => {
  await page.goto('/ledger')
  await expect(page.getByText('还没有账户')).toBeVisible()

  // 从设置里的账户页建一个
  await page.goto('/settings/accounts')
  await page.getByRole('button', { name: '新建账户' }).click()
  await page.getByLabel('账户名').fill('现金')
  await page.getByLabel('账户类型').selectOption('cash')
  await page.getByRole('button', { name: '保存', exact: true }).click()
  await expect(page.locator('.row-item').filter({ hasText: '现金' })).toBeVisible()

  // 回记账页，引导消失
  await page.goto('/ledger')
  await expect(page.getByText('还没有账户')).toHaveCount(0)
})
