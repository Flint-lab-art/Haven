import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

/**
 * 回收站路由与侧边栏归属（docs/v2/frontend/frontend.md 第一、二节）。
 *
 * - /trash 与其它私有域页面一样需要登录，未登录跳 /login 并保留 redirect；
 * - 路由 meta.section 必须是 'trash'，侧边栏据此高亮，不会误亮「笔记」「作品集」等项。
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

describe('回收站路由', () => {
  it('未登录访问 /trash 跳登录并保留 redirect', async () => {
    const router = await loadRouter()

    await router.push('/trash')
    expect(router.currentRoute.value.name).toBe('login')
    expect(router.currentRoute.value.query.redirect).toBe('/trash')
  })

  it('已登录可以进入 /trash，且 section 为 trash', async () => {
    auth.isLoggedIn = true
    const router = await loadRouter()

    await router.push('/trash')
    expect(router.currentRoute.value.name).toBe('trash')
    expect(router.currentRoute.value.meta.section).toBe('trash')
  })

  it('回收站的 section 与其它导航项不重叠', async () => {
    auth.isLoggedIn = true
    const router = await loadRouter()

    const bySection = new Map<string, string>()
    for (const record of router.getRoutes()) {
      const section = record.meta.section
      if (typeof section !== 'string' || !section) continue
      // 同一 section 允许多个路由（如 settings/*），但 trash 必须是回收站专属
      const name = String(record.name ?? '')
      bySection.set(section, `${bySection.get(section) ?? ''}${name},`)
    }

    const trashRoutes = bySection.get('trash')
    expect(trashRoutes).toBeDefined()
    expect(trashRoutes).toContain('trash')
    // 回收站不应与笔记工作台共用 section
    expect(bySection.get('notes')).not.toContain('trash')
  })
})
