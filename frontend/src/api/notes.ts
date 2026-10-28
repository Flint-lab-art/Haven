/** 笔记接口（docs/api.md 第六、七节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface TagBrief {
  id: string
  name: string
}

export interface Note {
  id: string
  title: string
  content: string
  visibility: 'private' | 'public'
  published_at: string | null
  created_at: string
  updated_at: string
  tags: TagBrief[]
}

export interface NoteSummary {
  id: string
  title: string
  content_preview: string
  visibility: 'private' | 'public'
  published_at: string | null
  created_at: string
  updated_at: string
  tags: TagBrief[]
}

export interface PublicNote {
  id: string
  title: string
  content: string
  published_at: string
  updated_at: string
  tags: TagBrief[]
}

export interface PublicNoteSummary {
  id: string
  title: string
  content_preview: string
  published_at: string
  updated_at: string
  tags: TagBrief[]
}

export interface ListNotesQuery {
  limit?: number
  offset?: number
  visibility?: 'private' | 'public'
  tag_id?: string
}

export interface CreateNoteInput {
  title: string
  content: string
  tag_ids: string[]
}

export interface UpdateNoteInput {
  title?: string
  content?: string
  tag_ids?: string[]
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

export function publishNote(id: string): Promise<Note> {
  return request<Note>(`/api/notes/${id}/publish`, { method: 'POST' })
}

export function unpublishNote(id: string): Promise<Note> {
  return request<Note>(`/api/notes/${id}/unpublish`, { method: 'POST' })
}

export function listPublicNotes(limit = 20, offset = 0): Promise<ListResult<PublicNoteSummary>> {
  return request('/api/public/notes', { query: { limit, offset } })
}

export function getPublicNote(id: string): Promise<PublicNote> {
  return request<PublicNote>(`/api/public/notes/${id}`)
}
