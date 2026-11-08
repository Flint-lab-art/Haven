/** 搜索接口（docs/api.md 第九节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface SearchNoteHit {
  id: string
  title: string
  content_preview: string
  visibility?: 'private' | 'public'
  published_at: string | null
  updated_at: string
  tags: { id: string; name: string }[]
}

export interface SearchTagHit {
  id: string
  name: string
  note_count: number
}

export interface PrivateSearchResult {
  notes: ListResult<SearchNoteHit>
  tags: ListResult<SearchTagHit>
}

/** 搜索范围：只搜标题（命令面板用）或标题 + 正文（搜索页用）。 */
export type SearchType = 'title' | 'title_content'

export function searchPrivate(
  q: string,
  limit = 20,
  offset = 0,
  type?: SearchType,
): Promise<PrivateSearchResult> {
  return request<PrivateSearchResult>('/api/search', {
    query: { q, limit, offset, ...(type ? { type } : {}) },
  })
}

export function searchPublic(
  q: string,
  limit = 20,
  offset = 0,
): Promise<ListResult<SearchNoteHit>> {
  return request<ListResult<SearchNoteHit>>('/api/public/search', { query: { q, limit, offset } })
}
