import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import {
  ISSUE_PRIORITY_LABEL,
  ISSUE_STATUS_LABEL,
  ISSUE_TYPE_LABEL,
  buildIssueTree,
  hasIssueChildren,
  isIssueStatus,
  parentFeatureOptions,
  priorityTone,
} from '@/utils/issues'
import type { Issue } from '@/api/issues'

/**
 * Issue 面板路由与展示映射（docs-ai/v8/frontend/frontend.md、ui-design.md 第九节）。
 */
const auth = { initialized: true, isLoggedIn: false, refresh: vi.fn(async () => {}) }

vi.mock('@/stores/auth', () => ({ useAuthStore: () => auth }))

async function loadRouter() {
  vi.resetModules()
  const mod = await import('@/router/index')
  return mod.default
}

beforeEach(() => {
  vi.spyOn(window, 'scrollTo').mockImplementation(() => {})
  setActivePinia(createPinia())
  auth.initialized = true
  auth.isLoggedIn = false
})

afterEach(() => {
  vi.clearAllMocks()
})

describe('Issue 路由', () => {
  it('未登录访问 /issues 跳登录并保留 redirect', async () => {
    const router = await loadRouter()

    await router.push('/issues')
    expect(router.currentRoute.value.name).toBe('login')
    expect(router.currentRoute.value.query.redirect).toBe('/issues')
  })

  it('已登录可以进入 /issues，且 section 为 issues', async () => {
    auth.isLoggedIn = true
    const router = await loadRouter()

    await router.push('/issues')
    expect(router.currentRoute.value.name).toBe('issues')
    expect(router.currentRoute.value.meta.section).toBe('issues')
    expect(router.currentRoute.value.meta.noList).toBe(true)
  })

  it('公开域不注册 /issues', async () => {
    const router = await loadRouter()
    const publicRoutes = router
      .getRoutes()
      .filter((record) => record.path.startsWith('/public'))
      .map((record) => String(record.name ?? ''))
    expect(publicRoutes).not.toContain('issues')
  })

  it('已登录可以进入 /issues/:id，且 section 为 issues', async () => {
    auth.isLoggedIn = true
    const router = await loadRouter()

    await router.push('/issues/00000000-0000-0000-0000-000000000000')
    expect(router.currentRoute.value.name).toBe('issue-detail')
    expect(router.currentRoute.value.meta.section).toBe('issues')
    expect(router.currentRoute.value.meta.noList).toBe(true)
  })
})

describe('Issue 展示映射', () => {
  it('类型文案', () => {
    expect(ISSUE_TYPE_LABEL.bug).toBe('Bug')
    expect(ISSUE_TYPE_LABEL.feature).toBe('Feature')
  })

  it('状态文案', () => {
    expect(ISSUE_STATUS_LABEL.todo).toBe('待办')
    expect(ISSUE_STATUS_LABEL.in_progress).toBe('进行中')
    expect(ISSUE_STATUS_LABEL.done).toBe('已完成')
  })

  it('优先级文案与色阶', () => {
    expect(ISSUE_PRIORITY_LABEL).toEqual({ low: '低', medium: '中', high: '高' })
    expect(priorityTone('high')).toBe('high')
    expect(priorityTone('medium')).toBe('medium')
    expect(priorityTone('low')).toBe('low')
  })

  it('isIssueStatus 只接受三个合法值', () => {
    expect(isIssueStatus('todo')).toBe(true)
    expect(isIssueStatus('in_progress')).toBe(true)
    expect(isIssueStatus('done')).toBe(true)
    expect(isIssueStatus('doing')).toBe(false)
  })
})

function issue(id: string, overrides: Partial<Issue> = {}): Issue {
  return {
    id,
    parent_id: null,
    title: id,
    description: '',
    type: 'feature',
    status: 'todo',
    priority: 'medium',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

describe('Issue 一级树组装', () => {
  it('把子 Feature 挂到顶层 Feature 下', () => {
    const tree = buildIssueTree([
      issue('parent'),
      issue('child', { parent_id: 'parent' }),
      issue('bug', { type: 'bug' }),
    ])
    expect(tree).toHaveLength(2)
    expect(tree[0].id).toBe('parent')
    expect(tree[0].children.map((item) => item.id)).toEqual(['child'])
    expect(tree[1].children).toEqual([])
  })

  it('父不在当前结果里时，子项降级为根', () => {
    const tree = buildIssueTree([issue('orphan', { parent_id: 'missing' })])
    expect(tree).toHaveLength(1)
    expect(tree[0].id).toBe('orphan')
  })

  it('最多一层：父本身是子项时，第二层按根展示', () => {
    const tree = buildIssueTree([
      issue('parent'),
      issue('child', { parent_id: 'parent' }),
      issue('grandchild', { parent_id: 'child' }),
    ])
    expect(tree.map((item) => item.id)).toEqual(['parent', 'grandchild'])
    expect(tree[0].children.map((item) => item.id)).toEqual(['child'])
  })

  it('父需求下拉只包含顶层 Feature，并排除自身', () => {
    const items = [
      issue('root'),
      issue('other-root'),
      issue('child', { parent_id: 'root' }),
      issue('bug', { type: 'bug' }),
    ]
    expect(parentFeatureOptions(items).map((item) => item.id)).toEqual(['root', 'other-root'])
    expect(parentFeatureOptions(items, 'root').map((item) => item.id)).toEqual(['other-root'])
  })

  it('hasIssueChildren 能识别子项', () => {
    const items = [issue('parent'), issue('child', { parent_id: 'parent' })]
    expect(hasIssueChildren(items, 'parent')).toBe(true)
    expect(hasIssueChildren(items, 'child')).toBe(false)
  })
})
