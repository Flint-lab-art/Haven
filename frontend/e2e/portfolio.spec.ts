import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 作品集：新建、编辑、公开开关、仓库链接增删。
 *
 * 公开开关（is_public）是 V9 迁移新增的：匿名接口只返回显式公开的作品。
 * 这条最值得测——它同时关系到「能展示」和「不泄露」。
 *
 * 页面结构：中间栏是作品列表（「添加」入口），右侧是常驻的编辑表单 + 仓库链接区。
 */


/** 进入作品集并选中某个作品（列表行按标题定位）。 */
async function openItem(page: import('@playwright/test').Page, title: string) {
  await page.goto('/portfolio')
  await page.locator('.list-row').filter({ hasText: title }).first().click()
  await expect(page.locator('#edit-title')).toHaveValue(title)
}

/** 右侧编辑区真的一行都没有时，会显示这个提示。 */
const EMPTY_HINT = '添加作品和仓库链接'

test('新建作品后出现在列表', async ({ authedPage: page }) => {
  await page.goto('/portfolio')

  // 列表栏顶部或空态里的新建入口
  await page.getByRole('button', { name: /^添加/ }).first().click()

  // 新建表单用 item-* 前缀的 id，编辑表单用 edit-*，两者可能同时出现在页面上
  await page.locator('#item-title').fill('Haven')
  await page.locator('#item-desc').fill('自托管的个人知识中台')
  // 提交按钮在新建表单里（页面上「添加」按钮不止一个：列表栏顶部 + 表单提交）
  await page.locator('form.panel').getByRole('button', { name: '添加' }).click()

  // 新建后自动选中，右侧出现编辑表单，标题已填入
  await expect(page.locator('#edit-title')).toHaveValue('Haven')
  await expect(page.locator('#edit-desc')).toHaveValue('自托管的个人知识中台')
})

test('作品可以编辑标题与简介', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const item = await api.createPortfolioItem({ title: '旧标题', description: '旧简介' })

  await openItem(page, '旧标题')
  await page.locator('#edit-title').fill('新标题')
  await page.locator('#edit-desc').fill('新简介')
  await page.getByRole('button', { name: '保存' }).click()

  await expect
    .poll(async () => {
      const res = await page.request.get(`/api/portfolio/${item.id}`)
      const body = (await res.json()) as { title: string; description: string }
      return `${body.title}|${body.description}`
    })
    .toBe('新标题|新简介')
})

test('未勾选公开的作品不出现在公开页', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.createPortfolioItem({ title: '内部草稿', isPublic: false })

  const res = await page.request.get('/api/public/portfolio')
  const body = (await res.json()) as { items: { title: string }[] }
  expect(body.items.map((i) => i.title)).not.toContain('内部草稿')
})

test('勾选公开并保存后出现在公开作品集页', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const item = await api.createPortfolioItem({ title: '公开作品', isPublic: false })

  await openItem(page, '公开作品')
  await page.locator('#edit-public').check()
  await page.getByRole('button', { name: '保存' }).click()

  await expect
    .poll(async () => {
      const res = await page.request.get('/api/public/portfolio')
      const body = (await res.json()) as { items: { title: string }[] }
      return body.items.map((i) => i.title)
    })
    .toContain('公开作品')

  // 公开首页也能看到（公开域用 localhost 之外的判定，这里直接验接口即可，
  // 页面渲染由 public.spec.ts 覆盖）
})

test('可以给作品添加仓库链接，并标记主链接', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const item = await api.createPortfolioItem({ title: '带仓库的项目' })

  await openItem(page, '带仓库的项目')

  await page.getByLabel('链接地址').fill('https://github.com/kairo/haven')
  await page.getByLabel('链接标题').fill('源码')
  await page.getByRole('checkbox', { name: '主链接' }).check()
  await page.getByRole('button', { name: '添加链接' }).click()

  // 链接出现在列表里，并带「主链接」徽标
  await expect(page.getByText('https://github.com/kairo/haven')).toBeVisible()
  await expect(page.locator('.badge--public')).toContainText('主链接')

  const res = await page.request.get(`/api/portfolio/${item.id}`)
  const detail = (await res.json()) as { repos: { url: string; is_primary: boolean }[] }
  expect(detail.repos).toContainEqual(
    expect.objectContaining({ url: 'https://github.com/kairo/haven', is_primary: true }),
  )
})

test('可以移除仓库链接', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const item = await api.createPortfolioItem({ title: '删仓库' })
  await api.addRepo(item.id, 'https://github.com/kairo/temp')

  await openItem(page, '删仓库')
  await page.getByRole('button', { name: '移除' }).click()

  await expect
    .poll(async () => {
      const res = await page.request.get(`/api/portfolio/${item.id}`)
      return ((await res.json()) as { repos: { url: string }[] }).repos.length
    })
    .toBe(0)
})

test('可以删除作品（带二次确认）', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const item = await api.createPortfolioItem({ title: '待删除作品' })

  await openItem(page, '待删除作品')
  // 编辑区里的「删除作品」按钮
  await page.getByRole('button', { name: '删除作品', exact: true }).last().click()
  const confirm = page.getByRole('alertdialog')
  await expect(confirm).toBeVisible()
  await confirm.getByRole('button', { name: '删除' }).click()

  await expect
    .poll(async () => (await page.request.get(`/api/portfolio/${item.id}`)).status())
    .toBe(404)
})

test('空作品集给出引导提示', async ({ authedPage: page }) => {
  await page.goto('/portfolio')
  await expect(page.getByText(EMPTY_HINT).first()).toBeVisible()
})
