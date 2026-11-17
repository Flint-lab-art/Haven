import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 记账：快捷解析预览、确认写入、月度汇总、切月份、改分类、还款分类、删除。
 *
 * 记账是「解析自由文本」的入口，最容易出现「解析结果和写库结果不一致」：
 * 预览看到的和真正写进去的必须一致，所以两条路径都要验。
 */

test('快捷输入能解析出预览条目', async ({ authedPage: page }) => {
  await page.goto('/ledger')

  await page.getByLabel('记账输入').fill('早餐 12\n打车 25.5')
  await page.getByRole('button', { name: '解析预览' }).click()

  // 预览行按解析结果渲染
  const rows = page.locator('.ledger-parse__row')
  await expect(rows).toHaveCount(2)
  await expect(rows.first()).toContainText('早餐')
  await expect(rows.first()).toContainText('12')
  await expect(rows.nth(1)).toContainText('打车')
})

test('确认写入后明细出现，月度汇总同步更新', async ({ authedPage: page }) => {
  await page.goto('/ledger')

  await page.getByLabel('记账输入').fill('早餐 30\n午餐 20')
  await page.getByRole('button', { name: '解析预览' }).click()
  await page.getByRole('button', { name: /确认写入 2 笔/ }).click()

  // 明细列表出现两行
  const entries = page.locator('.ledger-entry')
  await expect(entries).toHaveCount(2)

  // 汇总支出 = 50
  await expect(page.locator('.ledger-total__value')).toContainText('50')

  // 用 API 确认真的落库，且金额分毫不差（12.5 这类小数最容易出错）
  const api = createApi(page.request)
  const { items } = await api.ledgerEntries()
  expect(items).toHaveLength(2)
  expect(items.reduce((sum, e) => sum + e.amount_cents, 0)).toBe(5000)
})

test('小数金额按分存储不丢精度', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const items = await api.quickCommit('咖啡 25.5')
  expect(items[0].amount_cents).toBe(2550)

  await page.goto('/ledger')
  await expect(page.locator('.ledger-entry')).toHaveCount(1)
  await expect(page.locator('.ledger-entry__amount').first()).toContainText('25.5')
})

test('收入行被识别为收入，会计入收入汇总', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.quickCommit('工资 8000')

  await page.goto('/ledger')
  // 明细里带 is-income 样式；页面显示成「+¥8,000」这种带千分位的形式
  await expect(page.locator('.ledger-entry__amount.is-income')).toContainText('8,000')

  const { items } = await api.ledgerEntries()
  expect(items[0].type).toBe('income')
  expect(items[0].amount_cents).toBe(800000)
})

test('可以切换月份查看不同月份', async ({ authedPage: page }) => {
  await page.goto('/ledger')

  const monthInput = page.getByLabel('选择月份')
  // inputValue() 不自动等待；先确认它已有值（月份由页面加载后填入）
  await expect(monthInput).not.toHaveValue('')
  const current = await monthInput.inputValue()
  const [year, month] = current.split('-').map(Number)
  const prev = month === 1 ? `${year - 1}-12` : `${year}-${String(month - 1).padStart(2, '0')}`

  await page.getByRole('button', { name: '上个月' }).click()
  await expect(monthInput).toHaveValue(prev)

  await page.getByRole('button', { name: '下个月' }).click()
  await expect(monthInput).toHaveValue(current)
})

test('明细行的分类下拉可直接修改，改完落库', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.quickCommit('午饭 40')

  await page.goto('/ledger')
  const row = page.locator('.ledger-entry').filter({ hasText: '午饭' }).first()
  await expect(row).toBeVisible()

  // 行内直接有分类下拉
  await row.locator('select.ledger-entry__cat').selectOption('餐饮')

  await expect
    .poll(async () => (await api.ledgerEntries()).items[0].category)
    .toBe('餐饮')
})

test('「还款」是内置分类（V10 迁移新增）', async ({ authedPage: page }) => {
  const res = await page.request.get('/api/ledger/categories')
  const body = (await res.json()) as { items: string[] }
  expect(body.items).toContain('还款')
})

test('可以删除明细，删除后列表清空', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.quickCommit('随手 10')

  await page.goto('/ledger')
  const row = page.locator('.ledger-entry').filter({ hasText: '随手' }).first()
  await expect(row).toBeVisible()

  await row.getByRole('button', { name: '删除这笔记录' }).click()
  const confirm = page.getByRole('alertdialog')
  await expect(confirm).toBeVisible()
  await confirm.getByRole('button', { name: '删除' }).click()

  await expect(page.locator('.ledger-entry')).toHaveCount(0)
  await expect.poll(async () => (await api.ledgerEntries()).items.length).toBe(0)
})

test('解析失败的行给出逐行错误，且不写入', async ({ authedPage: page }) => {
  await page.goto('/ledger')

  await page.getByLabel('记账输入').fill('这一行没有金额')
  await page.getByRole('button', { name: '解析预览' }).click()

  // 有明显错误提示，且没有可写入的条目
  await expect(page.locator('.ledger-parse__errors')).toBeVisible()

  const api = createApi(page.request)
  expect((await api.ledgerEntries()).items).toHaveLength(0)
})

test('编辑弹窗可改金额与分类，保存后列表与汇总同步', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.quickCommit('晚饭 40')

  await page.goto('/ledger')
  const row = page.locator('.ledger-entry').filter({ hasText: '晚饭' }).first()
  await expect(row).toBeVisible()

  // 打开编辑弹窗
  await row.getByRole('button', { name: '编辑金额与时间' }).click()
  const dialog = page.getByRole('dialog', { name: '编辑记账' })
  await expect(dialog).toBeVisible()

  // 分类与金额都能改
  await dialog.locator('select').selectOption('娱乐')
  await dialog.locator('input[inputmode="decimal"]').fill('60')
  await dialog.getByRole('button', { name: '保存' }).click()

  // 弹窗关闭，列表显示新值
  await expect(dialog).toBeHidden()
  await expect(page.locator('.ledger-entry__amount').first()).toContainText('60')

  // 汇总同步到 60
  await expect(page.locator('.ledger-total__value')).toContainText('60')

  // 落库确认
  const { items } = await api.ledgerEntries()
  expect(items[0]).toMatchObject({ amount_cents: 6000, category: '娱乐' })
})

test('编辑弹窗金额非法时给出提示且不关闭', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.quickCommit('测试非法 10')

  await page.goto('/ledger')
  await page.locator('.ledger-entry').first().getByRole('button', { name: '编辑金额与时间' }).click()

  const dialog = page.getByRole('dialog', { name: '编辑记账' })
  await dialog.locator('input[inputmode="decimal"]').fill('0')
  await dialog.getByRole('button', { name: '保存' }).click()

  await expect(dialog.getByText(/金额需为大于 0/)).toBeVisible()
  await expect(dialog).toBeVisible()

  // 数据没被改动
  const { items } = await api.ledgerEntries()
  expect(items[0].amount_cents).toBe(1000)
})

test('「Token」是内置支出分类，并能用别名快捷记账', async ({ authedPage: page }) => {
  const res = await page.request.get('/api/ledger/categories')
  const body = (await res.json()) as { items: string[] }
  expect(body.items).toContain('Token')

  // 默认别名只灌注给开发账号，E2E 账号要自己建一条
  const alias = await page.request.post('/api/ledger/aliases', {
    data: { alias: 'claude', category: 'Token' },
  })
  expect(alias.ok(), await alias.text()).toBeTruthy()

  // AI 服务的常见写法：第一词是别名，金额在后
  const api = createApi(page.request)
  const items = await api.quickCommit('claude 20')
  expect(items[0]).toMatchObject({ type: 'expense', category: 'Token', amount_cents: 2000 })

  // 界面上的分类下拉里也能选到。
  // allTextContents() 不自动等待，先等行渲染完再读，否则会读到空数组。
  await page.goto('/ledger')
  const row = page.locator('.ledger-entry').filter({ hasText: 'claude' }).first()
  await expect(row).toBeVisible()
  await expect(row.locator('select.ledger-entry__cat option').first()).toBeAttached()
  const options = await row.locator('select.ledger-entry__cat option').allTextContents()
  expect(options).toContain('Token')
})

test('「订阅」是内置支出分类，与 Token 并存且互不干扰', async ({ authedPage: page }) => {
  const res = await page.request.get('/api/ledger/categories')
  const body = (await res.json()) as { items: string[] }
  expect(body.items).toContain('订阅')
  expect(body.items).toContain('Token')

  // 默认别名只灌注给开发账号，E2E 账号自己建
  for (const [alias, category] of [
    ['icloud', '订阅'],
    ['claude', 'Token'],
  ]) {
    const r = await page.request.post('/api/ledger/aliases', { data: { alias, category } })
    expect(r.ok(), await r.text()).toBeTruthy()
  }

  const api = createApi(page.request)
  const rows = await api.quickCommit('icloud 25\nclaude 20')
  // 返回顺序是录入顺序，不是文本行序，所以按集合断言
  expect(rows.map((r) => r.category).sort()).toEqual(['Token', '订阅'].sort())
  expect(rows.every((r) => r.type === 'expense')).toBe(true)

  // 界面下拉里两个分类都能选
  await page.goto('/ledger')
  const row = page.locator('.ledger-entry').filter({ hasText: 'icloud' }).first()
  await expect(row).toBeVisible()
  await expect(row.locator('select.ledger-entry__cat option').first()).toBeAttached()
  const options = await row.locator('select.ledger-entry__cat option').allTextContents()
  expect(options).toContain('订阅')
  expect(options).toContain('Token')
})

test('重复提交同一批次不会重复写入（幂等）', async ({ authedPage: page }) => {
  const batchId = 'e2e-idempotent-batch'
  const payload = {
    batch_id: batchId,
    items: [{ type: 'expense', amount_cents: 1000, category: '餐饮', occurred_at: new Date().toISOString() }],
  }

  const first = await page.request.post('/api/ledger/entries/batch', { data: payload })
  expect(first.status()).toBe(201)

  const second = await page.request.post('/api/ledger/entries/batch', { data: payload })
  expect(second.status()).toBe(200)
  expect(await second.json()).toMatchObject({ created: false })
})
