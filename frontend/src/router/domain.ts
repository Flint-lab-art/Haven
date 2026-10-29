/**
 * 公开域与私有域的路由表（docs/frontend/frontend.md 第一、三、四节）。
 *
 * 同一份构建部署在两个域名下，启动时按 window.location.hostname 选择路由表：
 * - 公开域：只有只读页面，没有登录入口、没有后台链接；
 * - 私有域：工作台 + 设置，除 /login 外全部需要登录。
 */

/** 设置当前域名是否为私有域。 */
export type DomainKind = 'public' | 'private'

/**
 * 判断当前域名属于哪一侧。
 *
 * 生产上由 HAVEN_COOKIE_DOMAIN（如 app.example.com）决定；本地开发没有
 * 两个域名，这里按「本机地址 + 环境变量」兜底，全部当作私有域，
 * 方便本地测管理功能。
 */
export function detectDomain(hostname: string, configured = import.meta.env.VITE_PRIVATE_HOST): DomainKind {
  if (configured) {
    return hostname === configured ? 'private' : 'public'
  }
  // 本地开发：localhost / 127.0.0.1 / 局域网 IP 一律视为私有域
  if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname.endsWith('.localhost')) {
    return 'private'
  }
  if (/^\d+\.\d+\.\d+\.\d+$/.test(hostname)) {
    return 'private'
  }
  // 生产环境：默认当公开域，私有域必须显式配置 VITE_PRIVATE_HOST
  return 'public'
}
