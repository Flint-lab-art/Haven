/** 首页统计接口（docs/v5/api.md 第一节）。 */
import { request } from './client'

/** 总量统计。 */
export interface StatsTotals {
  notes: number
  words: number
  public_notes: number
}

/** 本周动态。 */
export interface StatsWeek {
  created: number
  updated: number
}

/** 热力图的一天。 */
export interface HeatmapCell {
  date: string
  count: number
}

/** 最近编辑的一项。 */
export interface RecentNote {
  id: string
  title: string
  updated_at: string
  visibility: string
}

/** 一个文件夹及其笔记数。 */
export interface FolderStat {
  id: string
  name: string
  count: number
}

/** 仪表盘 Issue 概览里的一条未完成 Issue。 */
export interface StatsRecentIssue {
  id: string
  title: string
  type: 'bug' | 'feature'
  status: 'todo' | 'in_progress' | 'done'
  priority: 'low' | 'medium' | 'high'
  updated_at: string
  parent_id: string | null
  parent_title: string | null
}

/** 仪表盘的 Issue 汇总（docs-ai/v8/api.md 第二节）。 */
export interface StatsIssues {
  total: number
  todo: number
  in_progress: number
  done: number
  recent: StatsRecentIssue[]
}

/** GET /api/stats 的响应。 */
export interface StatsSnapshot {
  totals: StatsTotals
  week: StatsWeek
  heatmap: HeatmapCell[]
  recent: RecentNote[]
  folders: FolderStat[]
  issues: StatsIssues
}

/** 拉取首页统计数据。 */
export function getStats(): Promise<StatsSnapshot> {
  return request<StatsSnapshot>('/api/stats')
}
