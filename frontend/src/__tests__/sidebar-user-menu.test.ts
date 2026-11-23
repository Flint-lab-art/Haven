import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { nextTick } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import PrivateSidebar from '@/components/layout/PrivateSidebar.vue'

/**
 * 守住「侧栏账户菜单可点击」这条契约。
 *
 * 迁移到 Reka Popover 时，触发按钮外面漏了 PopoverTrigger——它变成了一个
 * 没有 onClick 的普通 <button>：aria-expanded 永远 false，点了毫无反应。
 * 这类错误 vue-tsc 查不出来（模板里就是一个合法的 button），
 * 只有真的点一下才知道。
 */

const stub = { template: '<div />' }

/** 侧栏里的每个 RouterLink 都要有对应路由，否则解析失败。 */
const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', name: 'home', component: stub },
    { path: '/notes', name: 'workbench', component: stub },
    { path: '/search', name: 'search', component: stub },
    { path: '/tags', name: 'tags', component: stub },
    { path: '/ledger', name: 'ledger', component: stub },
    { path: '/issues', name: 'issues', component: stub },
    { path: '/trash', name: 'trash', component: stub },
    { path: '/settings', name: 'settings', component: stub },
    { path: '/login', name: 'login', component: stub },
  ],
})

function mountSidebar() {
  return mount(PrivateSidebar, {
    global: { plugins: [router] },
    attachTo: document.body,
  })
}

function userTrigger(): HTMLButtonElement {
  const el = document.querySelector('.user-trigger')
  if (!el) throw new Error('找不到 .user-trigger')
  return el as HTMLButtonElement
}

describe('侧栏账户菜单', () => {
  beforeEach(async () => {
    setActivePinia(createPinia())
    vi.stubGlobal('fetch', vi.fn(async () => new Response('{}', { status: 200 })))
    await router.push('/')
  })

  it('点触发按钮能打开菜单', async () => {
    const wrapper = mountSidebar()
    await nextTick()

    expect(document.querySelector('.user-menu')).toBeNull()

    userTrigger().click()
    await nextTick()
    await nextTick()

    expect(document.querySelector('.user-menu')).not.toBeNull()
    wrapper.unmount()
  })

  it('触发按钮的 aria-expanded 跟随开合状态', async () => {
    const wrapper = mountSidebar()
    await nextTick()

    // 漏掉 PopoverTrigger 时这里恒为 'false'，是最好的判据
    expect(userTrigger().getAttribute('aria-expanded')).toBe('false')

    userTrigger().click()
    await nextTick()
    await nextTick()
    expect(userTrigger().getAttribute('aria-expanded')).toBe('true')

    wrapper.unmount()
  })
})