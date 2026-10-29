/** 文件夹接口（docs/api.md 第六点五节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface Folder {
  id: string
  parent_id: string | null
  name: string
  sort_order: number
}

export interface CreateFolderInput {
  name: string
  parent_id?: string | null
}

export interface UpdateFolderInput {
  name?: string
  parent_id?: string | null
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
