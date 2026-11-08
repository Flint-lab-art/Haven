import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

/**
 * 首页路由（docs/v5/frontend/frontend.md 第一节）。
 *
 * - `/` 改为概览首页，section 为 home；
 * - 工作台从 `/` 挪到 `/notes`，section 仍为 notes；
 * - `/notes/:id` 仍是笔记详情，不能被 `/notes` 吞掉。
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
  auth.isLoggedIn = true
})

afterEach(() => {
  vi.clearAllMocks()
})

describe('首页与工作台路由', () => {
  it('/ 是首页，section 为 home', async () => {
    const router = await loadRouter()

    await router.push('/')
    expect(router.currentRoute.value.name).toBe('home')
    expect(router.currentRoute.value.meta.section).toBe('home')
  })

  it('/notes 是工作台，section 为 notes', async () => {
    const router = await loadRouter()

    await router.push('/notes')
    expect(router.currentRoute.value.name).toBe('workbench')
    expect(router.currentRoute.value.meta.section).toBe('notes')
  })

  it('/notes/:id 仍是笔记详情', async () => {
    const router = await loadRouter()

    await router.push('/notes/abc')
    expect(router.currentRoute.value.name).toBe('note-detail')
    expect(router.currentRoute.value.params.id).toBe('abc')
  })

  it('/notes/new 仍是新建笔记', async () => {
    const router = await loadRouter()

    await router.push('/notes/new')
    expect(router.currentRoute.value.name).toBe('note-create')
  })

  it('首页与标签页标记为无列表栏，笔记页保持有列表栏', async () => {
    const router = await loadRouter()

    await router.push('/')
    expect(router.currentRoute.value.meta.noList).toBe(true)

    await router.push('/tags')
    expect(router.currentRoute.value.meta.noList).toBe(true)

    await router.push('/notes')
    expect(router.currentRoute.value.meta.noList).toBeUndefined()

    await router.push('/search')
    expect(router.currentRoute.value.meta.noList).toBeUndefined()
  })

  it('未登录访问首页跳登录', async () => {
    auth.isLoggedIn = false
    const router = await loadRouter()

    await router.push('/')
    expect(router.currentRoute.value.name).toBe('login')
  })
})
