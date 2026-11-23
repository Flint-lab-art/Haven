/** 登录日志接口（docs/auth.md 登录审计）。 */
import { request } from './client'
import type { ListResult } from './client'

export type LoginLogEventType = 'login_success' | 'login_failure' | 'totp_failure' | 'logout'

export interface LoginLogItem {
  id: string
  event_type: LoginLogEventType
  username: string
  /** password / totp / session */
  method: string
  success: boolean
  failure_reason: string | null
  ip: string
  user_agent: string
  created_at: string
}

/** 自己的登录历史；只有浏览器会话可读，API Token 会拿到 403。 */
export function listLoginLogs(
  limit = 50,
  offset = 0,
): Promise<ListResult<LoginLogItem>> {
  return request<ListResult<LoginLogItem>>('/api/auth/login-logs', {
    query: { limit, offset },
  })
}
