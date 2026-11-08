/** GET /api/me（docs/api.md 11.1）。 */
import { request } from './client'

export interface MeUser {
  id: string
  username: string
  totp_enabled?: boolean
}

export interface MeResponse {
  anonymous: boolean
  auth_type?: 'session' | 'token'
  scope?: 'read' | 'read_write'
  user?: MeUser
}

export function getMe(): Promise<MeResponse> {
  return request<MeResponse>('/api/me', { skipUnauthorizedHandler: true })
}
