import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 笔记：新建、编辑、自动保存、删除、回收站还原、版本历史。
 *
 * 造数据走 API，**用户可见结果全部用界面断言**。
 * 尤其是自动保存和回收站，它们此前的 bug 都是「接口返回 200 但数据没改」，
 * 所以这里一律重新加载页面或重新读列表来确认。
 */

/** 笔记树里某篇笔记的行。 */
function noteRow(page: import('@playwright/test').Page, title: string) {
  return page.locator('.tree-row--note').filter({ hasText: title })
}

/** 编辑区的可编辑区域（TipTap / ProseMirror）。 */
function editorSurface(page: import('@playwright/test').Page) {
  return page.locator('.editor-surface .ProseMirror').first()
}

test('工作台点「新建笔记」后可直接输入标题', async ({ authedPage: page }) => {
  await page.goto('/notes')

  await page.getByRole('button', { name: '新建笔记' }).first().click()

  const title = page.getByLabel('标题')
  await expect(title).toBeVisible()
  await title.fill('我的第一篇笔记')

  // 自动保存：状态提示会从「保存中」变成已保存
  await expect(page.locator('.save-state--saved')).toBeVisible()
})

test('新建的笔记在重新加载后仍然存在（自动保存真的落库）', async ({ authedPage: page }) => {
  await page.goto('/notes')
  await page.getByRole('button', { name: '新建笔记' }).first().click()
  await page.getByLabel('标题').fill('落库验证')

  // 等自动保存完成再刷新。只等界面提示会漏掉「提示成功但数据没写」的 bug
  await expect(page.locator('.save-state--saved')).toBeVisible()

  await page.goto('/notes')
  await expect(noteRow(page, '落库验证')).toBeVisible()
})

test('正文编辑后会写进搜索结果', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const note = await api.createNote({ title: '正文可达' })

  await page.goto(`/notes/${note.id}`)
  const editor = editorSurface(page)
  await editor.click()
  await editor.pressSequentially('苹果香蕉搜索词')
  await expect(page.locator('.save-state--saved')).toBeVisible()

  // 用后端搜索确认正文真的存进去了：正文没写入的话搜索结果不可能命中
  const res = await page.request.get('/api/search?q=苹果香蕉')
  const body = (await res.json()) as { notes: { items: { id: string }[] } }
  expect(body.notes.items.map((n) => n.id)).toContain(note.id)
})

test('删除笔记后从列表消失、出现在回收站，可还原', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.createNote({ title: '待删除笔记' })

  await page.goto('/notes')
  const row = noteRow(page, '待删除笔记')
  await expect(row).toBeVisible()

  await row.getByRole('button', { name: '删除笔记' }).click()
  await page.getByRole('alertdialog').getByRole('button', { name: '删除' }).click()
  await expect(noteRow(page, '待删除笔记')).toHaveCount(0)

  // 回收站里能看到
  await page.goto('/trash')
  await expect(page.getByText('待删除笔记').first()).toBeVisible()

  // 选中后还原
  await page.getByText('待删除笔记').first().click()
  await page.getByRole('button', { name: '还原' }).click()

  // 成功提示会随列表刷新被清掉，因此断言结果而不是提示文案：
  // 回收站里不再有它，笔记列表里重新出现
  await page.goto('/trash')
  await expect(page.getByText('待删除笔记')).toHaveCount(0)

  await page.goto('/notes')
  await expect(noteRow(page, '待删除笔记')).toBeVisible()
})

test('回收站永久删除后不可恢复', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const note = await api.createNote({ title: '彻底删除' })
  await api.deleteNote(note.id)

  await page.goto('/trash')
  await page.getByText('彻底删除').first().click()
  await page.getByRole('button', { name: '永久删除' }).click()
  await page.getByRole('alertdialog').getByRole('button', { name: '删除' }).click()

  // 用 API 确认真的没了（不是只从界面移除）
  await expect
    .poll(async () => (await api.trash()).map((n) => n.id))
    .not.toContain(note.id)
})

test('历史版本里能查看旧版本的内容差异并还原', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const note = await api.createNote({ title: '初版标题', content: '初版内容' })
  // 5 分钟内的修改会合并成一个版本（避免自动保存刷出大量版本），
  // 所以这里断言的是「存在历史版本且能还原」，而不是「版本数量等于修改次数」。
  await api.updateNote(note.id, { title: '当前标题', content: '当前内容' })

  await page.goto(`/notes/${note.id}`)
  await expect(page.getByLabel('标题')).toHaveValue('当前标题')

  await page.getByRole('button', { name: '历史版本' }).click()
  const dialog = page.getByRole('dialog', { name: '历史版本' })
  await expect(dialog).toBeVisible()

  // 至少有一个可选的旧版本
  const items = dialog.locator('.version-item')
  await expect(items.first()).toBeVisible()
  await items.first().click()

  await dialog.getByRole('button', { name: '还原到此版本' }).click()
  // 还原前的二次确认（ConfirmDialog 用的是 alertdialog，不是 dialog）
  await page.getByRole('alertdialog').getByRole('button', { name: '删除' }).click()

  // 还原成功：对话框关闭，标题变成旧版本的值
  await expect(dialog).toBeHidden()
  await expect(page.getByLabel('标题')).toHaveValue('初版标题')
})

test('笔记可移动到其他文件夹', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const folder = await api.createFolder('资料')
  const note = await api.createNote({ title: '待归位' })

  await page.goto(`/notes/${note.id}`)
  await page.getByLabel('所属文件夹').selectOption({ label: '资料' })
  await expect(page.locator('.save-state--saved')).toBeVisible()

  // 用 API 确认 folder_id 真的改了（updateById 跳过 null 那类 bug 会在这一步暴露）
  const detail = await page.request.get(`/api/notes/${note.id}`)
  expect(await detail.json()).toMatchObject({ folder_id: folder.id })
})
