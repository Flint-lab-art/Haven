/**
 * 运行时前端配置。
 *
 * 同一份构建产物会部署在多个域名下（公开站点 + 私有站点），
 * 因此「哪个域名是私有域」不能写死在打包时的 `VITE_PRIVATE_HOST` 里，
 * 改域名就得重新打包。这里在应用启动时向后端取一次配置：
 * `GET /api/app-config` -> `{ "private_hosts": [...], "version": "1.1.0" }`。
 *
 * 取不到时（纯静态部署、后端未启动）退回构建期环境变量，
 * 行为与之前保持一致。
 */

export interface RuntimeConfig {
  /** 私有域主机名列表，已转成小写。 */
  privateHosts: string[]
  /** 应用版本号（以后端构建为准），未知时为空字符串。 */
  version: string
}

const EMPTY_CONFIG: RuntimeConfig = { privateHosts: [], version: '' }

let runtimeConfig: RuntimeConfig = EMPTY_CONFIG

/** 当前生效的运行时配置（只读）。 */
export function getRuntimeConfig(): RuntimeConfig {
  return runtimeConfig
}

/** 覆盖运行时配置，主要给测试用。 */
export function setRuntimeConfig(config: Partial<RuntimeConfig>): void {
  runtimeConfig = {
    privateHosts: normalizeHosts(config.privateHosts),
    version: typeof config.version === 'string'
        ? config.version.trim()
        : runtimeConfig.version,
  }
}

/** 把后端返回值 / 环境变量统一成小写主机名数组。 */
export function normalizeHosts(value: unknown): string[] {
  const raw = Array.isArray(value)
      ? value
      : typeof value === 'string'
          ? value.split(',')
          : []

  return raw
      .filter((host): host is string => typeof host === 'string')
      .map((host) => host.trim().toLowerCase())
      .filter((host) => host.length > 0)
}

/**
 * 从后端加载运行时配置。
 *
 * 失败不抛错：前端照常启动，`detectDomain` 会用构建期配置兜底。
 */
export async function loadRuntimeConfig(): Promise<RuntimeConfig> {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), 3000)

  try {
    const response = await fetch('/api/app-config', {
      credentials: 'same-origin',
      headers: { Accept: 'application/json' },
      signal: controller.signal,
    })
    if (!response.ok) {
      return runtimeConfig
    }

    const body = (await response.json()) as {
      private_hosts?: unknown
      version?: unknown
    }
    runtimeConfig = {
      privateHosts: normalizeHosts(body.private_hosts),
      version: typeof body.version === 'string' ? body.version.trim() : '',
    }
  } catch {
    // 离线或纯静态部署：保留构建期配置
  } finally {
    clearTimeout(timer)
  }
  return runtimeConfig
}