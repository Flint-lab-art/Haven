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
  /** 作品介绍正文（Markdown），仅详情接口返回，列表接口省略。 */
  content?: string
  sort_order: number
  repos: PortfolioRepo[]
}

export interface CreateItemInput {
  title: string
  description: string
  content?: string
  sort_order: number
}

export interface UpdateItemInput {
  title?: string
  description?: string
  content?: string
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

/** 私有域的作品详情，含介绍正文（docs/v3/api.md 1.2）。 */
export function getPortfolioItem(id: string): Promise<PortfolioItem> {
  return request<PortfolioItem>(`/api/portfolio/${id}`)
}

/** 公开的作品详情，含介绍正文（docs/v3/api.md 2.2）。 */
export function getPublicPortfolioItem(id: string): Promise<PortfolioItem> {
  return request<PortfolioItem>(`/api/public/portfolio/${id}`)
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
