/**
 * 路由 `meta` 的类型扩展。
 *
 * Vue Router 4 的 `RouteMeta` 默认是空接口，自定义字段都会被推断成 `unknown`，
 * 于是每个读取点都得手写 `typeof x === 'string'` 收窄。这里集中声明一次。
 *
 * 新增 meta 字段时必须同时加到这里，否则 `vue-tsc` 会在定义处报错。
 */
import 'vue-router'

/** 三栏布局的当前栏目，用于侧边栏高亮。 */
export type RouteSection =
  | 'home'
  | 'notes'
  | 'search'
  | 'tags'
  | 'trash'
  | 'ledger'
  | 'issues'
  | 'settings'

declare module 'vue-router' {
  interface RouteMeta {
    /** 页面标题，用于 `document.title`。 */
    title?: string
    /** 是否忽略登录态校验（只有登录页需要）。 */
    public?: boolean
    /** 当前栏目，侧边栏据此高亮。 */
    section?: RouteSection
    /** 整页内容不需要右侧列表栏（首页、标签页等）。 */
    noList?: boolean
    /** 右侧空态标题。 */
    emptyTitle?: string
    /** 右侧空态说明。 */
    emptyText?: string
    /** 移动端底部 tab 高亮项。 */
    mTab?: 'ledger' | 'stats' | 'accounts' | 'me'
  }
}
