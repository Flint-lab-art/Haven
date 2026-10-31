import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

/**
 * 标签页路由（docs/v3/frontend/frontend.md 第十节）。
 *
 * 标签页只读，挂在私有域：未登录要跳登录，登录后能进。
 * jsdom 默认 localhost 被判为私有域，不需要 mock domain。
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
  auth.isLoggedIn = false
})

afterEach(() => {
  vi.clearAllMocks()
})

describe('标签页路由', () => {
  it('未登录访问 /tags 跳登录并保留 redirect', async () => {
    const router = await loadRouter()

    await router.push('/tags')
    expect(router.currentRoute.value.name).toBe('login')
    expect(router.currentRoute.value.query.redirect).toBe('/tags')
  })

  it('已登录可以进入 /tags，section 为 tags', async () => {
    auth.isLoggedIn = true
    const router = await loadRouter()

    await router.push('/tags')
    expect(router.currentRoute.value.name).toBe('tags')
    expect(router.currentRoute.value.meta.section).toBe('tags')
  })
})
