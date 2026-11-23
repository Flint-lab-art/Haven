import { createApi } from './api'
import { expect, test } from './fixtures'

/**
 * 文件夹与标签。
 *
 * 图标面板那一条是**回归用例**：它曾经因为 IconPicker 被渲染成 FolderTreeNode 的兄弟节点、
 * 丢失定位祖先而被 .tree 的 overflow 裁掉，状态明明打开却看不见。
 * jsdom 不做布局计算测不出来，只有真实浏览器能发现。
 */

/** 笔记树里某个文件夹的行。 */
function folderRow(page: import('@playwright/test').Page, name: string) {
  return page.locator('.tree-row--folder').filter({ hasText: name })
}

test('新建文件夹并重命名', async ({ authedPage: page }) => {
  await page.goto('/notes')

  await page.getByRole('button', { name: '新建文件夹' }).click()
  const input = page.getByLabel('新文件夹名')
  await input.fill('项目资料')
  await input.press('Enter')

  const row = folderRow(page, '项目资料')
  await expect(row).toBeVisible()

  // 重命名：打开行菜单
  await row.getByRole('button', { name: '更多操作' }).click()
  await page.getByRole('menuitem', { name: '重命名' }).click()
  // 行内切换为输入框（.tree-rename），值预填当前名称
  const renameInput = page.locator('.tree-rename')
  await expect(renameInput).toBeVisible()
  await renameInput.fill('项目文档')
  await renameInput.press('Enter')

  await expect(folderRow(page, '项目文档')).toBeVisible()
  await expect(folderRow(page, '项目资料')).toHaveCount(0)
})

test('文件夹可以嵌套子文件夹，并在重新加载后保留层级', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const parent = await api.createFolder('父级')
  await api.createFolder('子级', parent.id)

  await page.goto('/notes')
  await expect(folderRow(page, '父级')).toBeVisible()
  // 父级默认展开时子级可见；未展开则点开。
  // 先断言父级行已渲染，再判断子级——count() 不做自动等待，早于渲染会误判为 0。
  const child = folderRow(page, '子级')
  if (!(await child.isVisible().catch(() => false))) {
    await folderRow(page, '父级').getByRole('button', { name: /展开文件夹/ }).click()
  }
  await expect(child).toBeVisible()

  // 子级有更深的缩进
  const parentPadding = await folderRow(page, '父级').evaluate((el) => getComputedStyle(el).paddingLeft)
  const childPadding = await child.evaluate((el) => getComputedStyle(el).paddingLeft)
  expect(parseInt(childPadding, 10)).toBeGreaterThan(parseInt(parentPadding, 10))
})

test('图标面板点击后可见（回归：面板曾被 overflow 裁掉）', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.createFolder('带图标的文件夹')

  await page.goto('/notes')
  const row = folderRow(page, '带图标的文件夹')
  await expect(row).toBeVisible()

  // 点行内的图标按钮
  await row.getByRole('button', { name: /更改「带图标的文件夹」的图标/ }).click()

  const picker = page.locator('.icon-picker')
  await expect(picker).toBeVisible()

  // 关键断言：面板真的在视口内、有尺寸，且没有被祖先容器裁掉。
  // 只断言 exists/visible 不够——被 overflow 裁掉的元素仍可能被判为 visible，
  // 所以用 elementFromPoint 验证面板内部几个点都能命中面板自己。
  // 注意别断言「完整落在视口内」：树栏在窗口左侧，面板贴边是正常布局，不是 bug。
  const box = await picker.boundingBox()
  expect(box, '面板应渲染出实际尺寸').not.toBeNull()
  expect(box!.width).toBeGreaterThan(100)
  expect(box!.height).toBeGreaterThan(100)

  const visibleHitPoints = await picker.evaluate((el) => {
    const r = el.getBoundingClientRect()
    // 取面板内部、离边缘 8px 的九个点，避开圆角与边框
    const xs = [r.left + 8, r.left + r.width / 2, r.right - 8]
    const ys = [r.top + 8, r.top + r.height / 2, r.bottom - 8]
    return xs.flatMap((x) =>
      ys.map((y) => {
        const hit = document.elementFromPoint(x, y)
        return hit !== null && (hit === el || el.contains(hit))
      }),
    )
  })
  expect(visibleHitPoints, '面板内部各点都应能命中面板本身（未被裁掉）').toEqual(
    Array(9).fill(true),
  )

  // 选一个 emoji，文件夹图标应立刻变成 emoji（默认是 SVG 文件夹图标，没有 —emoji 类）
  const emojiButton = picker.getByRole('button', { name: /😀|🚀|📁/ }).first()
  const pickedEmoji = (await emojiButton.textContent())?.trim() ?? ''
  await emojiButton.click()

  const emojiIcon = row.locator('.tree-icon--emoji')
  await expect(emojiIcon).toBeVisible()
  await expect(emojiIcon).toHaveText(pickedEmoji)
})

test('右键菜单的「更改图标」同样能打开面板', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  await api.createFolder('右键测试')

  await page.goto('/notes')
  const row = folderRow(page, '右键测试')

  await row.click({ button: 'right' })
  await page.getByRole('menuitem', { name: '更改图标' }).click()

  await expect(page.locator('.icon-picker')).toBeVisible()
})

test('删除文件夹会把它里面的笔记移回收件箱，而不是一并删除', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const folder = await api.createFolder('待删目录')
  await api.createNote({ title: '目录里的笔记', folderId: folder.id })

  await page.goto('/notes')
  const row = folderRow(page, '待删目录')
  await row.getByRole('button', { name: '更多操作' }).click()
  await page.getByRole('menuitem', { name: '删除' }).click()
  await page.getByRole('alertdialog').getByRole('button', { name: '删除' }).click()

  await expect(folderRow(page, '待删目录')).toHaveCount(0)

  // 笔记没有被删除，而是到了收件箱
  const notes = await api.notes()
  const moved = notes.find((n) => n.title === '目录里的笔记')
  expect(moved, '笔记不应随文件夹一起消失').toBeTruthy()
  expect(moved!.folder_id).toBe(await api.inboxId())
})

test('标签页按引用次数展示，点开能看到引用它的笔记', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const tag = await api.createTag('重要')
  const note = await api.createNote({ title: '带标签的笔记', content: '正文' })
  await api.updateNote(note.id, { tagIds: [tag.id] })

  await page.goto('/tags')
  await expect(page.getByRole('heading', { name: '标签', level: 1 })).toBeVisible()

  const card = page.locator('.tag-card').filter({ hasText: '重要' })
  await expect(card).toBeVisible()

  await card.click()
  await expect(page.getByText('带标签的笔记').first()).toBeVisible()
})

test('在编辑页给笔记加标签后，标签页能看到', async ({ authedPage: page }) => {
  const api = createApi(page.request)
  const note = await api.createNote({ title: '待打标' })

  await page.goto(`/notes/${note.id}`)
  // 标签下拉需要先点「添加标签」展开
  await page.getByRole('button', { name: /添加标签/ }).click()
  const tagInput = page.getByLabel('搜索或输入新标签')
  await tagInput.fill('新标签')
  await tagInput.press('Enter')

  // 标签已挂到笔记上
  await expect(page.getByLabel('移除标签 新标签')).toBeVisible()

  await page.goto('/tags')
  await expect(page.locator('.tag-card').filter({ hasText: '新标签' })).toBeVisible()
})
