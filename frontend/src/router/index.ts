import {
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
  type Router,
} from 'vue-router'
import { detectDomain } from './domain'
import { useAuthStore } from '@/stores/auth'

/** 公开域路由（docs/frontend/frontend.md 第三节）：全部匿名可访问，无写入口。 */
const publicRoutes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'public-home',
    component: () => import('@/views/public/PublicHome.vue'),
    meta: { title: '笔记' },
  },
  {
    path: '/notes/:id',
    name: 'public-note',
    component: () => import('@/views/public/PublicNote.vue'),
    meta: { title: '笔记' },
  },
  {
    path: '/search',
    name: 'public-search',
    component: () => import('@/views/public/PublicSearch.vue'),
    meta: { title: '搜索' },
  },
  {
    path: '/portfolio',
    name: 'public-portfolio',
    component: () => import('@/views/public/PublicPortfolio.vue'),
    meta: { title: '作品集' },
  },
]

/** 私有域路由（docs/frontend/frontend.md 第四节）。 */
const privateRoutes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/private/LoginView.vue'),
    meta: { title: '登录', public: true },
  },
  {
    path: '/',
    name: 'workbench',
    component: () => import('@/views/private/NoteListView.vue'),
    meta: { title: '笔记' },
  },
  {
    // 新建：标题与标签由弹窗通过 query 带进来（title / tag_ids），正文在编辑页写
    path: '/notes/new',
    name: 'note-create',
    component: () => import('@/views/private/NoteEditView.vue'),
    meta: { title: '新建笔记' },
  },
  {
    path: '/notes/:id',
    name: 'note-detail',
    component: () => import('@/views/private/NoteEditView.vue'),
    meta: { title: '笔记' },
  },
  {
    path: '/search',
    name: 'search',
    component: () => import('@/views/private/SearchView.vue'),
    meta: { title: '搜索' },
  },
  {
    path: '/tags',
    name: 'tags',
    component: () => import('@/views/private/TagsView.vue'),
    meta: { title: '标签' },
  },
  {
    path: '/portfolio',
    name: 'portfolio',
    component: () => import('@/views/private/PortfolioView.vue'),
    meta: { title: '作品集' },
  },
  {
    path: '/settings',
    name: 'settings',
    component: () => import('@/views/private/SettingsHome.vue'),
    meta: { title: '设置' },
  },
  {
    path: '/settings/security',
    name: 'settings-security',
    component: () => import('@/views/private/SettingsSecurity.vue'),
    meta: { title: '账号安全' },
  },
  {
    path: '/settings/sessions',
    name: 'settings-sessions',
    component: () => import('@/views/private/SettingsSessions.vue'),
    meta: { title: '会话' },
  },
  {
    path: '/settings/devices',
    name: 'settings-devices',
    component: () => import('@/views/private/SettingsDevices.vue'),
    meta: { title: '授信设备' },
  },
  {
    path: '/settings/tokens',
    name: 'settings-tokens',
    component: () => import('@/views/private/SettingsTokens.vue'),
    meta: { title: 'API Token' },
  },
  {
    // 公开笔记预览（docs/frontend/frontend.md 第四节最后一行，可选）
    path: '/preview/notes/:id',
    name: 'note-preview',
    component: () => import('@/views/public/PublicNote.vue'),
    meta: { title: '预览' },
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/private/NotFoundView.vue'),
    meta: { title: '页面不存在', public: true },
  },
]

export function createHavenRouter(hostname = window.location.hostname): Router {
  const domain = detectDomain(hostname)
  const routes = domain === 'private' ? privateRoutes : publicRoutes

  const router = createRouter({
    history: createWebHistory(),
    routes,
    scrollBehavior: () => ({ top: 0 }),
  })

  router.beforeEach(async (to) => {
    // 公开域不做登录态判断（docs/frontend/frontend.md 第三节规则）
    if (domain !== 'private') {
      return true
    }

    const auth = useAuthStore()
    if (!auth.initialized) {
      await auth.refresh()
    }

    if (to.meta.public) {
      // 已登录访问登录页：进目标页（没有 redirect 就进工作台）
      if (to.name === 'login' && auth.isLoggedIn) {
        const redirect = to.query.redirect
        const path = typeof redirect === 'string' && redirect.startsWith('/') && !redirect.startsWith('//')
          ? redirect
          : '/'
        return path
      }
      return true
    }

    if (!auth.isLoggedIn) {
      return { name: 'login', query: { redirect: to.fullPath } }
    }
    return true
  })

  router.afterEach((to) => {
    const title = typeof to.meta.title === 'string' ? to.meta.title : '笔记'
    document.title = `${title} · Haven`
  })

  return router
}

export default createHavenRouter()
