/** 标签接口（docs/api.md 第八节）。 */
import { request } from './client'
import type { ListResult } from './client'
import type { NoteSummary } from './notes'

export interface Tag {
  id: string
  name: string
  note_count: number
  created_at: string
}

export function listTags(): Promise<ListResult<Tag>> {
  return request<ListResult<Tag>>('/api/tags')
}

export function createTag(name: string): Promise<Tag> {
  return request<Tag>('/api/tags', { method: 'POST', body: { name } })
}

export function deleteTag(id: string): Promise<void> {
  return request<void>(`/api/tags/${id}`, { method: 'DELETE' })
}

export function listTagNotes(
  id: string,
  limit = 20,
  offset = 0,
): Promise<ListResult<NoteSummary>> {
  return request(`/api/tags/${id}/notes`, { query: { limit, offset } })
}
