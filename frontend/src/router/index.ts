import {
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
  type Router,
} from 'vue-router'
// 副作用导入：注册 RouteMeta 的类型扩展，让 meta 字段有具体类型
import './meta'
import { useAuthStore } from '@/stores/auth'
import mobileRoutes from './mobile'

/**
 * 私有路由（docs/frontend/frontend.md 第四节）。
 *
 * 除 `/login` 外全部挂在三栏布局下（ui-design.md 第二节）：
 * `default` 是右侧详情区，`list` 是中间列表栏。
 * 同一分区共用同一个 `list` 组件，切换右侧笔记时左、中两栏不重建。
 */
const noteList = () => import('@/components/note/NoteListPanel.vue')

const privateRoutes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/private/LoginView.vue'),
    meta: { title: '登录', public: true },
  },
  {
    path: '/',
    component: () => import('@/components/layout/PrivateLayout.vue'),
    children: [
      {
        // 仪表盘：概览统计（docs/v5/frontend/frontend.md 第一节）
        path: '',
        name: 'home',
        component: () => import('@/views/private/HomeView.vue'),
        // 仪表盘没有中间列表栏，详情区占满整行（docs/v5/frontend/frontend.md 第一节）
        meta: { title: '仪表盘', section: 'home', noList: true },
      },
      {
        // 工作台：从 / 迁移到 /notes（docs/v5/frontend/frontend.md 第一节）
        path: 'notes',
        name: 'workbench',
        components: {
          default: () => import('@/components/common/EmptyDetail.vue'),
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
          default: () => import('@/components/common/EmptyDetail.vue'),
          list: () => import('@/components/note/SearchPanel.vue'),
        },
        meta: {
          title: '搜索',
          section: 'search',
          emptyTitle: '搜索结果',
          emptyText: '在中间栏输入关键词；点击结果会打开对应笔记。',
        },
      },
      {
        // 标签页只读，不需要中间列表栏（docs/v3/frontend/frontend.md 第十节）
        path: 'tags',
        name: 'tags',
        component: () => import('@/views/private/TagsView.vue'),
        meta: { title: '标签', section: 'tags', noList: true },
      },
      {
        // 记账页（PC 三栏）：中间栏是明细列表，右侧是汇总与账户
        path: 'ledger',
        name: 'ledger',
        components: {
          default: () => import('@/views/private/LedgerView.vue'),
          list: () => import('@/components/ledger/LedgerListPanel.vue'),
        },
        meta: { title: '记账', section: 'ledger' },
      },
      {
        // Issue 面板（docs-ai/v8/frontend/frontend.md）
        path: 'issues',
        name: 'issues',
        component: () => import('@/views/private/IssuesView.vue'),
        meta: { title: 'Issue', section: 'issues', noList: true },
      },
      {
        // Issue 详情（docs-ai/v9/frontend/frontend.md）
        path: 'issues/:id',
        name: 'issue-detail',
        component: () => import('@/views/private/IssueDetailView.vue'),
        meta: { title: 'Issue', section: 'issues', noList: true },
      },
      {
        // 回收站（docs/v2/frontend/frontend.md 第一节）
        path: 'trash',
        name: 'trash',
        components: {
          default: () => import('@/views/private/TrashView.vue'),
          list: () => import('@/components/note/TrashPanel.vue'),
        },
        meta: {
          title: '回收站',
          section: 'trash',
          emptyTitle: '回收站里还没有东西',
          emptyText: '从左侧选一篇被删除的笔记，还原或永久删除。',
        },
      },
      {
        path: 'settings',
        name: 'settings',
        components: {
          default: () => import('@/views/private/SettingsHome.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '设置', section: 'settings' },
      },
      {
        path: 'settings/appearance',
        name: 'settings-appearance',
        components: {
          default: () => import('@/views/private/SettingsAppearance.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '外观', section: 'settings' },
      },
      {
        path: 'settings/security',
        name: 'settings-security',
        components: {
          default: () => import('@/views/private/SettingsSecurity.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '账号安全', section: 'settings' },
      },
      {
        path: 'settings/login-logs',
        name: 'settings-login-logs',
        components: {
          default: () => import('@/views/private/SettingsLoginLogs.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '登录日志', section: 'settings' },
      },
      {
        path: 'settings/sessions',
        name: 'settings-sessions',
        components: {
          default: () => import('@/views/private/SettingsSessions.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '会话', section: 'settings' },
      },
      {
        path: 'settings/devices',
        name: 'settings-devices',
        components: {
          default: () => import('@/views/private/SettingsDevices.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '授信设备', section: 'settings' },
      },
      {
        path: 'settings/tokens',
        name: 'settings-tokens',
        components: {
          default: () => import('@/views/private/SettingsTokens.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: 'API Token', section: 'settings' },
      },
      {
        path: 'settings/budget',
        name: 'settings-budget',
        components: {
          default: () => import('@/views/private/SettingsBudget.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '预算', section: 'settings' },
      },
      {
        path: 'settings/accounts',
        name: 'settings-accounts',
        components: {
          default: () => import('@/views/private/SettingsAccounts.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '账户', section: 'settings' },
      },
      {
        path: 'settings/import',
        name: 'settings-import',
        components: {
          default: () => import('@/views/private/SettingsImport.vue'),
          list: () => import('@/components/common/SettingsPanel.vue'),
        },
        meta: { title: '导入账单', section: 'settings' },
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/private/NotFoundView.vue'),
    // 不标 public：私有域下未登录访问未知路径也应先去登录（frontend.md 第四节）
    meta: { title: '页面不存在' },
  },
]

export function createHavenRouter(): Router {
  const router = createRouter({
    history: createWebHistory(),
    // 移动端路由挂在 /m/ 下，与 PC 共用同一份数据层与鉴权守卫
    routes: [...privateRoutes, ...mobileRoutes],
    scrollBehavior: () => ({ top: 0 }),
  })

  router.beforeEach(async (to) => {
    const auth = useAuthStore()
    if (!auth.initialized) {
      await auth.refresh()
    }

    if (to.meta.public === true) {
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
    const title = to.meta.title ?? '笔记'
    document.title = `${title} · Haven`
  })

  return router
}

export default createHavenRouter()
