import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 版本还原的契约：还原后笔记的标题与正文必须等于旧版本，且能再被读到。
 *
 * 单独放在这里是因为「还原被自动保存覆盖」这类问题在 UI 上很难分辨：
 * 到底后端没写、还是前端又被回写了。先在没有编辑器的纯 API 场景把它钉死。
 */

test('还原旧版本后标题与正文都回到旧值', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const note = await api.createNote({ title: '初版标题', content: '初版内容' })
  await api.updateNote(note.id, { title: '当前标题', content: '当前内容' })

  const versions = (await (await page.request.get(`/api/notes/${note.id}/versions`)).json()) as {
    items: { id: string; title: string }[]
  }
  expect(versions.items.length).toBeGreaterThan(0)
  // 取最早的那一版
  const oldest = versions.items[versions.items.length - 1]

  const res = await page.request.post(`/api/notes/${note.id}/versions/${oldest.id}/restore`)
  expect(res.ok()).toBeTruthy()
  const restored = (await res.json()) as { title: string; content: string }
  expect(restored.title).toBe(oldest.title)

  // 再读一次，确认落库而不是只在响应里
  const detail = (await (await page.request.get(`/api/notes/${note.id}`)).json()) as {
    title: string
    content: string
  }
  expect(detail.title).toBe(oldest.title)
  expect(detail.content).toContain('初版')
})

test('快照保存的是「修改前」的内容：历史里那一版能还原出旧文本', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const note = await api.createNote({ title: '改之前', content: '旧文本' })
  await api.updateNote(note.id, { content: '新文本' })

  const versions = (await (await page.request.get(`/api/notes/${note.id}/versions`)).json()) as {
    items: { id: string }[]
  }
  // 至少有一条历史，且它的内容是「旧文本」——这正是用户想回到的状态
  expect(versions.items.length).toBeGreaterThan(0)
  const first = (await (
    await page.request.get(`/api/notes/${note.id}/versions/${versions.items[versions.items.length - 1].id}`)
  ).json()) as { content: string }
  expect(first.content).toContain('旧文本')
})

test('内容没变的保存不产生新版本（自动保存不应刷屏）', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const note = await api.createNote({ title: '稳定', content: '不变的正文' })
  await api.updateNote(note.id, { content: '改一次' })

  const before = (await (await page.request.get(`/api/notes/${note.id}/versions`)).json()) as {
    items: unknown[]
  }

  // 与原值完全相同的 PATCH
  await api.updateNote(note.id, { content: '改一次' })

  const after = (await (await page.request.get(`/api/notes/${note.id}/versions`)).json()) as {
    items: unknown[]
  }
  expect(after.items.length).toBe(before.items.length)
})
