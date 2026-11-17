import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import NoteListPanel from '@/components/note/NoteListPanel.vue'

/**
 * 文件夹图标的完整链路：点图标按钮 → 打开面板 → 选 emoji → 调 PATCH → 刷新。
 *
 * 之前只测了 IconPicker 自身（能发事件），没测父组件是否正确接线，
 * 结果「点了没反应」这种问题溜了过去。这里补齐父组件侧。
 */
vi.mock('@/api/folders', () => ({
  listFolders: vi.fn(),
  createFolder: vi.fn(),
  updateFolder: vi.fn(),
  deleteFolder: vi.fn(),
}))
vi.mock('@/api/notes', () => ({
  listNotes: vi.fn(async () => ({ items: [], total: 0 })),
  deleteNote: vi.fn(),
  publishNote: vi.fn(),
  unpublishNote: vi.fn(),
  updateNote: vi.fn(),
}))
vi.mock('@/api/uploads', () => ({
  uploadImage: vi.fn(),
  listUploads: vi.fn(async () => ({ items: [], total: 0 })),
  isUploadableImage: vi.fn(() => false),
}))
vi.mock('vue-router', () => ({
  useRoute: () => ({ params: {} }),
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
}))

const inbox = {
  id: 'inbox',
  parent_id: null,
  name: '收件箱',
  icon: null,
  is_inbox: true,
  sort_order: 0,
  created_at: '',
  updated_at: '',
  children: [],
}
const work = {
  ...inbox,
  id: 'work',
  name: '工作',
  is_inbox: false,
  sort_order: 1,
}

const { listFolders, updateFolder } = vi.mocked(await import('@/api/folders'))

describe('NoteListPanel 文件夹图标', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setActivePinia(createPinia())
    listFolders.mockResolvedValue({ items: [inbox, work], total: 2 })
  })

  async function mountPanel() {
    const wrapper = mount(NoteListPanel)
    await flushPromises()
    return wrapper
  }

  it('点文件夹行的图标按钮会打开图标面板', async () => {
    const wrapper = await mountPanel()

    // 未打开时面板不存在
    expect(wrapper.find('.icon-picker').exists()).toBe(false)

    // 点「工作」那行的图标按钮
    const rows = wrapper.findAll('.tree-row--folder')
    expect(rows.length).toBeGreaterThanOrEqual(2)
    await rows[1].find('.tree-icon-btn').trigger('click')
    await flushPromises()

    expect(wrapper.find('.icon-picker').exists()).toBe(true)
  })

  it('在面板里选 emoji 会调用 updateFolder 并关掉面板', async () => {
    const wrapper = await mountPanel()

    const rows = wrapper.findAll('.tree-row--folder')
    await rows[1].find('.tree-icon-btn').trigger('click')
    await flushPromises()

    const firstEmoji = wrapper.find('.icon-picker__emoji-btn')
    const expected = firstEmoji.text()
    await firstEmoji.trigger('click')
    await flushPromises()

    expect(updateFolder).toHaveBeenCalledWith('work', { icon: expected })
    expect(wrapper.find('.icon-picker').exists()).toBe(false)
  })

  it('「恢复默认」发出 icon: null', async () => {
    // 让「工作」带一个图标，才能触发「与当前不同」的保存
    listFolders.mockResolvedValue({ items: [inbox, { ...work, icon: '🍀' }], total: 2 })
    const wrapper = await mountPanel()

    await wrapper.findAll('.tree-row--folder')[1].find('.tree-icon-btn').trigger('click')
    await flushPromises()

    const restore = wrapper.findAll('.icon-picker__actions button')[0]
    await restore.trigger('click')
    await flushPromises()

    expect(updateFolder).toHaveBeenCalledWith('work', { icon: null })
  })

  it('右键菜单的「更改图标」也能打开面板', async () => {
    const wrapper = await mountPanel()

    const row = wrapper.findAll('.tree-row--folder')[1]
    await row.trigger('contextmenu')
    await flushPromises()

    const menuItems = wrapper.findAll('.tree-menu__item')
    expect(menuItems.length).toBeGreaterThan(0)
    // 第 3 项是「更改图标」
    await menuItems[2].trigger('click')
    await flushPromises()

    expect(wrapper.find('.icon-picker').exists()).toBe(true)
  })

  it('选了与当前相同的图标不会发请求', async () => {
    listFolders.mockResolvedValue({ items: [inbox, { ...work, icon: '📁' }], total: 2 })
    const wrapper = await mountPanel()

    await wrapper.findAll('.tree-row--folder')[1].find('.tree-icon-btn').trigger('click')
    await flushPromises()

    // 找到显示为 📁 的那个 emoji 按钮
    const same = wrapper.findAll('.icon-picker__emoji-btn').find((btn) => btn.text() === '📁')
    expect(same).toBeTruthy()
    await same!.trigger('click')
    await flushPromises()

    expect(updateFolder).not.toHaveBeenCalled()
    expect(wrapper.find('.icon-picker').exists()).toBe(false)
  })
})
