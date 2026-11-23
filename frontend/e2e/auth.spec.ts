import { expect, test, loginViaApi, resetDatabase, TEST_PASSWORD, TEST_USER } from './fixtures'

/**
 * 登录 / 会话 / 登出。
 *
 * 这些是最底层的功能：登录坏了，其它用例全部连带失败。
 * 所以它只依赖数据库重置，不用 authedPage 夹具（那个夹具本身会走登录）。
 */

test.beforeEach(async () => {
  await resetDatabase()
})

test('未登录访问私有区会被引导到登录页', async ({ page }) => {
  await page.goto('/notes')
  await expect(page).toHaveURL(/\/login/)
  await expect(page.getByLabel('用户名')).toBeVisible()
})

test('密码错误时显示错误提示，不跳转', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('用户名').fill(TEST_USER)
  await page.getByLabel('密码').fill('wrong-password')
  await page.getByRole('button', { name: '登录', exact: true }).click()

  // 错误提示用 role=alert，便于断言也便于读屏
  await expect(page.getByRole('alert')).toBeVisible()
  await expect(page).toHaveURL(/\/login/)
})

test('输入正确密码后进入仪表盘，侧边栏显示用户名', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('用户名').fill(TEST_USER)
  await page.getByLabel('密码').fill(TEST_PASSWORD)
  await page.getByRole('button', { name: '登录', exact: true }).click()

  // 默认落在仪表盘
  await expect(page.getByRole('heading', { name: '仪表盘', level: 1 })).toBeVisible()
  // 侧边栏账户菜单显示登录用户
  await expect(page.getByRole('button', { name: '账户菜单' })).toContainText(TEST_USER)
})

test('登录后访问受保护页面会带上 redirect 参数，登录后回到原页面', async ({ page }) => {
  await page.goto('/tags')

  // 未登录时被守卫送到登录页，并记住来源
  await expect(page).toHaveURL(/\/login\?redirect=/)
  await page.getByLabel('用户名').fill(TEST_USER)
  await page.getByLabel('密码').fill(TEST_PASSWORD)
  await page.getByRole('button', { name: '登录', exact: true }).click()

  await expect(page).toHaveURL(/\/tags/)
  await expect(page.getByRole('heading', { name: '标签', level: 1 })).toBeVisible()
})

test('登录后可访问全部业务页面', async ({ page }) => {
  await loginViaApi(page.request)
  // 用 API 登录拿到 Cookie 后，页面直接带会话访问
  const pages = [
    { path: '/', heading: '仪表盘' },
    { path: '/tags', heading: '标签' },
    { path: '/ledger', heading: '记账' },
    { path: '/issues', heading: 'Issue' },
    { path: '/settings', heading: '设置' },
  ]

  for (const item of pages) {
    await page.goto(item.path)
    // 关键断言：没有被踢回登录页
    await expect(page, `${item.path} 不应跳到登录页`).not.toHaveURL(/\/login/)
    await expect(
      page.getByRole('heading', { name: item.heading, level: 1 }).first(),
      `${item.path} 应显示「${item.heading}」标题`,
    ).toBeVisible()
  }
})

test('登出后回到登录页，且私有接口不可访问', async ({ page }) => {
  await loginViaApi(page.request)
  await page.goto('/notes')

  await page.getByRole('button', { name: '账户菜单' }).click()
  await page.getByRole('menuitem', { name: '退出登录' }).click()

  await expect(page).toHaveURL(/\/login/)

  // 会话真的失效了，不只是前端跳转
  const res = await page.request.get('/api/me')
  const body = (await res.json()) as { anonymous: boolean }
  expect(body.anonymous).toBe(true)
})

test('/api/me 在匿名时返回 anonymous=true', async ({ request }) => {
  const res = await request.get('/api/me')
  expect(res.ok()).toBeTruthy()
  expect(await res.json()).toMatchObject({ anonymous: true })
})

test('/api/me 在登录后返回用户信息', async ({ page }) => {
  await loginViaApi(page.request)
  const res = await page.request.get('/api/me')
  expect(await res.json()).toMatchObject({
    anonymous: false,
    auth_type: 'session',
    user: { username: TEST_USER },
  })
})
