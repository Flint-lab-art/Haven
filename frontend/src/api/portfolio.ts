/** 作品集接口（docs/api.md 第十节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface PortfolioRepo {
  id: string
  platform: 'gogs' | 'github'
  repo_path: string
  /** 后端拼好的完整地址，前端直接使用。 */
  url: string
  is_primary: boolean
}

export interface PortfolioItem {
  id: string
  title: string
  description: string
  sort_order: number
  repos: PortfolioRepo[]
}

export interface CreateItemInput {
  title: string
  description: string
  sort_order: number
}

export interface UpdateItemInput {
  title?: string
  description?: string
  sort_order?: number
}

export interface CreateRepoInput {
  platform: 'gogs' | 'github'
  repo_path: string
  is_primary: boolean
}

export interface UpdateRepoInput {
  repo_path?: string
  is_primary?: boolean
}

export function listPortfolio(): Promise<ListResult<PortfolioItem>> {
  return request<ListResult<PortfolioItem>>('/api/public/portfolio')
}

export function createItem(input: CreateItemInput): Promise<PortfolioItem> {
  return request<PortfolioItem>('/api/portfolio', { method: 'POST', body: input })
}

export function updateItem(id: string, input: UpdateItemInput): Promise<PortfolioItem> {
  return request<PortfolioItem>(`/api/portfolio/${id}`, { method: 'PATCH', body: input })
}

export function deleteItem(id: string): Promise<void> {
  return request<void>(`/api/portfolio/${id}`, { method: 'DELETE' })
}

export function addRepo(itemId: string, input: CreateRepoInput): Promise<PortfolioRepo> {
  return request<PortfolioRepo>(`/api/portfolio/${itemId}/repos`, { method: 'POST', body: input })
}

export function updateRepo(
  itemId: string,
  repoId: string,
  input: UpdateRepoInput,
): Promise<PortfolioRepo> {
  return request<PortfolioRepo>(`/api/portfolio/${itemId}/repos/${repoId}`, {
    method: 'PATCH',
    body: input,
  })
}

export function deleteRepo(itemId: string, repoId: string): Promise<void> {
  return request<void>(`/api/portfolio/${itemId}/repos/${repoId}`, { method: 'DELETE' })
}
