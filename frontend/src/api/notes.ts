/** 笔记接口（docs/api.md 第六、七节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface TagBrief {
  id: string
  name: string
}

export interface Note {
  id: string
  folder_id: string | null
  sort_order: number
  title: string
  content: string
  created_at: string
  updated_at: string
  tags: TagBrief[]
}

export interface NoteSummary {
  id: string
  folder_id: string | null
  sort_order: number
  title: string
  content_preview: string
  created_at: string
  updated_at: string
  tags: TagBrief[]
}

export interface ListNotesQuery {
  limit?: number
  offset?: number
  tag_id?: string
  /** 传空字符串表示收件箱（folder_id IS NULL）；不传表示全部。 */
  folder_id?: string
  include_trash?: boolean
}

export interface CreateNoteInput {
  title: string
  content: string
  tag_ids: string[]
  folder_id?: string | null
}

export interface UpdateNoteInput {
  title?: string
  content?: string
  tag_ids?: string[]
  folder_id?: string | null
  /** 为 true 时把笔记移到根目录（folder_id 被忽略）。 */
  clear_folder?: boolean
  sort_order?: number
}

export function listNotes(query: ListNotesQuery = {}): Promise<ListResult<NoteSummary>> {
  return request('/api/notes', { query: { ...query } })
}

export function getNote(id: string): Promise<Note> {
  return request<Note>(`/api/notes/${id}`)
}

export function createNote(input: CreateNoteInput): Promise<Note> {
  return request<Note>('/api/notes', { method: 'POST', body: input })
}

export function updateNote(id: string, input: UpdateNoteInput): Promise<Note> {
  return request<Note>(`/api/notes/${id}`, { method: 'PATCH', body: input })
}

export function deleteNote(id: string): Promise<void> {
  return request<void>(`/api/notes/${id}`, { method: 'DELETE' })
}

/** 回收站列表项（docs/v2/api.md 2.1）。 */
export interface TrashItem {
  id: string
  title: string
  content_preview: string
  folder_id: string | null
  folder_path: string
  deleted_at: string
}

export function listTrash(limit = 20, offset = 0): Promise<ListResult<TrashItem>> {
  return request('/api/notes/trash', { query: { limit, offset } })
}

export function restoreNote(id: string): Promise<Note> {
  return request<Note>(`/api/notes/${id}/restore`, { method: 'POST' })
}

export function purgeNote(id: string): Promise<void> {
  return request<void>(`/api/notes/${id}/purge`, { method: 'DELETE' })
}

export function emptyTrash(): Promise<void> {
  return request<void>('/api/notes/trash', { method: 'DELETE' })
}

/** 历史版本列表项（docs/v2/api.md 3.1）。 */
export interface VersionSummary {
  id: string
  title: string
  content_preview: string
  created_at: string
  content_size: number
}

/** 单个历史版本的完整快照（docs/v2/api.md 3.2）。 */
export interface VersionDetail {
  id: string
  title: string
  content: string
  folder_id: string | null
  tag_ids: string[]
  created_at: string
  content_size: number
}

export function listVersions(noteId: string, limit = 50, offset = 0): Promise<ListResult<VersionSummary>> {
  return request(`/api/notes/${noteId}/versions`, { query: { limit, offset } })
}

export function getVersion(noteId: string, versionId: string): Promise<VersionDetail> {
  return request<VersionDetail>(`/api/notes/${noteId}/versions/${versionId}`)
}

export function restoreVersion(noteId: string, versionId: string): Promise<Note> {
  return request<Note>(`/api/notes/${noteId}/versions/${versionId}/restore`, { method: 'POST' })
}
