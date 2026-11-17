/** Issue 接口（docs-ai/v8/api.md 第一节）。 */
import { request } from './client'
import type { ListResult } from './client'

export type IssueType = 'bug' | 'feature'
export type IssueStatus = 'todo' | 'in_progress' | 'done'
export type IssuePriority = 'low' | 'medium' | 'high'

export interface Issue {
  id: string
  title: string
  description: string
  type: IssueType
  status: IssueStatus
  priority: IssuePriority
  created_at: string
  updated_at: string
}

export interface IssueBrief {
  id: string
  title: string
  type: IssueType
  status: IssueStatus
  priority: IssuePriority
  updated_at: string
}

export interface IssueStatusEvent {
  id: string
  from_status: IssueStatus | null
  to_status: IssueStatus
  created_at: string
}

/** 详情页使用的扁平形状：Issue 字段 + 状态流转历史。 */
export interface IssueDetail extends Issue {
  status_events: IssueStatusEvent[]
}

/** 后端 GET /api/issues/{id} 的原始响应。 */
export interface IssueDetailPayload {
  issue: Issue
  status_events: IssueStatusEvent[]
}

export interface ListIssuesQuery {
  status?: IssueStatus
  limit?: number
  offset?: number
}

export interface CreateIssueInput {
  title: string
  description?: string
  type: IssueType
  status?: IssueStatus
  priority?: IssuePriority
}

export interface UpdateIssueInput {
  title?: string
  description?: string
  type?: IssueType
  status?: IssueStatus
  priority?: IssuePriority
}

export function listIssues(query: ListIssuesQuery = {}): Promise<ListResult<Issue>> {
  return request('/api/issues', { query: { ...query } })
}

export function createIssue(input: CreateIssueInput): Promise<Issue> {
  return request('/api/issues', { method: 'POST', body: input })
}

/** 拉取详情，并把后端的 {issue, status_events} 摊平成页面直接可用的结构。 */
export async function getIssue(id: string): Promise<IssueDetail> {
  const payload = await request<IssueDetailPayload>(`/api/issues/${id}`)
  return { ...payload.issue, status_events: payload.status_events }
}

export function updateIssue(id: string, input: UpdateIssueInput): Promise<Issue> {
  return request(`/api/issues/${id}`, { method: 'PATCH', body: input })
}

export function deleteIssue(id: string): Promise<void> {
  return request(`/api/issues/${id}`, { method: 'DELETE' })
}