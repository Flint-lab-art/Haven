/** Issue 展示文案与颜色映射（docs-ai/v8/frontend/ui-design.md 9.4）。 */
import type { IssuePriority, IssueStatus, IssueType } from '@/api/issues'

export const ISSUE_TYPE_LABEL: Record<IssueType, string> = {
  bug: 'Bug',
  feature: 'Feature',
}

export const ISSUE_STATUS_LABEL: Record<IssueStatus, string> = {
  todo: '待办',
  in_progress: '进行中',
  done: '已完成',
}

export const ISSUE_PRIORITY_LABEL: Record<IssuePriority, string> = {
  low: '低',
  medium: '中',
  high: '高',
}

export type PriorityTone = 'low' | 'medium' | 'high'

export function priorityTone(priority: IssuePriority): PriorityTone {
  return priority
}

export function isIssueStatus(value: string): value is IssueStatus {
  return value === 'todo' || value === 'in_progress' || value === 'done'
}