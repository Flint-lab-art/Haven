/** 会话管理接口（docs/api.md 第三节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface SessionItem {
  id: string
  user_agent: string
  created_at: string
  last_used_at: string
  is_current: boolean
}

export function listSessions(): Promise<ListResult<SessionItem>> {
  return request<ListResult<SessionItem>>('/api/sessions')
}

export function revokeSession(id: string): Promise<void> {
  return request<void>(`/api/sessions/${id}`, { method: 'DELETE' })
}
