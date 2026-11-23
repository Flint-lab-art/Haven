import type { RouteRecordRaw } from 'vue-router'

/**
 * 移动端路由（`/m/`）。
 *
 * 与 PC 共用数据层（`src/api/*`），但布局与页面完全独立：
 * 底部 tab 四只：记账 / 统计 / 账户 / 我的。
 * 记账是默认页；Issue 与设置收进「我的」。
 *
 * 入口由**路径**决定，不做 UA 嗅探：PC 上也能直接打开 `/m/` 预览。
 */
const mobileRoutes: RouteRecordRaw[] = [
  {
    path: '/m',
    component: () => import('@/components/mobile/MobileLayout.vue'),
    children: [
      {
        // 默认落在记账：记账是最高频的动作
        path: '',
        name: 'm-ledger',
        component: () => import('@/views/mobile/MobileLedger.vue'),
        meta: { title: '记账', mTab: 'ledger' },
      },
      {
        path: 'stats',
        name: 'm-stats',
        component: () => import('@/views/mobile/MobileStats.vue'),
        meta: { title: '统计', mTab: 'stats' },
      },
      {
        // 账户提升为顶级 tab，不再藏在「我的」里
        path: 'accounts',
        name: 'm-accounts',
        component: () => import('@/views/mobile/MobileAccounts.vue'),
        meta: { title: '账户', mTab: 'accounts' },
      },
      {
        path: 'me',
        name: 'm-me',
        component: () => import('@/views/mobile/MobileMe.vue'),
        meta: { title: '我的', mTab: 'me' },
      },
      {
        path: 'me/budget',
        name: 'm-budget',
        component: () => import('@/views/mobile/MobileBudget.vue'),
        meta: { title: '预算', mTab: 'me' },
      },
      {
        path: 'me/settings',
        name: 'm-settings',
        component: () => import('@/views/mobile/MobileSettings.vue'),
        meta: { title: '设置', mTab: 'me' },
      },
      {
        path: 'me/appearance',
        name: 'm-appearance',
        component: () => import('@/views/mobile/MobileAppearance.vue'),
        meta: { title: '外观', mTab: 'me' },
      },
      {
        path: 'me/login-logs',
        name: 'm-login-logs',
        component: () => import('@/views/mobile/MobileLoginLogs.vue'),
        meta: { title: '登录日志', mTab: 'me' },
      },
      {
        path: 'me/issues',
        name: 'm-issues',
        component: () => import('@/views/mobile/MobileIssues.vue'),
        meta: { title: 'Issue', mTab: 'me' },
      },
      {
        path: 'me/issues/new',
        name: 'm-issue-new',
        component: () => import('@/views/mobile/MobileIssueNew.vue'),
        meta: { title: '新建 Issue', mTab: 'me' },
      },
      {
        path: 'me/issues/:id',
        name: 'm-issue-detail',
        component: () => import('@/views/mobile/MobileIssueDetail.vue'),
        meta: { title: 'Issue', mTab: 'me' },
      },
    ],
  },
]

export default mobileRoutes
