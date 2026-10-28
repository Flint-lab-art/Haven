/** 认证相关接口（docs/api.md 第二节）。 */
import { request } from './client'

export interface UserBrief {
  id: string
  username: string
}

export interface LoginResult {
  user: UserBrief
  totp_required: boolean
  /** 仅 totp_required 为 true 时出现，只放内存，不落 localStorage。 */
  temp_token?: string
}

export interface TotpSetupResult {
  secret: string
  otpauth_uri: string
}

export function login(username: string, password: string, trustDevice: boolean): Promise<LoginResult> {
  return request<LoginResult>('/api/auth/login', {
    method: 'POST',
    body: { username, password, trust_device: trustDevice },
    // 登录失败就是 401，不应触发全局登出
    skipUnauthorizedHandler: true,
  })
}

export function loginTotp(tempToken: string, code: string): Promise<LoginResult> {
  return request<LoginResult>('/api/auth/login/totp', {
    method: 'POST',
    body: { temp_token: tempToken, code },
    skipUnauthorizedHandler: true,
  })
}

export function logout(): Promise<void> {
  return request<void>('/api/auth/logout', { method: 'POST' })
}

export function setupTotp(): Promise<TotpSetupResult> {
  return request<TotpSetupResult>('/api/auth/totp/setup', { method: 'POST' })
}

export function verifyTotp(secret: string, code: string): Promise<{ totp_enabled: boolean }> {
  return request('/api/auth/totp/verify', { method: 'POST', body: { secret, code } })
}

export function disableTotp(code: string): Promise<{ totp_enabled: boolean }> {
  return request('/api/auth/totp/disable', { method: 'POST', body: { code } })
}

export function changePassword(
  oldPassword: string,
  newPassword: string,
  totpCode?: string,
): Promise<void> {
  return request<void>('/api/auth/password', {
    method: 'POST',
    body: { old_password: oldPassword, new_password: newPassword, totp_code: totpCode ?? '' },
  })
}
