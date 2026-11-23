import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

/**
 * 路由守卫（docs/frontend/implementation.md 第四节）：
 * 除 /login 外全部需要登录，包括未知路径。
 *
 * 现在只有一张路由表，登录守卫对所有页面一视同仁。
 * 每个用例先 resetModules 再动态 import，避免共享同一份路由实例。
 */
const auth = { initialized: true, isLoggedIn: false, refresh: vi.fn(async () => {}) }

vi.mock('@/stores/auth', () => ({ useAuthStore: () => auth }))

async function loadRouter() {
  vi.resetModules()
  const mod = await import('@/router/index')
  return mod.default
}

beforeEach(() => {
  // jsdom 没实现 scrollTo，路由的 scrollBehavior 会调用它
  vi.spyOn(window, 'scrollTo').mockImplementation(() => {})
  setActivePinia(createPinia())
  auth.initialized = true
  auth.isLoggedIn = false
})

afterEach(() => {
  vi.clearAllMocks()
})

describe('路由守卫', () => {
  it('未登录访问未知路径要先跳登录，而不是直接展示 404', async () => {
    const router = await loadRouter()

    await router.push('/这个路径不存在')
    expect(router.currentRoute.value.name).toBe('login')
    expect(router.currentRoute.value.query.redirect).toBe('/这个路径不存在')
  })

  it('未登录访问工作台跳登录并保留 redirect', async () => {
    const router = await loadRouter()

    await router.push('/tags')
    expect(router.currentRoute.value.name).toBe('login')
    expect(router.currentRoute.value.query.redirect).toBe('/tags')
  })

  it('已登录访问未知路径才展示 404', async () => {
    auth.isLoggedIn = true
    const router = await loadRouter()

    await router.push('/这个路径不存在')
    expect(router.currentRoute.value.name).toBe('not-found')
  })
})
