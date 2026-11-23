/**
 * 记账接口（docs/ledger.md 第五节）。
 *
 * 模型三根支柱：账户（钱从哪出）、两级分类（花在哪）、转账（不计收支）。
 */
import { request } from './client'
import type { ListResult } from './client'

/** 账户类型。 */
export type AccountType = 'cash' | 'bank' | 'credit' | 'ewallet'

/** 流水类型；transfer 不计入收支统计。 */
export type EntryType = 'expense' | 'income' | 'transfer'

export interface Account {
  id: string
  name: string
  /** 图标 key（如 `icbc` / `alipay`）；空串表示不显示。 */
  icon: string
  type: AccountType
  /** 期初余额（分）。 */
  initial_balance_cents: number
  /** 实时余额 = 期初 + 流水累计；credit 类为负数表示欠款。 */
  balance_cents: number
  sort_order: number
  archived: boolean
}

export interface Category {
  id: number
  /** 一级为 null。 */
  parent_id: number | null
  name: string
  /** emoji 图标；空串表示没有。 */
  icon: string
  kind: EntryType
  sort_order: number
  children: Category[]
}

export interface LedgerEntry {
  id: string
  type: EntryType
  amount_cents: number
  /** 支出 / 收入的分类；转账为 null。 */
  category_id: number | null
  category_name: string | null
  /** 一级分类名，便于按大类分组。 */
  root_category_name: string | null
  /** 支出 / 收入的账户；转账时为转出账户。 */
  account_id: string | null
  account_name: string | null
  /** 转账的转入账户。 */
  to_account_id: string | null
  to_account_name: string | null
  note: string | null
  occurred_at: string
  created_at: string
  updated_at: string
}

export interface CategorySpend {
  category_id: number
  category_name: string
  spent_cents: number
}

export interface LedgerSummary {
  month: string
  from: string
  to: string
  total_expense_cents: number
  total_income_cents: number
  /** 不含转账。 */
  total_count: number
  transfer_count: number
  expense_by_category: CategorySpend[]
  income_by_category: CategorySpend[]
}

export interface DailyPoint {
  date: string
  expense_cents: number
  income_cents: number
  count: number
}

export interface LedgerTrend {
  days: number
  from: string
  to: string
  total_expense_cents: number
  total_income_cents: number
  total_count: number
  daily: DailyPoint[]
}

export interface BudgetItem {
  category_id: number
  category_name: string
  amount_cents: number
  spent_cents: number
  remaining_cents: number
}

export interface Budget {
  month: string
  total_budget_cents: number
  total_spent_cents: number
  items: BudgetItem[]
}

// ── 账户 ──────────────────────────────────────────

export interface AccountInput {
  name: string
  icon?: string
  type: AccountType
  initial_balance_cents?: number
  sort_order?: number
  archived?: boolean
}

export function listAccounts(): Promise<Account[]> {
  return request<Account[]>('/api/ledger/accounts')
}

export function createAccount(input: AccountInput): Promise<Account> {
  return request<Account>('/api/ledger/accounts', { method: 'POST', body: input })
}

export function updateAccount(id: string, input: AccountInput): Promise<Account> {
  return request<Account>(`/api/ledger/accounts/${id}`, { method: 'PUT', body: input })
}

export function deleteAccount(id: string): Promise<void> {
  return request<void>(`/api/ledger/accounts/${id}`, { method: 'DELETE' })
}

// ── 分类 ──────────────────────────────────────────

export function listCategories(): Promise<Category[]> {
  return request<Category[]>('/api/ledger/categories')
}

// ── 流水 ──────────────────────────────────────────

export interface LedgerEntryInput {
  type: EntryType
  amount_cents: number
  /** 支出 / 收入的分类。 */
  category_id?: number | null
  /** 支出 / 收入的账户；转账时的转出账户。 */
  account_id?: string | null
  /** 转账的转入账户。 */
  to_account_id?: string | null
  note?: string | null
  occurred_at?: string | null
}

export interface ListEntriesQuery {
  type?: EntryType
  category_id?: number
  account_id?: string
  from?: string
  to?: string
  limit?: number
  offset?: number
}

export function listEntries(query: ListEntriesQuery = {}): Promise<ListResult<LedgerEntry>> {
  return request<ListResult<LedgerEntry>>('/api/ledger/entries', {
    query: {
      type: query.type,
      category_id: query.category_id,
      account_id: query.account_id,
      from: query.from,
      to: query.to,
      limit: query.limit,
      offset: query.offset,
    },
  })
}

export function getEntry(id: string): Promise<LedgerEntry> {
  return request<LedgerEntry>(`/api/ledger/entries/${id}`)
}

export function createEntry(input: LedgerEntryInput): Promise<LedgerEntry> {
  return request<LedgerEntry>('/api/ledger/entries', { method: 'POST', body: input })
}

export function updateEntry(id: string, input: Partial<LedgerEntryInput>): Promise<LedgerEntry> {
  return request<LedgerEntry>(`/api/ledger/entries/${id}`, { method: 'PATCH', body: input })
}

export function deleteEntry(id: string): Promise<void> {
  return request<void>(`/api/ledger/entries/${id}`, { method: 'DELETE' })
}

// ── 统计 ──────────────────────────────────────────

export function getSummary(month?: string): Promise<LedgerSummary> {
  return request<LedgerSummary>('/api/ledger/summary', { query: { month } })
}

export function getTrend(days = 7): Promise<LedgerTrend> {
  return request<LedgerTrend>('/api/ledger/trend', { query: { days } })
}

// ── 区间统计 ──────────────────────────────────────

export interface LedgerRangeStats {
  from: string
  to: string
  total_expense_cents: number
  total_income_cents: number
  total_count: number
  transfer_count: number
  expense_by_category: CategorySpend[]
  income_by_category: CategorySpend[]
  /** 区间内按天补零的点；月/季/年视图由前端合并成月。 */
  buckets: DailyPoint[]
}

/**
 * 任意区间统计（周 / 月 / 季 / 年都走这里）。
 *
 * 区间由前端按本地时区算好，后端只认 from/to。
 */
export function getRangeStats(from: string, to: string): Promise<LedgerRangeStats> {
  return request<LedgerRangeStats>('/api/ledger/stats', { query: { from, to } })
}

// ── 预算 ──────────────────────────────────────────

export function getBudget(month?: string): Promise<Budget> {
  return request<Budget>('/api/ledger/budgets', { query: { month } })
}

export function upsertBudget(categoryId: number, month: string, amountCents: number): Promise<Budget> {
  return request<Budget>('/api/ledger/budgets', {
    method: 'PUT',
    body: { category_id: categoryId, month, amount_cents: amountCents },
  })
}

export function deleteBudget(categoryId: number, month: string): Promise<void> {
  return request<void>(`/api/ledger/budgets/${categoryId}`, { method: 'DELETE', query: { month } })
}
