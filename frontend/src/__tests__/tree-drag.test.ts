import { beforeEach, describe, expect, it } from 'vitest'
import { useTreeDrag } from '@/composables/useTreeDrag'
import type { Folder } from '@/api/folders'
import type { NoteSummary } from '@/api/notes'

/**
 * 拖拽状态机：谁能拖、能拖到哪、落在哪个位置。
 *
 * 这些规则原先埋在 NoteListPanel 的 50 行事件处理里，只能手点验证。
 */
function folder(id: string, parentId: string | null = null, isInbox = false): Folder {
  return {
    id,
    parent_id: parentId,
    name: id,
    icon: null,
    is_inbox: isInbox,
    sort_order: 0,
    created_at: '',
    updated_at: '',
    children: [],
  } as Folder
}

function note(id: string): NoteSummary {
  return {
    id,
    folder_id: null,
    sort_order: 0,
    title: id,
    content_preview: '',
    created_at: '',
    updated_at: '',
    tags: [],
  } as NoteSummary
}

/** 构造一个带 clientY 的拖拽事件，currentTarget 带可控的 rect。 */
function dragEvent(clientY: number, rect = { top: 100, height: 40 }, target?: Element): DragEvent {
  const el = document.createElement('div')
  el.getBoundingClientRect = () => ({ ...rect, bottom: rect.top + rect.height, left: 0, right: 100, width: 100, x: 0, y: rect.top, toJSON: () => ({}) })
  const event = new Event('dragover') as unknown as DragEvent
  Object.defineProperty(event, 'clientY', { value: clientY })
  Object.defineProperty(event, 'currentTarget', { value: el })
  Object.defineProperty(event, 'target', { value: target ?? el })
  Object.defineProperty(event, 'preventDefault', { value: () => {} })
  Object.defineProperty(event, 'dataTransfer', {
    value: { effectAllowed: '', dropEffect: '', setData: () => {} },
  })
  return event
}

describe('useTreeDrag', () => {
  let folders: Folder[]
  let busy: boolean
  let drag: ReturnType<typeof useTreeDrag>

  beforeEach(() => {
    folders = [folder('inbox', null, true), folder('work'), folder('child', 'work'), folder('other')]
    busy = false
    drag = useTreeDrag(
      () => folders,
      () => busy,
    )
  })

  it('初始没有拖拽状态', () => {
    expect(drag.dragState.value).toBeNull()
    expect(drag.dropTarget.value).toBeNull()
    expect(drag.dragging.value).toBe(false)
  })

  it('开始拖文件夹后记录拖拽源', () => {
    drag.startFolderDrag(dragEvent(110), folders[1])

    expect(drag.dragState.value).toEqual({ kind: 'folder', id: 'work' })
    expect(drag.dragging.value).toBe(true)
    expect(drag.isDragging('folder', 'work')).toBe(true)
    expect(drag.isDragging('note', 'work')).toBe(false)
  })

  it('收件箱不能被拖动', () => {
    drag.startFolderDrag(dragEvent(110), folders[0])

    expect(drag.dragState.value).toBeNull()
  })

  it('忙碌时不能开始拖拽', () => {
    busy = true
    drag.startFolderDrag(dragEvent(110), folders[1])

    expect(drag.dragState.value).toBeNull()
  })

  it('拖到文件夹上时按位置判定 before / after', () => {
    // 用与 work 平级的 other 作落点；拖到 child（work 的子节点）会被子树规则拦下
    drag.startFolderDrag(dragEvent(110), folders[1])

    drag.onFolderDragOver(dragEvent(105), folders[3])
    expect(drag.dropTarget.value).toEqual({ kind: 'folder', id: 'other', position: 'before' })

    drag.onFolderDragOver(dragEvent(135), folders[3])
    expect(drag.dropTarget.value).toEqual({ kind: 'folder', id: 'other', position: 'after' })
  })

  it('不能拖进自己或自己的子树', () => {
    drag.startFolderDrag(dragEvent(110), folders[1])

    // 拖到自己身上
    drag.onFolderDragOver(dragEvent(120), folders[1])
    expect(drag.dropTarget.value).toBeNull()

    // 拖到自己的子文件夹里
    drag.onFolderDragOver(dragEvent(120), folders[2])
    expect(drag.dropTarget.value).toBeNull()
  })

  it('拖到收件箱上永远视为放入', () => {
    drag.startFolderDrag(dragEvent(110), folders[1])

    drag.onFolderDragOver(dragEvent(105), folders[0])

    expect(drag.dropTarget.value).toEqual({ kind: 'folder', id: 'inbox', position: 'inside' })
  })

  it('笔记拖到文件夹上永远是放入', () => {
    drag.startNoteDrag(dragEvent(110), note('n1'))

    drag.onFolderDragOver(dragEvent(105), folders[1])

    expect(drag.dropTarget.value).toEqual({ kind: 'folder', id: 'work', position: 'inside' })
  })

  it('笔记拖到笔记上只有 before / after', () => {
    drag.startNoteDrag(dragEvent(110), note('n1'))

    drag.onNoteDragOver(dragEvent(105), note('n2'))
    expect(drag.dropTarget.value).toEqual({ kind: 'note', id: 'n2', position: 'before' })

    drag.onNoteDragOver(dragEvent(135), note('n2'))
    expect(drag.dropTarget.value).toEqual({ kind: 'note', id: 'n2', position: 'after' })
  })

  it('拖到自己身上不算落点', () => {
    drag.startNoteDrag(dragEvent(110), note('n1'))

    drag.onNoteDragOver(dragEvent(105), note('n1'))

    expect(drag.dropTarget.value).toBeNull()
  })

  it('没有拖拽时 hover 不产生落点', () => {
    drag.onFolderDragOver(dragEvent(105), folders[1])

    expect(drag.dropTarget.value).toBeNull()
  })

  it('拖到树底部时落点为 root', () => {
    drag.startFolderDrag(dragEvent(110), folders[1])

    drag.onRootDragOver(dragEvent(200))

    expect(drag.dropTarget.value).toEqual({ kind: 'root' })
    expect(drag.isDrop('root', null)).toBe(true)
  })

  it('isDrop 按 kind / id / position 逐项匹配', () => {
    drag.startFolderDrag(dragEvent(110), folders[1])
    drag.onFolderDragOver(dragEvent(105), folders[3])

    expect(drag.isDrop('folder', 'other')).toBe(true)
    expect(drag.isDrop('folder', 'other', 'before')).toBe(true)
    expect(drag.isDrop('folder', 'other', 'after')).toBe(false)
    expect(drag.isDrop('folder', 'work')).toBe(false)
    expect(drag.isDrop('note', 'other')).toBe(false)
  })

  it('clearDrag 清空两个状态', () => {
    drag.startFolderDrag(dragEvent(110), folders[1])
    drag.onRootDragOver(dragEvent(200))

    drag.clearDrag()

    expect(drag.dragState.value).toBeNull()
    expect(drag.dropTarget.value).toBeNull()
    expect(drag.dragging.value).toBe(false)
  })
})
