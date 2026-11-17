import { beforeEach, describe, expect, it, vi } from 'vitest'
import { computed, createApp, effectScope, nextTick, ref } from 'vue'
import { AUTOSAVE_DELAY, useNoteAutoSave } from '@/composables/useNoteAutoSave'

/**
 * 自动保存状态机：防抖、排队、空白笔记、404 放弃。
 *
 * 这些分支原先埋在 NoteEditView 里，只能靠手点验证；抽成 composable 后可以直接测。
 *
 * 不引入 `@vue/test-utils`：composable 只需要一个 effect scope 与响应式引用，
 * 用 Vue 自带的 `effectScope` + `createApp` 就能跑。
 */
vi.mock('@/api/notes', () => ({
  createNote: vi.fn(),
  updateNote: vi.fn(),
}))

const { createNote, updateNote } = await import('@/api/notes')

type Options = Parameters<typeof useNoteAutoSave>[0]

function setup(overrides: Partial<Options> = {}) {
  const title = ref('标题')
  const content = ref('正文')
  const folderId = ref<string | null>(null)
  const selectedTagIds = ref<string[]>([])
  const note = ref<unknown>(null)
  const hydrating = ref(false)
  const isNew = overrides.isNew ?? ref(false)
  const isBlankNewNote = overrides.isBlankNewNote ?? ref(false)
  const noteId = computed(() => (isNew.value ? '' : 'note-1'))

  // composable 内部用了 watch，必须在 effect scope 里创建
  const scope = effectScope()
  let api!: ReturnType<typeof useNoteAutoSave>

  const app = createApp({
    setup() {
      api = useNoteAutoSave({
        noteId,
        isNew,
        draft: { title, content, folderId, selectedTagIds },
        note: note as never,
        hydrating,
        isBlankNewNote,
        isLeaving: () => false,
        replaceToDetail: vi.fn(),
        onTagsChanged: vi.fn(),
        onSaved: vi.fn(),
        onError: vi.fn(),
        ...overrides,
      })
      return () => null
    },
  })

  scope.run(() => app.mount(document.createElement('div')))

  return { api, title, content, folderId, selectedTagIds, note, hydrating, isNew, isBlankNewNote, scope }
}

describe('useNoteAutoSave', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
  })

  it('没有改动时不发请求', async () => {
    const { api } = setup()
    await api.save()
    expect(updateNote).not.toHaveBeenCalled()
  })

  it('改动后防抖保存', async () => {
    const { api, title } = setup()
    vi.mocked(updateNote).mockResolvedValue({ id: 'note-1' } as never)

    title.value = '改后'
    await nextTick()
    expect(api.saveState.value).toBe('dirty')

    await vi.advanceTimersByTimeAsync(AUTOSAVE_DELAY)
    await nextTick()

    expect(updateNote).toHaveBeenCalledTimes(1)
    expect(api.saveState.value).toBe('saved')
  })

  it('没有文件夹时用 clear_folder，而不是 folder_id: null', async () => {
    const { api, title } = setup()
    vi.mocked(updateNote).mockResolvedValue({ id: 'note-1' } as never)

    title.value = '改后'
    await api.save()

    const payload = vi.mocked(updateNote).mock.calls[0][1] as Record<string, unknown>
    expect(payload.clear_folder).toBe(true)
    expect(payload).not.toHaveProperty('folder_id')
  })

  it('有文件夹时传 folder_id', async () => {
    const { api, title, folderId } = setup()
    vi.mocked(updateNote).mockResolvedValue({ id: 'note-1' } as never)

    folderId.value = 'folder-9'
    title.value = '改后'
    await api.save()

    const payload = vi.mocked(updateNote).mock.calls[0][1] as Record<string, unknown>
    expect(payload.folder_id).toBe('folder-9')
    expect(payload).not.toHaveProperty('clear_folder')
  })

  it('空白新笔记不创建记录', async () => {
    const isNew = ref(true)
    const isBlankNewNote = ref(true)
    const { api, title } = setup({ isNew, isBlankNewNote })

    title.value = ''
    await api.save()

    expect(createNote).not.toHaveBeenCalled()
    expect(api.saveState.value).toBe('idle')
  })

  it('新建笔记保存后调用 createNote 并换路由', async () => {
    const isNew = ref(true)
    const replaceToDetail = vi.fn()
    vi.mocked(createNote).mockResolvedValue({ id: 'new-1' } as never)

    const { api, title } = setup({ isNew, replaceToDetail })

    title.value = '新笔记'
    await api.save()

    expect(createNote).toHaveBeenCalledTimes(1)
    expect(replaceToDetail).toHaveBeenCalledWith('new-1')
  })

  it('回填中不保存', async () => {
    const { api, title, hydrating } = setup()
    hydrating.value = true

    title.value = '改后'
    await nextTick()
    await api.save()

    expect(updateNote).not.toHaveBeenCalled()
  })

  it('cancelPending 取消待执行的防抖保存', async () => {
    const { api, title } = setup()
    vi.mocked(updateNote).mockResolvedValue({ id: 'note-1' } as never)

    title.value = '改后'
    await nextTick()
    api.cancelPending()

    await vi.advanceTimersByTimeAsync(AUTOSAVE_DELAY * 2)
    expect(updateNote).not.toHaveBeenCalled()
  })

  it('保存成功后把基线对齐，重复保存不再发请求', async () => {
    const { api, title } = setup()
    vi.mocked(updateNote).mockResolvedValue({ id: 'note-1' } as never)

    title.value = '改后'
    await api.save()
    await api.save()

    expect(updateNote).toHaveBeenCalledTimes(1)
  })
})
