/**
 * 标签接口（docs/api.md 第八节）。
 *
 * 标签页只读：列表 + 按标签查笔记。创建在编辑笔记页的 TagDropdown 完成，
 * 删除接口保留但前端暂无入口。
 */
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

/** 某个标签引用的笔记（标签页点开标签时调用）。 */
export function listTagNotes(
  id: string,
  limit = 20,
  offset = 0,
): Promise<ListResult<NoteSummary>> {
  return request(`/api/tags/${id}/notes`, { query: { limit, offset } })
}
