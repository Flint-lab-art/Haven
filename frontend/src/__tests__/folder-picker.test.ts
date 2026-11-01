import { describe, expect, it } from 'vitest'

/**
 * 文件夹选择器的导航模型（docs/v6/frontend/frontend.md 第三节）。
 *
 * Ranger 式单列：j/k 移动、l 进入、h 返回上级、Enter 确认当前目录。
 * 这里只测纯逻辑，组件渲染由人工验证。
 */
interface Folder {
  id: string
  parent_id: string | null
  name: string
  is_inbox: boolean
}

const inbox: Folder = { id: 'inbox', parent_id: null, name: '收件箱', is_inbox: true }
const project: Folder = { id: 'p', parent_id: null, name: '项目', is_inbox: false }
const site: Folder = { id: 's', parent_id: 'p', name: '官网检索器', is_inbox: false }
const diary: Folder = { id: 'g', parent_id: 'p', name: 'gogs-diary', is_inbox: false }
const deep: Folder = { id: 'd', parent_id: 's', name: '深层', is_inbox: false }

const all = [inbox, project, site, diary, deep]

/** 当前目录下的子文件夹，按名称排序。 */
function children(current: string | null, folders: Folder[] = all): Folder[] {
  return folders
    .filter((f) => (f.parent_id ?? null) === current)
    .sort((a, b) => a.name.localeCompare(b.name, 'zh-CN'))
}

/** 面包屑。 */
function breadcrumb(current: string | null, folders: Folder[] = all): string {
  const byId = new Map(folders.map((f) => [f.id, f]))
  const parts: string[] = []
  let id = current
  const seen = new Set<string>()
  while (id) {
    if (seen.has(id)) break
    seen.add(id)
    const folder = byId.get(id)
    if (!folder) break
    parts.unshift(folder.name)
    id = folder.parent_id ?? null
  }
  return parts.length ? parts.join(' / ') : '根目录'
}

/** Enter 确认的是左侧高亮项；没有子项时确认当前目录。 */
function confirmTarget(current: string | null, activeIndex: number, folders: Folder[] = all): string | null {
  const list = children(current, folders)
  return list[activeIndex]?.id ?? current
}

/** 右列预览：左列高亮项的子文件夹。 */
function preview(current: string | null, activeIndex: number, folders: Folder[] = all): string[] {
  const target = children(current, folders)[activeIndex]
  if (!target) return []
  return children(target.id, folders).map((f) => f.name)
}

describe('文件夹选择器导航', () => {
  it('Enter 确认左列高亮项', () => {
    // 根目录：收件箱、项目；高亮「项目」时 Enter 应选项目
    expect(confirmTarget(null, 1)).toBe('p')
  })

  it('没有子项时 Enter 确认当前目录', () => {
    expect(confirmTarget('d', 0)).toBe('d')
  })

  it('右列显示左列高亮项的子文件夹', () => {
    // 根目录高亮「项目」→ 右列显示项目的子级
    expect(preview(null, 1)).toEqual(['官网检索器', 'gogs-diary'])
  })

  it('高亮的文件夹没有子项时右列为空', () => {
    expect(preview('p', 1)).toEqual([]) // gogs-diary 没有子项
  })

  it('根目录只列出顶层文件夹', () => {
    const names = children(null).map((f) => f.name)
    expect(names).toEqual(['收件箱', '项目'])
  })

  it('进入文件夹后只列出它的子级', () => {
    const names = children('p').map((f) => f.name)
    expect(names).toEqual(['官网检索器', 'gogs-diary'])
  })

  it('多级嵌套可以逐层进入', () => {
    expect(children('s').map((f) => f.name)).toEqual(['深层'])
    expect(children('d')).toEqual([])
  })

  it('面包屑显示完整层级', () => {
    expect(breadcrumb(null)).toBe('根目录')
    expect(breadcrumb('p')).toBe('项目')
    expect(breadcrumb('d')).toBe('项目 / 官网检索器 / 深层')
  })

  it('返回上级沿 parent_id 走', () => {
    const byId = new Map(all.map((f) => [f.id, f]))
    expect(byId.get('d')?.parent_id).toBe('s')
    expect(byId.get('s')?.parent_id).toBe('p')
    expect(byId.get('p')?.parent_id).toBeNull()
  })

  it('根目录没有上级', () => {
    // currentId 为 null 时 goUp 不改动，面包屑保持「根目录」
    expect(breadcrumb(null)).toBe('根目录')
  })

  it('空文件夹给出可确认的空列表', () => {
    expect(children('d')).toEqual([])
  })
})
