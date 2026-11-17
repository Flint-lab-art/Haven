/** 作品集接口（docs/api.md 第十节）。 */
import { request } from './client'
import type { ListResult } from './client'

export interface PortfolioRepo {
  id: string
  /** 完整地址，直接保存与展示，不再拼接。 */
  url: string
  /** 非仓库链接在公开页展示的文字；仓库链接留空，按域名显示图标。 */
  title: string
  /** 由后端按域名推断：github / gitee / git / link。 */
  kind: 'github' | 'gitee' | 'git' | 'link'
  is_primary: boolean
}

export interface PortfolioItem {
  id: string
  title: string
  description: string
  /** 作品介绍正文（Markdown），仅详情接口返回，列表接口省略。 */
  content?: string
  sort_order: number
  /** 是否出现在匿名作品集页；未公开即为草稿。 */
  is_public: boolean
  repos: PortfolioRepo[]
}

export interface CreateItemInput {
  title: string
  description: string
  content?: string
  sort_order: number
  is_public?: boolean
}

export interface UpdateItemInput {
  title?: string
  description?: string
  content?: string
  sort_order?: number
  is_public?: boolean
}

export interface CreateRepoInput {
  url: string
  /** 留空时后端会尝试抓取页面标题。 */
  title?: string
  is_primary: boolean
}

export interface UpdateRepoInput {
  url?: string
  title?: string
  is_primary?: boolean
}

/**
 * 公开作品集列表（匿名可访问，只含 is_public=true）。
 * 公开域页面用它；管理页请用 listMyPortfolio。
 */
export function listPublicPortfolio(): Promise<ListResult<PortfolioItem>> {
  return request<ListResult<PortfolioItem>>('/api/public/portfolio')
}

/**
 * 当前用户的全部作品（含未公开草稿），管理页用。
 *
 * 不能用公开接口：它只返回 is_public=true 的作品，
 * 会导致刚创建、还没勾选公开的作品从管理页「凭空消失」。
 */
export function listMyPortfolio(): Promise<ListResult<PortfolioItem>> {
  return request<ListResult<PortfolioItem>>('/api/portfolio')
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
