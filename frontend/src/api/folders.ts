/** 文件夹接口（docs/api.md 第六点五节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface Folder {
  id: string
  parent_id: string | null
  name: string
  /** 自定义 Emoji 图标；null 表示使用默认文件夹图标。 */
  icon: string | null
  /** 是否为收件箱；固定在根目录第一位，不可删除、不可移动。 */
  is_inbox: boolean
  sort_order: number
}

export interface CreateFolderInput {
  name: string
  parent_id?: string | null
  icon?: string | null
}

export interface UpdateFolderInput {
  name?: string
  parent_id?: string | null
  icon?: string | null
  sort_order?: number
}

export function listFolders(): Promise<ListResult<Folder>> {
  return request<ListResult<Folder>>('/api/folders')
}

export function createFolder(input: CreateFolderInput): Promise<Folder> {
  return request<Folder>('/api/folders', { method: 'POST', body: input })
}

export function updateFolder(id: string, input: UpdateFolderInput): Promise<Folder> {
  return request<Folder>(`/api/folders/${id}`, { method: 'PATCH', body: input })
}

export function deleteFolder(id: string): Promise<void> {
  return request<void>(`/api/folders/${id}`, { method: 'DELETE' })
}
