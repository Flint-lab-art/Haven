import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 公开域：匿名可访问的首页、笔记列表、笔记详情、搜索、作品集。
 *
 * 公开域与私有域是**同一份构建**，靠 hostname 切换路由表：
 * - `localhost`  → 私有域（工作台），未登录会被送去登录页
 * - `127.0.0.1`  → 公开域，只能看到公开内容，且没有后台入口
 *
 * 这组用例专测后者，重点是「该看到的能看到」和「不该看到的看不到」。
 */

const PUBLIC_BASE = process.env.E2E_PUBLIC_BASE ?? 'http://127.0.0.1:18099'

/** 造一批公开 / 私有数据。 */
async function seed(page: import('@playwright/test').Page) {
  const api = createApi(page.request)
  const published = await api.createNote({ title: '公开的笔记', content: '这篇可以给所有人看' })
  await page.request.post(`/api/notes/${published.id}/publish`)

  const draft = await api.createNote({ title: '私密草稿', content: '这篇不该被外人看到' })

  const item = await api.createPortfolioItem({
    title: '公开作品',
    description: '一句话简介',
    content: '# 正文',
    isPublic: true,
  })
  const hidden = await api.createPortfolioItem({ title: '未公开作品', isPublic: false })

  return { published, draft, item, hidden }
}

test('公开首页只展示公开内容', async ({ authedPage: page }) => {
  await seed(page)

  await page.goto(`${PUBLIC_BASE}/`)
  await expect(page.getByRole('heading', { name: '正在做的事和写过的东西' })).toBeVisible()

  // 公开作品能看到
  await expect(page.getByText('公开作品').first()).toBeVisible()
  // 未公开的作品看不到
  await expect(page.getByText('未公开作品')).toHaveCount(0)
})

test('公开域没有后台入口，也没有登录链接', async ({ authedPage: page }) => {
  await page.goto(`${PUBLIC_BASE}/`)

  // 主导航只有笔记 / 作品集
  const nav = page.getByRole('navigation', { name: '主导航' })
  await expect(nav.getByRole('link', { name: '笔记' })).toBeVisible()
  await expect(nav.getByRole('link', { name: '作品集' })).toBeVisible()

  // 私有域才有的入口一个都不应出现
  await expect(page.getByRole('link', { name: '记账' })).toHaveCount(0)
  await expect(page.getByRole('link', { name: 'Issue' })).toHaveCount(0)
  await expect(page.getByRole('link', { name: '回收站' })).toHaveCount(0)
  await expect(page.getByRole('link', { name: /登录/ })).toHaveCount(0)
})

test('公开笔记列表只列已发布的笔记', async ({ authedPage: page }) => {
  await seed(page)

  await page.goto(`${PUBLIC_BASE}/notes`)
  await expect(page.getByRole('heading', { name: '公开笔记', level: 1 })).toBeVisible()

  await expect(page.getByText('公开的笔记').first()).toBeVisible()
  await expect(page.getByText('私密草稿')).toHaveCount(0)
})

test('公开笔记详情可匿名阅读，私密笔记返回不存在', async ({ authedPage: page }) => {
  const { published, draft } = await seed(page)

  await page.goto(`${PUBLIC_BASE}/notes/${published.id}`)
  await expect(page.getByRole('heading', { level: 1 })).toContainText('公开的笔记')

  await page.goto(`${PUBLIC_BASE}/notes/${draft.id}`)
  // 不泄露存在性：统一按「不存在」处理
  await expect(page.getByText(/不存在|已被删除|没有权限/).first()).toBeVisible()
})

test('公开搜索能按关键词找到公开笔记', async ({ authedPage: page }) => {
  await seed(page)

  await page.goto(`${PUBLIC_BASE}/search`)
  const input = page.getByRole('searchbox').or(page.getByPlaceholder(/搜索/)).first()
  await input.fill('公开的笔记')
  await input.press('Enter')

  await expect(page.getByText('公开的笔记').first()).toBeVisible()
})

test('公开作品集与详情页可匿名访问', async ({ authedPage: page }) => {
  const { item } = await seed(page)

  await page.goto(`${PUBLIC_BASE}/portfolio`)
  await expect(page.getByText('公开作品').first()).toBeVisible()
  await expect(page.getByText('未公开作品')).toHaveCount(0)

  await page.goto(`${PUBLIC_BASE}/portfolio/${item.id}`)
  await expect(page.getByRole('heading', { name: '公开作品' })).toBeVisible()
  await expect(page.getByText('一句话简介')).toBeVisible()
})

test('未公开作品的详情在公开域返回不存在', async ({ authedPage: page }) => {
  const { hidden } = await seed(page)

  await page.goto(`${PUBLIC_BASE}/portfolio/${hidden.id}`)
  // 不泄露存在性：文案是「找不到这个作品」，与「作品不存在」无法区分
  await expect(page.getByText('找不到这个作品')).toBeVisible()
  await expect(page.getByText('未公开作品')).toHaveCount(0)
})

test('匿名访问私有接口返回 401，而不是空数据', async ({ authedPage: page }) => {
  // 用独立的请求上下文（不带 authedPage 的 Cookie）
  const anon = await page.context().browser()!.newContext()
  const request = anon.request

  for (const path of ['/api/notes', '/api/folders', '/api/ledger/entries', '/api/issues']) {
    const res = await request.get(`${PUBLIC_BASE}${path}`)
    expect(res.status(), `${path} 应拒绝匿名访问`).toBe(401)
  }

  await anon.close()
})
