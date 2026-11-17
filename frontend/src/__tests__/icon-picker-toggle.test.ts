import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import NoteListPanel from '@/components/note/NoteListPanel.vue'

/**
 * 图标面板的开关时序。
 *
 * 真实浏览器里，点按钮会依次派发 pointerdown → pointerup → click。
 * 文档级 pointerdown 监听器若在 target 不在面板内时关闭面板，
 * 就会出现「面板闪一下又消失」：click 刚打开，后续事件又把它关掉。
 *
 * 这里的用例固定住正确行为：点触发按钮本身不应被文档监听器关闭。
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

const { listFolders } = await import('@/api/folders')

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
const work = { ...inbox, id: 'work', name: '工作', is_inbox: false, sort_order: 1 }

describe('文件夹图标面板的开关时序', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setActivePinia(createPinia())
    vi.mocked(listFolders).mockResolvedValue({ items: [inbox, work], total: 2 } as never)
  })

  async function mountPanel() {
    const wrapper = mount(NoteListPanel)
    await flushPromises()
    return wrapper
  }

  it('点图标按钮打开的瞬间不会被文档级 pointerdown 关掉', async () => {
    const wrapper = await mountPanel()
    const btn = wrapper.findAll('.tree-row--folder')[1].find('.tree-icon-btn')

    // 真实顺序：pointerdown 先于 click
    await btn.trigger('pointerdown')
    await btn.trigger('click')
    await flushPromises()

    expect(wrapper.find('.icon-picker').exists()).toBe(true)
  })

  it('打开后点面板外部才关闭', async () => {
    const wrapper = await mountPanel()
    const btn = wrapper.findAll('.tree-row--folder')[1].find('.tree-icon-btn')

    await btn.trigger('pointerdown')
    await btn.trigger('click')
    await flushPromises()
    expect(wrapper.find('.icon-picker').exists()).toBe(true)

    // 点面板外部
    document.body.dispatchEvent(new Event('pointerdown', { bubbles: true }))
    await flushPromises()

    expect(wrapper.find('.icon-picker').exists()).toBe(false)
  })

  it('再次点同一个图标按钮会收起面板（toggle）', async () => {
    const wrapper = await mountPanel()
    const btn = wrapper.findAll('.tree-row--folder')[1].find('.tree-icon-btn')

    await btn.trigger('pointerdown')
    await btn.trigger('click')
    await flushPromises()
    expect(wrapper.find('.icon-picker').exists()).toBe(true)

    await btn.trigger('pointerdown')
    await btn.trigger('click')
    await flushPromises()

    expect(wrapper.find('.icon-picker').exists()).toBe(false)
  })
})
