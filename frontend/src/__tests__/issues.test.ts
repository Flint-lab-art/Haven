import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import {
  ISSUE_PRIORITY_LABEL,
  ISSUE_STATUS_LABEL,
  ISSUE_TYPE_LABEL,
  isIssueStatus,
  priorityTone,
} from '@/utils/issues'

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