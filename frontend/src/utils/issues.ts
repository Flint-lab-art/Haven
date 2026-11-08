/** Issue 展示文案与颜色映射（docs-ai/v8/frontend/ui-design.md 9.4）。 */
import type { Issue, IssuePriority, IssueStatus, IssueType } from '@/api/issues'

/** 列表展示用的一级树节点。 */
export interface IssueTreeItem extends Issue {
  children: Issue[]
}

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

/**
 * 把后端返回的平铺列表组装成一级树（docs-ai/v9/frontend/frontend.md 第一节）。
 *
 * - parent_id 为 null 的是根；
 * - 父不在当前结果里、或父本身也是子项时，当前项按根展示，避免数据不完整时丢失；
 * - 子项保持后端返回的 created_at DESC 顺序。
 */
export function buildIssueTree(issues: Issue[]): IssueTreeItem[] {
  const byId = new Map(issues.map((issue) => [issue.id, issue]))
  const children = new Map<string, Issue[]>()

  for (const issue of issues) {
    const parent = issue.parent_id ? byId.get(issue.parent_id) : undefined
    if (!parent || parent.id === issue.id || parent.parent_id) continue
    const list = children.get(parent.id) ?? []
    list.push(issue)
    children.set(parent.id, list)
  }

  const roots: IssueTreeItem[] = []
  for (const issue of issues) {
    const parent = issue.parent_id ? byId.get(issue.parent_id) : undefined
    const isChild = Boolean(parent && parent.id !== issue.id && !parent.parent_id)
    if (isChild) continue
    roots.push({ ...issue, children: children.get(issue.id) ?? [] })
  }
  return roots
}

/** 可作为父需求的顶层 Feature；编辑时排除自身。 */
export function parentFeatureOptions(issues: Issue[], excludeId?: string): Issue[] {
  return issues.filter(
    (issue) =>
      issue.type === 'feature' &&
      issue.parent_id === null &&
      (!excludeId || issue.id !== excludeId),
  )
}

/** 某个 Issue 是否有子项（仅用于编辑弹窗判断下拉是否禁用）。 */
export function hasIssueChildren(issues: Issue[], id: string): boolean {
  return issues.some((issue) => issue.parent_id === id)
}
