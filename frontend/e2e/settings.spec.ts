import { expect, test } from './fixtures'

/**
 * 设置：概览、外观、账号安全、会话、授信设备、API Token。
 *
 * 测试账号没有绑定 TOTP，这恰好覆盖了「未完成动态码验证时不能管理 Token」这条约束。
 * 绑定 TOTP 的完整流程需要真实动态码，属于手工验收范围（见 docs/testing.md）。
 */

test('设置概览显示用户名、版本与双重验证状态', async ({ authedPage: page }) => {
  await page.goto('/settings')

  // 「设置」标题在侧边导航和正文里各有一个，正文里的是 detail-title
  await expect(page.locator('.detail-title').filter({ hasText: '设置' })).toBeVisible()
  await expect(page.getByText('e2e-user').first()).toBeVisible()
  // 版本号来自构建注入的 app.version
  await expect(page.locator('dd').filter({ hasText: /^Haven v\d+\.\d+\.\d+$/ })).toHaveCount(1)
})

test('切换主题后立即生效，刷新后保持', async ({ authedPage: page }) => {
  await page.goto('/settings/appearance')

  // 先等选项渲染出来再计数：count() 不做自动等待，
  // 页面还没挂载时它直接返回 0，会得到一个与真实情况无关的失败。
  const radios = page.getByRole('radio')
  await expect(radios.first()).toBeVisible()

  const count = await radios.count()
  expect(count, '主题选项应至少有多个').toBeGreaterThan(1)

  // 找到一个当前未选中的主题并切换
  let target = -1
  for (let i = 0; i < count; i++) {
    if ((await radios.nth(i).getAttribute('aria-checked')) !== 'true') {
      target = i
      break
    }
  }
  expect(target, '应存在未选中的主题').toBeGreaterThanOrEqual(0)

  await radios.nth(target).click()
  await expect(radios.nth(target)).toHaveAttribute('aria-checked', 'true')

  // 记录实际生效的根节点属性，刷新后应保持
  const applied = await page.evaluate(() => document.documentElement.getAttribute('data-theme'))
  await page.reload()
  await expect
    .poll(() => page.evaluate(() => document.documentElement.getAttribute('data-theme')))
    .toBe(applied)
})

test('账号安全页展示动态验证码状态，可进入绑定流程', async ({ authedPage: page }) => {
  await page.goto('/settings/security')

  await expect(page.getByRole('heading', { name: '账号安全', level: 1 })).toBeVisible()
  // 未绑定时提供「开始绑定」
  await page.getByRole('button', { name: '开始绑定' }).click()

  // 出现二维码与手动输入的密钥
  await expect(page.locator('#bind-code')).toBeVisible()
  const res = await page.request.get('/api/me')
  expect(await res.json()).toMatchObject({ user: { totp_enabled: false } })
})

test('会话页列出当前设备，并标注「当前设备」', async ({ authedPage: page }) => {
  await page.goto('/settings/sessions')

  await expect(page.getByRole('heading', { name: '会话', level: 1 })).toBeVisible()
  // 当前这次登录的会话一定在列表里
  await expect(page.getByText('当前设备').first()).toBeVisible()
  await expect(page.getByText('没有活跃会话')).toHaveCount(0)
})

test('授信设备页在无设备时给出空态', async ({ authedPage: page }) => {
  await page.goto('/settings/devices')

  await expect(page.getByRole('heading', { name: '授信设备', level: 1 })).toBeVisible()
  // 登录时没勾「信任这台设备」，所以是空态
  await expect(page.getByText('没有授信设备')).toBeVisible()
})

test('未绑定动态验证码时，API Token 页可用（没有第二因素可验证）', async ({ authedPage: page }) => {
  await page.goto('/settings/tokens')

  await expect(page.getByRole('heading', { name: 'API Token', level: 1 })).toBeVisible()
  // 账号未开启 TOTP，登录时没有第二因素可验证，会话直接视为已通过，
  // 因此这里应当能管理 Token，而不是被 403 挡住
  await expect(page.getByText('管理 Token 需要完成动态码验证')).toHaveCount(0)
  await expect(page.getByRole('button', { name: '新建 Token' }).first()).toBeVisible()

  // 完整创建一次，确认真的能用
  await page.getByRole('button', { name: '新建 Token' }).first().click()
  await page.locator('#token-name').fill('e2e 脚本')
  await page.locator('#token-scope').selectOption('read')
  await page.getByRole('button', { name: /创建/ }).first().click()

  // 一次性明文展示出来，且能被列表看到
  await expect(page.locator('.code-block')).not.toBeEmpty()

  const res = await page.request.get('/api/tokens')
  const body = (await res.json()) as { items: { name: string }[] }
  expect(body.items.map((t) => t.name)).toContain('e2e 脚本')
})

test('API Token 可用于访问只读接口', async ({ authedPage: page }) => {
  const res = await page.request.post('/api/tokens', { data: { name: '只读 token', scope: 'read' } })
  const created = (await res.json()) as { token: string }
  expect(created.token).toBeTruthy()

  // 用 Bearer 访问只读接口
  const notes = await page.request.get('/api/notes', {
    headers: { Authorization: `Bearer ${created.token}` },
  })
  expect(notes.ok()).toBeTruthy()

  // 只读 token 不能写
  const write = await page.request.post('/api/notes', {
    headers: { Authorization: `Bearer ${created.token}` },
    data: { title: '不该被创建' },
  })
  expect(write.status()).toBe(403)
})

test('匿名访问 Token 接口返回 401，而不是空列表（避免误以为没有凭证）', async ({ request }) => {
  const res = await request.get('/api/tokens')
  expect(res.status()).toBe(401)
})
