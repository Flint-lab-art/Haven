/**
 * 运行时前端配置接口（`GET /api/app-config`）。
 *
 * 同一份构建产物会部署在多个域名下（公开站点 + 私有站点），
 * 因此「哪个域名是私有域」不能写死在打包时的 `VITE_PRIVATE_HOST` 里。
 * 应用启动时向这个接口取一次配置，见 `src/config.ts`。
 */
import { request } from './client'

/** 后端 `AppConfigResponse` 的对应类型。 */
export interface AppConfigResponse {
  version: string
  /** 私有域主机名列表；后端以逗号分隔的配置生成。 */
  private_hosts: string[]
}

/** 拉取运行时配置。调用方负责兜底（失败不应阻断启动）。 */
export function getAppConfig(timeoutMs = 3000): Promise<AppConfigResponse> {
  return request<AppConfigResponse>('/api/app-config', { timeoutMs })
}
