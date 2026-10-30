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
    component: () => import('@/components/PublicLayout.vue'),
    children: [
      {
        path: '',
        name: 'public-home',
        component: () => import('@/views/public/PublicHome.vue'),
        meta: { title: '笔记' },
      },
      {
        path: 'notes/:id',
        name: 'public-note',
        component: () => import('@/views/public/PublicNote.vue'),
        meta: { title: '笔记' },
      },
      {
        path: 'search',
        name: 'public-search',
        component: () => import('@/views/public/PublicSearch.vue'),
        meta: { title: '搜索' },
      },
      {
        path: 'portfolio',
        name: 'public-portfolio',
        component: () => import('@/views/public/PublicPortfolio.vue'),
        meta: { title: '作品集' },
      },
      {
        path: ':pathMatch(.*)*',
        name: 'public-not-found',
        component: () => import('@/views/public/PublicNotFound.vue'),
        meta: { title: '页面不存在' },
      },
    ],
  },
]

/**
 * 私有域路由（docs/frontend/frontend.md 第四节）。
 *
 * 除 `/login` 外全部挂在三栏布局下（ui-design.md 第二节）：
 * `default` 是右侧详情区，`list` 是中间列表栏。
 * 同一分区共用同一个 `list` 组件，切换右侧笔记时左、中两栏不重建。
 */
const noteList = () => import('@/components/NoteListPanel.vue')

const privateRoutes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/private/LoginView.vue'),
    meta: { title: '登录', public: true },
  },
  {
    path: '/',
    component: () => import('@/components/PrivateLayout.vue'),
    children: [
      {
        path: '',
        name: 'workbench',
        components: {
          default: () => import('@/components/EmptyDetail.vue'),
          list: noteList,
        },
        meta: {
          title: '笔记',
          section: 'notes',
          emptyTitle: '选择一篇笔记',
          emptyText: '从左侧列表选择，或新建一篇；内容会显示在这里。',
        },
      },
      {
        // 新建：标题与标签由弹窗通过 query 带进来（title / tag_ids），正文在编辑页写
        path: 'notes/new',
        name: 'note-create',
        components: {
          default: () => import('@/views/private/NoteEditView.vue'),
          list: noteList,
        },
        meta: { title: '新建笔记', section: 'notes' },
      },
      {
        path: 'notes/:id',
        name: 'note-detail',
        components: {
          default: () => import('@/views/private/NoteEditView.vue'),
          list: noteList,
        },
        meta: { title: '笔记', section: 'notes' },
      },
      {
        path: 'search',
        name: 'search',
        components: {
          default: () => import('@/components/EmptyDetail.vue'),
          list: () => import('@/components/SearchPanel.vue'),
        },
        meta: {
          title: '搜索',
          section: 'search',
          emptyTitle: '搜索结果',
          emptyText: '在中间栏输入关键词；点击结果会打开对应笔记。',
        },
      },
      {
        path: 'tags',
        name: 'tags',
        components: {
          default: () => import('@/views/private/TagsView.vue'),
          list: () => import('@/components/TagsPanel.vue'),
        },
        meta: { title: '标签', section: 'tags' },
      },
      {
        path: 'portfolio',
        name: 'portfolio',
        components: {
          default: () => import('@/views/private/PortfolioView.vue'),
          list: () => import('@/components/PortfolioPanel.vue'),
        },
        meta: { title: '作品集', section: 'portfolio' },
      },
      {
        path: 'settings',
        name: 'settings',
        components: {
          default: () => import('@/views/private/SettingsHome.vue'),
          list: () => import('@/components/SettingsPanel.vue'),
        },
        meta: { title: '设置', section: 'settings' },
      },
      {
        path: 'settings/security',
        name: 'settings-security',
        components: {
          default: () => import('@/views/private/SettingsSecurity.vue'),
          list: () => import('@/components/SettingsPanel.vue'),
        },
        meta: { title: '账号安全', section: 'settings' },
      },
      {
        path: 'settings/sessions',
        name: 'settings-sessions',
        components: {
          default: () => import('@/views/private/SettingsSessions.vue'),
          list: () => import('@/components/SettingsPanel.vue'),
        },
        meta: { title: '会话', section: 'settings' },
      },
      {
        path: 'settings/devices',
        name: 'settings-devices',
        components: {
          default: () => import('@/views/private/SettingsDevices.vue'),
          list: () => import('@/components/SettingsPanel.vue'),
        },
        meta: { title: '授信设备', section: 'settings' },
      },
      {
        path: 'settings/tokens',
        name: 'settings-tokens',
        components: {
          default: () => import('@/views/private/SettingsTokens.vue'),
          list: () => import('@/components/SettingsPanel.vue'),
        },
        meta: { title: 'API Token', section: 'settings' },
      },
      {
        // 公开笔记预览（docs/frontend/frontend.md 第四节最后一行，可选）
        path: 'preview/notes/:id',
        name: 'note-preview',
        components: {
          default: () => import('@/views/private/PreviewNoteView.vue'),
          list: noteList,
        },
        meta: { title: '预览', section: 'notes' },
      },
    ],
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
