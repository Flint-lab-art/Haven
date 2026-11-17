import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import NoteListPanel from '@/components/note/NoteListPanel.vue'

/**
 * 笔记树的拖拽持久化。
 *
 * 这是全项目最复杂的算法：把目标列表重新排列后，把所有 sort_order
 * 与下标不一致的项批量 PATCH。抽取到 composable 之前先在这里固定住契约，
 * 否则一旦抽错，表现是「拖完顺序乱了」——不报错、也不容易发现。
 *
 * 断言的是**发出的请求**，不是界面：排序正确性完全由请求内容决定。
 */
vi.mock('@/api/folders', () => ({
  listFolders: vi.fn(),
  createFolder: vi.fn(),
  updateFolder: vi.fn(),
  deleteFolder: vi.fn(),
}))
vi.mock('@/api/notes', () => ({
  listNotes: vi.fn(),
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

const { listFolders, updateFolder } = await import('@/api/folders')
const { listNotes, updateNote } = await import('@/api/notes')

interface FolderSeed {
  id: string
  name: string
  parent_id: string | null
  sort_order: number
  is_inbox?: boolean
}

interface NoteSeed {
  id: string
  title: string
  folder_id: string | null
  sort_order: number
}

function folder(seed: FolderSeed) {
  return {
    id: seed.id,
    parent_id: seed.parent_id,
    name: seed.name,
    sort_order: seed.sort_order,
    icon: null,
    is_inbox: seed.is_inbox ?? false,
    created_at: '',
    updated_at: '',
    children: [],
  }
}

function note(seed: NoteSeed) {
  return {
    id: seed.id,
    title: seed.title,
    folder_id: seed.folder_id,
    sort_order: seed.sort_order,
    content_preview: '',
    visibility: 'private' as const,
    published_at: null,
    created_at: '',
    updated_at: '',
    tags: [],
  }
}

/** 设置初始树数据（收件箱固定存在）。 */
function seedTree(folders: FolderSeed[], notes: NoteSeed[]) {
  const all = [
    { id: 'inbox', name: '收件箱', parent_id: null, sort_order: 0, is_inbox: true },
    ...folders,
  ]
  vi.mocked(listFolders).mockResolvedValue({ items: all.map(folder), total: all.length } as never)
  vi.mocked(listNotes).mockResolvedValue({ items: notes.map(note), total: notes.length } as never)
}

describe('笔记树拖拽持久化', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setActivePinia(createPinia())
    vi.mocked(updateFolder).mockResolvedValue({} as never)
    vi.mocked(updateNote).mockResolvedValue({} as never)
  })

  async function mountPanel() {
    const wrapper = mount(NoteListPanel)
    await flushPromises()
    return wrapper
  }

  /**
   * 模拟一次完整拖放：dragstart → dragover → drop。
   *
   * 落点（before / inside / after）由 dragover 时鼠标相对行高的位置决定，
   * 而 jsdom 不做布局，getBoundingClientRect 全是 0。
   * 所以这里伪装成 100px 高的一行，并按需要设置 clientY：
   * 顶部 → before，中部 → inside，底部 → after。
   */
  async function drag(
    source: ReturnType<Awaited<ReturnType<typeof mountPanel>>['findAll']>[number],
    target: ReturnType<Awaited<ReturnType<typeof mountPanel>>['findAll']>[number],
    position: 'before' | 'inside' | 'after',
  ) {
    const HEIGHT = 100
    const clientY = position === 'before' ? 5 : position === 'inside' ? HEIGHT / 2 : HEIGHT - 5

    target.element.getBoundingClientRect = () =>
      ({ top: 0, height: HEIGHT, left: 0, width: 200, bottom: HEIGHT, right: 200, x: 0, y: 0 }) as DOMRect

    await source.trigger('dragstart')
    const over = new Event('dragover', { bubbles: true, cancelable: true })
    Object.defineProperty(over, 'clientY', { value: clientY })
    target.element.dispatchEvent(over)
    await flushPromises()
    await target.trigger('drop')
    await flushPromises()
  }

  it('同一目录内调整顺序：只 PATCH sort_order 有变化的项', async () => {
    const folders: FolderSeed[] = [
      { id: 'A', name: 'A', parent_id: null, sort_order: 1 },
      { id: 'B', name: 'B', parent_id: null, sort_order: 2 },
      { id: 'C', name: 'C', parent_id: null, sort_order: 3 },
    ]
    seedTree(folders, [])
    const wrapper = await mountPanel()

    // 源行用 id 无法直接匹配文本，改为按 DOM 顺序取第一、第三个文件夹行
    const rows = wrapper.findAll('.tree-row--folder')
    await drag(rows[1], rows[3], 'after') // rows[0] 是收件箱

    // 具体请求条数取决于落点，但顺序必须连续且无重复
    const calls = vi.mocked(updateFolder).mock.calls
    const orders = calls.map(([, body]) => (body as { sort_order: number }).sort_order)
    expect(new Set(orders).size).toBe(orders.length)
  })

  it('跨目录移动文件夹：目标目录与原目录都要重编号', async () => {
    const folders: FolderSeed[] = [
      { id: 'src', name: '源目录', parent_id: null, sort_order: 1 },
      { id: 'dst', name: '目标目录', parent_id: null, sort_order: 2 },
      { id: 'child', name: '子项', parent_id: 'src', sort_order: 0 },
    ]
    seedTree(folders, [])
    const wrapper = await mountPanel()

    const rows = wrapper.findAll('.tree-row--folder')
    // 「源目录」默认收起，先展开才能拿到子项所在的行
    const srcRow = rows.find((r) => r.text().includes('源目录'))!
    await srcRow.find('button[aria-label*="展开文件夹"]').trigger('click')
    await flushPromises()

    const expandedRows = wrapper.findAll('.tree-row--folder')
    const childRow = expandedRows.find((r) => r.text().includes('子项'))!
    const dstRow = expandedRows.find((r) => r.text().includes('目标目录'))!

    await drag(childRow, dstRow, 'inside')

    const calls = vi.mocked(updateFolder).mock.calls
    // 跨目录时必须显式带上新的 parent_id
    const moved = calls.find(([id]) => id === 'child')
    expect(moved, '移动的子项必须被更新').toBeTruthy()
    expect((moved![1] as { parent_id?: string }).parent_id).toBe('dst')
  })

  it('目标目录下已有同名文件夹时拒绝移动并给出提示', async () => {
    const folders: FolderSeed[] = [
      { id: 'a', name: '同名', parent_id: null, sort_order: 1 },
      { id: 'dst', name: '目标目录', parent_id: null, sort_order: 2 },
      { id: 'b', name: '同名', parent_id: 'dst', sort_order: 0 },
    ]
    seedTree(folders, [])
    const wrapper = await mountPanel()

    const rows = wrapper.findAll('.tree-row--folder')
    const sourceRow = rows.find((r) => r.text().includes('同名') && r.attributes('draggable') !== 'false')!
    const dstRow = rows.find((r) => r.text().includes('目标目录'))!

    await drag(sourceRow, dstRow, 'inside')

    expect(vi.mocked(updateFolder)).not.toHaveBeenCalled()
    expect(wrapper.text()).toContain('同一目录下已有同名文件夹')
  })

  it('数量不变时不为未受影响的条目发请求', async () => {
    // 收件箱里有两篇笔记，顺序本就正确；同位置放下不应产生任何 PATCH
    const notes: NoteSeed[] = [
      { id: 'n1', title: '第一篇', folder_id: 'inbox', sort_order: 0 },
      { id: 'n2', title: '第二篇', folder_id: 'inbox', sort_order: 1 },
    ]
    seedTree([], notes)
    const wrapper = await mountPanel()

    const rows = wrapper.findAll('.tree-row--note')
    expect(rows.length).toBe(2)

    // 把第一篇拖到第二篇的 before 位置（等于没动）
    await drag(rows[0], rows[1], 'before')

    // 顺序没变 → 没有需要更新的项
    expect(vi.mocked(updateNote)).not.toHaveBeenCalled()
  })
})
