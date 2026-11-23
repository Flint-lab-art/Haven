import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 移动端（`/m/`）：三个 tab、记账抽屉、统计四粒度、我的。
 *
 * 移动端布局与 PC 完全独立，所以单独一个 spec。
 * 手势（左滑删除）依赖真实触摸事件，在 CDP 之外不好模拟，
 * 这里只验「滑动之后的结果」，不验拖动过程。
 */

/** 建账户 + 一笔支出，作为大多数用例的起点。 */
async function seed(api: ReturnType<typeof createApi>) {
  const account = await api.createAccount({ name: '工资卡', type: 'bank', initialBalanceCents: 500_000 })
  const lunch = await api.categoryIdByName('餐饮', '午餐')
  await api.createLedgerEntry({ type: 'expense', amountCents: 2500, categoryId: lunch, accountId: account.id })
  return { account, lunch }
}

test('四个 tab 都在，默认进记账', async ({ authedPage: page }) => {
  await page.goto('/m/')

  const tabs = page.locator('.m-tab')
  await expect(tabs).toHaveCount(4)
  await expect(tabs.nth(0)).toContainText('记账')
  await expect(tabs.nth(1)).toContainText('统计')
  await expect(tabs.nth(2)).toContainText('账户')
  await expect(tabs.nth(3)).toContainText('我的')

  // 默认落在记账：记账是最高频的动作
  await expect(tabs.nth(0)).toHaveClass(/m-tab--active/)
})

test('记账页展示流水，摘要与分类正确', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await seed(api)

  await page.goto('/m/')
  await expect(page.locator('.m-row').filter({ hasText: '午餐' })).toHaveCount(1)
  // 明细行显示「大类 · 账户」
  await expect(page.locator('.m-row').first()).toContainText('餐饮')
  await expect(page.locator('.m-row').first()).toContainText('工资卡')
})

test('记一笔：抽屉里有分类网格与数字键盘，能完成录入', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.createAccount({ name: '工资卡', type: 'bank', initialBalanceCents: 500_000 })

  await page.goto('/m/')
  await page.getByRole('button', { name: '记一笔' }).click()

  const sheet = page.getByRole('dialog', { name: '记一笔' })
  await expect(sheet).toBeVisible()

  // 分类网格：先点餐饮，再点午餐
  await sheet.getByRole('radio', { name: /餐饮/ }).click()
  await sheet.getByRole('radio', { name: /午餐/ }).click()

  // 数字键盘输入 35
  const keypad = sheet.getByRole('group', { name: '数字键盘' })
  await expect(keypad).toBeVisible()
  await keypad.getByRole('button', { name: '3', exact: true }).click()
  await keypad.getByRole('button', { name: '5', exact: true }).click()
  await expect(sheet.locator('.m-amount__value')).toHaveText('35')

  // 保存键在键盘里
  await keypad.getByRole('button', { name: '记一笔' }).click()
  await expect(sheet).toBeHidden()

  await expect(page.locator('.m-row').filter({ hasText: '午餐' })).toHaveCount(1)
})

test('周视图默认选中，且只有 7 天数据', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await seed(api)

  await page.goto('/m/stats')
  // 粒度徽章默认是「周」
  await expect(page.locator('.m-nav__badge')).toHaveText('周')

  // 折线图存在（周用 line）
  await expect(page.locator('.m-chart__svg')).toBeVisible()
})

test('切换到月 / 季 / 年，图表形态随之变化', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await seed(api)

  await page.goto('/m/stats')

  // 打开粒度弹层
  await page.locator('.m-nav__center').click()
  const picker = page.getByRole('dialog', { name: '选择粒度' })
  await expect(picker).toBeVisible()

  // 切到月：弹层里每项是「月 钱花在哪」这样的结构
  await picker.locator('.m-granularity-item').filter({ hasText: '钱花在哪' }).click()
  await expect(page.locator('.m-nav__badge')).toHaveText('月')

  // 切到季：应出现柱状图（rect）
  await page.locator('.m-nav__center').click()
  await page
    .getByRole('dialog', { name: '选择粒度' })
    .locator('.m-granularity-item')
    .filter({ hasText: '三个月对比' })
    .click()
  await expect(page.locator('.m-nav__badge')).toHaveText('季')
  await expect(page.locator('.m-chart__svg rect').first()).toBeVisible()
})

test('我的页有身份卡与分组菜单', async ({ authedPage: page }) => {
  await page.goto('/m/me')

  await expect(page.locator('.m-profile__name')).toHaveText('e2e-user')
  // 两个分组：记账 / 其他
  await expect(page.locator('.m-group')).toHaveCount(2)
  await expect(page.getByRole('link', { name: /账户/ })).toBeVisible()
  await expect(page.getByRole('link', { name: /Issue/ })).toBeVisible()
  await expect(page.getByRole('link', { name: /设置/ })).toBeVisible()
})

test('移动端设置：外观与登录日志是原生页，其余跳 PC', async ({ authedPage: page }) => {
  await page.goto('/m/me/settings')

  await expect(page.getByRole('link', { name: /外观/ })).toBeVisible()
  await expect(page.getByRole('link', { name: /登录日志/ })).toBeVisible()
  // 跳 PC 的那组用外链
  await expect(page.getByRole('link', { name: /账号安全/ })).toHaveAttribute('href', '/settings/security')

  // 外观页是原生布局
  await page.getByRole('link', { name: /外观/ }).click()
  await expect(page.locator('.m-theme-grid')).toBeVisible()
})

test('移动端账户页：总资产卡 + 卡片列表，新建走底部抽屉', async ({ authedPage: page }) => {
  await page.goto('/m/accounts')

  // 顶部总资产卡
  await expect(page.locator('.m-total__label')).toHaveText('总资产')

  await page.getByRole('button', { name: '新建', exact: true }).click()
  const sheet = page.getByRole('dialog', { name: '新建账户' })
  await expect(sheet).toBeVisible()

  await sheet.getByLabel('账户名').fill('现金')
  // 底部抽屉里的保存
  await sheet.getByRole('button', { name: '保存' }).click()
  await expect(sheet).toBeHidden()

  // 卡片出现在列表里
  await expect(page.locator('.m-acc-card__name').filter({ hasText: '现金' })).toBeVisible()
})

test('移动端 Issue：列表按状态筛选，可新建', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.createIssue({ title: '移动端创建的 Bug', type: 'bug', priority: 'high' })

  await page.goto('/m/me/issues')
  await expect(page.locator('.m-issue').filter({ hasText: '移动端创建的 Bug' })).toHaveCount(1)

  // 新建
  await page.getByRole('link', { name: '新建' }).click()
  await page.getByLabel('标题').fill('新 Issue')
  await page.getByRole('button', { name: '创建' }).click()

  // 建完跳详情
  await expect(page.locator('.m-issue-detail__title')).toHaveText('新 Issue')
})

test('移动端 Issue 详情能改状态', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const issue = await api.createIssue({ title: '状态待改', type: 'bug', priority: 'medium' })

  await page.goto(`/m/me/issues/${issue.id}`)
  await page.getByRole('button', { name: '进行中' }).click()

  await expect(page.locator('.m-segmented__btn.is-active')).toContainText('进行中')
  const list = await api.issues()
  expect(list.find((i) => i.id === issue.id)?.status).toBe('in_progress')
})
