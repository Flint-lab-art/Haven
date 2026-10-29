/** API Token 接口（docs/api.md 第五节）。全部需要会话通过过 TOTP。 */
import { request } from './client'
import type { ListResult } from './client'

export interface TokenItem {
  id: string
  name: string
  token_prefix: string
  scope: 'read' | 'read_write'
  expires_at: string | null
  last_used_at: string | null
  revoked_at: string | null
  created_at: string
}

export interface CreatedToken extends TokenItem {
  /** 明文，只在创建时返回一次。 */
  token: string
}

export interface CreateTokenInput {
  name: string
  scope: 'read' | 'read_write'
  expires_at: string | null
}

export function listTokens(): Promise<ListResult<TokenItem>> {
  return request<ListResult<TokenItem>>('/api/tokens')
}

export function createToken(input: CreateTokenInput): Promise<CreatedToken> {
  return request<CreatedToken>('/api/tokens', { method: 'POST', body: input })
}

export function revokeToken(id: string): Promise<void> {
  return request<void>(`/api/tokens/${id}`, { method: 'DELETE' })
}
