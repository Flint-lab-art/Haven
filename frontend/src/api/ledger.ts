/** 记账接口（V4 / V5 迁移对应的 ledger 模块）。 */
import { request } from './client'
import type { ListResult } from './client'

export type LedgerType = 'expense' | 'income'

/** 单层分类，与后端 check 约束保持一致：支出 + 收入。 */
export type LedgerCategory =
  | '餐饮'
  | '购物'
  | '交通'
  | '居家'
  | '娱乐'
  | '医疗'
  | '未分类'
  | '工资'
  | '奖金'
  | '报销'
  | '退款'
  | '红包'
  | '其他收入'

export interface LedgerEntry {
  id: string
  type: LedgerType
  /** 金额，单位「分」，整数。 */
  amount_cents: number
  category: LedgerCategory
  note: string
  occurred_at: string
  batch_id: string
  created_at: string
}

/** quick 解析出的单条记录，可直接回传给 batch 接口。 */
export interface ParsedLedgerItem {
  line: number
  raw: string
  type: LedgerType
  amount_cents: number
  category: LedgerCategory
  note: string
  occurred_at: string
}

export interface LedgerParseError {
  line: number
  raw: string
  message: string
}

export interface QuickParseResult {
  items: ParsedLedgerItem[]
  errors: LedgerParseError[]
}

export interface LedgerCategoryRank {
  category: LedgerCategory
  amount_cents: number
  count: number
}

/** 按天聚合的一个点；没有记录的日期由后端补零。 */
export interface LedgerDailyPoint {
  date: string
  expense_cents: number
  income_cents: number
  count: number
}

export interface LedgerSummary {
  month: string
  from: string
  to: string
  total_expense_cents: number
  total_income_cents: number
  total_count: number
  /** 支出分类排行。 */
  category_ranking: LedgerCategoryRank[]
  /** 收入分类排行。 */
  income_category_ranking: LedgerCategoryRank[]
  /** 当月每天的收支走势，已补零。 */
  daily: LedgerDailyPoint[]
  recent: LedgerEntry[]
}

/** 最近 N 天的统计，字段与月度汇总一致，额外带 days。 */
export interface LedgerTrend {
  days: number
  from: string
  to: string
  total_expense_cents: number
  total_income_cents: number
  total_count: number
  category_ranking: LedgerCategoryRank[]
  income_category_ranking: LedgerCategoryRank[]
  daily: LedgerDailyPoint[]
}

export interface CreateLedgerEntryInput {
  type: LedgerType
  amount_cents: number
  category: LedgerCategory
  note?: string
  occurred_at?: string
}

export interface CreateLedgerBatchInput {
  batch_id: string
  raw_text?: string
  items: CreateLedgerEntryInput[]
}

export interface LedgerBatchResult {
  /** 首次写入为 true，重复 batch_id 回放为 false。 */
  created?: boolean
  batch_id: string
  raw_text: string | null
  created_at: string
  items: LedgerEntry[]
  total: number
}

export interface UpdateLedgerEntryInput {
  category?: LedgerCategory
  amount_cents?: number
  occurred_at?: string
}

export interface ListLedgerEntriesQuery {
  from?: string
  to?: string
  category?: LedgerCategory
  type?: LedgerType
  limit?: number
  offset?: number
}

/** 只解析不落库，返回 items + 逐行 errors。 */
export function quickParse(text: string): Promise<QuickParseResult> {
  return request<QuickParseResult>('/api/ledger/quick', {
    method: 'POST',
    body: { text },
  })
}

/** 确认写入，按 batch_id 幂等。 */
export function createLedgerBatch(input: CreateLedgerBatchInput): Promise<LedgerBatchResult> {
  return request<LedgerBatchResult>('/api/ledger/entries/batch', {
    method: 'POST',
    body: input,
  })
}

/** 月度汇总：总额 + 分类排行 + 按天走势 + 最近 3 笔。 */
export function getLedgerSummary(month: string): Promise<LedgerSummary> {
  return request<LedgerSummary>('/api/ledger/summary', { query: { month } })
}

/** 最近 N 天（默认 7）的统计与按天走势，仪表盘用。 */
export function getLedgerTrend(days = 7): Promise<LedgerTrend> {
  return request<LedgerTrend>('/api/ledger/trend', { query: { days } })
}

export function listLedgerEntries(
  query: ListLedgerEntriesQuery = {},
): Promise<ListResult<LedgerEntry>> {
  return request<ListResult<LedgerEntry>>('/api/ledger/entries', {
    query: {
      from: query.from,
      to: query.to,
      category: query.category,
      type: query.type,
      limit: query.limit,
      offset: query.offset,
    },
  })
}

export function updateLedgerEntry(
  id: string,
  input: UpdateLedgerEntryInput,
): Promise<LedgerEntry> {
  return request<LedgerEntry>(`/api/ledger/entries/${id}`, {
    method: 'PATCH',
    body: input,
  })
}

export function deleteLedgerEntry(id: string): Promise<void> {
  return request<void>(`/api/ledger/entries/${id}`, { method: 'DELETE' })
}