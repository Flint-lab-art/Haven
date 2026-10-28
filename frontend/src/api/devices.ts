/** 授信设备接口（docs/api.md 第四节）。不提供创建：只能在登录时 trust_device。 */
import { request } from './client'
import type { ListResult } from './client'

export interface TrustedDeviceItem {
  id: string
  device_name: string
  created_at: string
  last_used_at: string
  expires_at: string
}

export function listDevices(): Promise<ListResult<TrustedDeviceItem>> {
  return request<ListResult<TrustedDeviceItem>>('/api/trusted-devices')
}

export function revokeDevice(id: string): Promise<void> {
  return request<void>(`/api/trusted-devices/${id}`, { method: 'DELETE' })
}
