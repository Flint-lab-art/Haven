import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

/**
 * 公开域路由（docs/v3/frontend/frontend.md 第一节）。
 *
 * 首页改为「作品集 + 近期笔记」，公开笔记全集挪到 /notes；
 * 两条路由都匿名可访问，且 /notes 不能被 /notes/:id 吞掉。
 *
 * 路由表在模块加载时按 hostname 选定，所以每个用例先改 hostname 再 resetModules。
 */
const auth = { initialized: true, isLoggedIn: false, refresh: vi.fn(async () => {}) }

vi.mock('@/stores/auth', () => ({ useAuthStore: () => auth }))
// domain.ts 把 localhost 当私有域，这里直接把域名判定固定为公开域
vi.mock('@/router/domain', () => ({ detectDomain: () => 'public' }))

async function loadRouterAsPublic() {
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
  vi.restoreAllMocks()
  vi.clearAllMocks()
})

describe('公开域路由', () => {
  it('匿名可以访问首页', async () => {
    const router = await loadRouterAsPublic()

    await router.push('/')
    expect(router.currentRoute.value.name).toBe('public-home')
  })

  it('/notes 解析为全部笔记页，而不是笔记详情', async () => {
    const router = await loadRouterAsPublic()

    await router.push('/notes')
    expect(router.currentRoute.value.name).toBe('public-notes')
    expect(router.currentRoute.value.params.id).toBeUndefined()
  })

  it('/notes/:id 仍解析为笔记详情', async () => {
    const router = await loadRouterAsPublic()

    await router.push('/notes/abc')
    expect(router.currentRoute.value.name).toBe('public-note')
    expect(router.currentRoute.value.params.id).toBe('abc')
  })

  it('搜索页保留，可直接访问', async () => {
    const router = await loadRouterAsPublic()

    await router.push('/search?q=test')
    expect(router.currentRoute.value.name).toBe('public-search')
  })

  it('公开域没有登录路由，未知路径落到 404', async () => {
    const router = await loadRouterAsPublic()

    await router.push('/login')
    expect(router.currentRoute.value.name).toBe('public-not-found')
  })
})
