/**
 * 公开域与私有域的路由表（docs/frontend/frontend.md 第一、三、四节）。
 *
 * 同一份构建部署在两个域名下，启动时按 window.location.hostname 选择路由表：
 * - 公开域：只有只读页面，没有登录入口、没有后台链接；
 * - 私有域：工作台 + 设置，除 /login 外全部需要登录。
 */

import { getRuntimeConfig, normalizeHosts } from '@/config'

/** 设置当前域名是否为私有域。 */
export type DomainKind = 'public' | 'private'

/**
 * 判断当前域名属于哪一侧。
 *
 * 私有域名单优先取后端下发的运行时配置（`GET /api/app-config`），
 * 取不到时退回构建期的 `VITE_PRIVATE_HOST`（支持逗号分隔的多个域名）。
 * 都没有配置时：本机地址当私有域方便开发，其余按公开域处理。
 */
export function detectDomain(
  hostname: string,
  configured?: string | readonly string[],
): DomainKind {
  const runtimeHosts = getRuntimeConfig().privateHosts
  const buildHosts = normalizeHosts(configured ?? import.meta.env.VITE_PRIVATE_HOST)
  const privateHosts = runtimeHosts.length > 0 ? runtimeHosts : buildHosts
  const host = hostname.trim().toLowerCase()

  if (privateHosts.length > 0) {
    return privateHosts.includes(host) ? 'private' : 'public'
  }

  // 本地开发：localhost / 127.0.0.1 / 局域网 IP 一律视为私有域
  if (host === 'localhost' || host === '127.0.0.1' || host.endsWith('.localhost')) {
    return 'private'
  }
  if (/^\d+\.\d+\.\d+\.\d+$/.test(host)) {
    return 'private'
  }
  // 生产环境：默认当公开域，私有域必须显式配置
  return 'public'
}
