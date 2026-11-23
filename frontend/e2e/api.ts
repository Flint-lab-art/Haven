import { expect, type APIRequestContext } from '@playwright/test'

/**
 * 测试用的 API 辅助：快速造数据。
 *
 * 原则：**造数据走 API，验证行为走 UI**。
 * 如果每一步都点界面，用例会长到没人愿意读，失败时也分不清是造数据步骤错了还是被测行为错了。
 * 但凡是「用户能看到的结果」，一定用界面断言，不用 API 反查。
 */

/** 统一断言：非 2xx 时把响应体打出来，否则只有一句 status 码，排查要花十倍时间。 */
async function ensureOk(res: Awaited<ReturnType<APIRequestContext['get']>>, what: string): Promise<unknown> {
  if (!res.ok()) {
    throw new Error(`${what} 失败：${res.status()} ${await res.text()}`)
  }
  const text = await res.text()
  return text ? JSON.parse(text) : null
}

export interface Folder {
  id: string
  name: string
  is_inbox: boolean
  parent_id: string | null
  icon: string | null
  children: Folder[]
}

export interface NoteSummary {
  id: string
  title: string
  folder_id: string | null
  content_preview: string
  tags: { id: string; name: string }[]
}

export interface NoteDetail extends NoteSummary {
  content: string
}

export interface Tag {
  id: string
  name: string
}

export interface LedgerAccount {
  id: string
  name: string
  type: 'cash' | 'bank' | 'credit' | 'ewallet'
  initial_balance_cents: number
  balance_cents: number
}

export interface LedgerCategory {
  id: number
  parent_id: number | null
  name: string
  icon: string
  kind: 'expense' | 'income' | 'transfer'
  children: LedgerCategory[]
}

export interface LedgerEntry {
  id: string
  type: 'expense' | 'income' | 'transfer'
  amount_cents: number
  category_id: number | null
  category_name: string | null
  root_category_name: string | null
  account_id: string | null
  account_name: string | null
  to_account_id: string | null
  to_account_name: string | null
  note: string | null
  occurred_at: string
}

export interface Issue {
  id: string
  title: string
  type: string
  status: string
  priority: string
}

export function createApi(request: APIRequestContext) {
  /**
   * 建笔记时显式放进收件箱。
   *
   * 原因：后端允许 folder_id 为 null，但前端笔记树只渲染挂在文件夹下的笔记，
   * folder_id=null 的笔记在界面上看不到。测试要断言「界面上能看到」，就必须走真实路径。
   * 这个不对称已记录为待修项（见 docs/testing.md 的已知问题）。
   */
  async function inboxId(): Promise<string> {
    const body = (await ensureOk(await request.get('/api/folders'), '列出文件夹')) as { items: Folder[] }
    const inbox = body.items.find((f) => f.is_inbox)
    expect(inbox, '缺少收件箱').toBeTruthy()
    return inbox!.id
  }

  return {
    async folders(): Promise<Folder[]> {
      const body = (await ensureOk(await request.get('/api/folders'), '列出文件夹')) as { items: Folder[] }
      return body.items
    },

    /** 收件箱 id：新建笔记不指定文件夹时会落在收件箱。 */
    inboxId,

    async createFolder(name: string, parentId?: string): Promise<Folder> {
      return (await ensureOk(
        await request.post('/api/folders', { data: { name, parent_id: parentId ?? null } }),
        `创建文件夹「${name}」`,
      )) as Folder
    },

    async createNote(input: { title?: string; content?: string; folderId?: string }): Promise<NoteDetail> {
      const folderId = input.folderId ?? (await inboxId())
      return (await ensureOk(
        await request.post('/api/notes', {
          data: {
            title: input.title ?? '未命名',
            content: input.content ?? '',
            folder_id: folderId,
          },
        }),
        '创建笔记',
      )) as NoteDetail
    },

    async updateNote(
      id: string,
      patch: { title?: string; content?: string; folderId?: string; clearFolder?: boolean; tagIds?: string[] },
    ): Promise<NoteDetail> {
      return (await ensureOk(
        await request.patch(`/api/notes/${id}`, {
          data: {
            title: patch.title,
            content: patch.content,
            folder_id: patch.folderId,
            clear_folder: patch.clearFolder,
            tag_ids: patch.tagIds,
          },
        }),
        '更新笔记',
      )) as NoteDetail
    },

    async notes(): Promise<NoteSummary[]> {
      const body = (await ensureOk(await request.get('/api/notes'), '列出笔记')) as { items: NoteSummary[] }
      return body.items
    },

    async trash(): Promise<NoteSummary[]> {
      const body = (await ensureOk(await request.get('/api/notes/trash'), '列出回收站')) as {
        items: NoteSummary[]
      }
      return body.items
    },

    async deleteNote(id: string): Promise<void> {
      await ensureOk(await request.delete(`/api/notes/${id}`), '删除笔记')
    },

    async createTag(name: string): Promise<Tag> {
      return (await ensureOk(await request.post('/api/tags', { data: { name } }), `创建标签「${name}」`)) as Tag
    },

    /** 建一个账户，返回账户（含 id）。 */
    async createAccount(input: {
      name: string
      type?: 'cash' | 'bank' | 'credit' | 'ewallet'
      initialBalanceCents?: number
    }): Promise<LedgerAccount> {
      return (await ensureOk(
        await request.post('/api/ledger/accounts', {
          data: {
            name: input.name,
            type: input.type ?? 'cash',
            initial_balance_cents: input.initialBalanceCents ?? 0,
          },
        }),
        `创建账户「${input.name}」`,
      )) as LedgerAccount
    },

    /** 分类树（一级 + 二级）。 */
    async categories(): Promise<LedgerCategory[]> {
      return (await ensureOk(await request.get('/api/ledger/categories'), '列出分类')) as LedgerCategory[]
    },

    /** 取某个一级分类下第一个二级分类的 id，找不到就返回一级本身。 */
    async categoryIdByName(rootName: string, childName?: string): Promise<number> {
      const roots = (await ensureOk(await request.get('/api/ledger/categories'), '列出分类')) as LedgerCategory[]
      const root = roots.find((c) => c.name === rootName && c.kind === 'expense')
      if (!root) throw new Error(`找不到分类「${rootName}」`)
      if (!childName) return root.id
      return root.children.find((c) => c.name === childName)?.id ?? root.id
    },

    /** 记一笔（支出 / 收入 / 转账）。 */
    async createLedgerEntry(input: {
      type: 'expense' | 'income' | 'transfer'
      amountCents: number
      categoryId?: number | null
      accountId?: string | null
      toAccountId?: string | null
      note?: string | null
      occurredAt?: string
    }): Promise<LedgerEntry> {
      return (await ensureOk(
        await request.post('/api/ledger/entries', {
          data: {
            type: input.type,
            amount_cents: input.amountCents,
            category_id: input.categoryId ?? null,
            account_id: input.accountId ?? null,
            to_account_id: input.toAccountId ?? null,
            note: input.note ?? null,
            occurred_at: input.occurredAt ?? null,
          },
        }),
        '记一笔',
      )) as LedgerEntry
    },

    async ledgerEntries(): Promise<{ items: LedgerEntry[]; total: number }> {
      return (await ensureOk(await request.get('/api/ledger/entries?limit=100'), '列出记账明细')) as {
        items: LedgerEntry[]
        total: number
      }
    },

    async createIssue(input: {
      title: string
      description?: string
      type?: string
      priority?: string
    }): Promise<Issue> {
      return (await ensureOk(
        await request.post('/api/issues', {
          data: {
            title: input.title,
            description: input.description ?? '',
            type: input.type ?? 'bug',
            priority: input.priority ?? 'medium',
          },
        }),
        '创建 Issue',
      )) as Issue
    },

    async issues(): Promise<Issue[]> {
      const body = (await ensureOk(await request.get('/api/issues'), '列出 Issue')) as { items: Issue[] }
      return body.items
    },

    async patchIssue(id: string, patch: { status?: string; title?: string }): Promise<Issue> {
      return (await ensureOk(await request.patch(`/api/issues/${id}`, { data: patch }), '更新 Issue')) as Issue
    },
  }
}
