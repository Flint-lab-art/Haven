import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * Issue：新建、状态流转、详情时间线、编辑与删除。
 *
 * 状态流转会写 issue_status_events，所以除了看列表里的状态，
 * 还要确认详情页的时间线真的记下了每一次变更。
 */

test('新建 Issue 后出现在列表，默认待办', async ({ authedPage: page }) => {
  await page.goto('/issues')

  await page.getByRole('button', { name: '新建 Issue' }).first().click()
  const dialog = page.getByRole('dialog', { name: '新建 Issue' })
  await expect(dialog).toBeVisible()

  await dialog.getByPlaceholder('例如：登录页在 Safari 下错位').fill('Safari 下登录页错位')
  await dialog.getByRole('button', { name: /创建|保存/ }).click()

  await expect(page.getByText('Safari 下登录页错位').first()).toBeVisible()

  const api = createApi(page.request)
  const issues = await api.issues()
  expect(issues[0]).toMatchObject({ title: 'Safari 下登录页错位', status: 'todo' })
})

test('列表里可一键标记完成，再标记回待办', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const issue = await api.createIssue({ title: '待完成的事' })

  await page.goto('/issues')
  const row = page.locator('.issue-row').filter({ hasText: '待完成的事' }).first()
  await expect(row).toBeVisible()

  // 未完成时按钮是「标记为已完成」
  await row.getByRole('button', { name: '标记为已完成' }).click()
  await expect(row.getByRole('button', { name: '标记为待办' })).toBeVisible()

  // 再点回待办
  await row.getByRole('button', { name: '标记为待办' }).click()
  await expect(row.getByRole('button', { name: '标记为已完成' })).toBeVisible()

  const issues = await api.issues()
  expect(issues.find((i) => i.id === issue.id)!.status).toBe('todo')
})

test('状态页签能按状态过滤', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.createIssue({ title: '还没做的' })
  const done = await api.createIssue({ title: '已经做完的' })
  await api.patchIssue(done.id, { status: 'done' })

  await page.goto('/issues')
  await page.getByRole('tab', { name: '已完成' }).click()

  await expect(page.getByText('已经做完的').first()).toBeVisible()
  await expect(page.getByText('还没做的')).toHaveCount(0)
})

test('详情页显示状态变更时间线', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const issue = await api.createIssue({ title: '有历史记录的事' })
  await api.patchIssue(issue.id, { status: 'in_progress' })
  await api.patchIssue(issue.id, { status: 'done' })

  await page.goto(`/issues/${issue.id}`)
  await expect(page.getByRole('heading', { name: '有历史记录的事' })).toBeVisible()
  await expect(page.getByText('已完成').first()).toBeVisible()

  // 时间线里应有状态流转记录
  const res = await page.request.get(`/api/issues/${issue.id}`)
  const detail = (await res.json()) as { status_events: { to_status: string }[] }
  expect(detail.status_events.map((e) => e.to_status)).toEqual(
    expect.arrayContaining(['in_progress', 'done']),
  )
})

test('详情页可编辑标题', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const issue = await api.createIssue({ title: '原标题' })

  await page.goto(`/issues/${issue.id}`)
  await page.getByRole('button', { name: '编辑' }).click()

  const dialog = page.getByRole('dialog', { name: '编辑 Issue' })
  const titleInput = dialog.getByPlaceholder('例如：登录页在 Safari 下错位')
  await titleInput.fill('改过的标题')
  await dialog.getByRole('button', { name: /保存/ }).click()

  await expect(page.getByRole('heading', { name: '改过的标题' })).toBeVisible()
})

test('可以删除 Issue', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const issue = await api.createIssue({ title: '要删掉的事' })

  await page.goto(`/issues/${issue.id}`)
  await page.getByRole('button', { name: '删除' }).first().click()
  const confirm = page.getByRole('alertdialog')
  await expect(confirm).toBeVisible()
  await confirm.getByRole('button', { name: '删除' }).click()

  await expect
    .poll(async () => (await api.issues()).some((i) => i.id === issue.id))
    .toBe(false)
})
