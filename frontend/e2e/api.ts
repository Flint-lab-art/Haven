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
  visibility: 'private' | 'public'
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

export interface LedgerEntry {
  id: string
  type: string
  amount_cents: number
  category: string
  note: string | null
  occurred_at: string
}

export interface PortfolioItem {
  id: string
  title: string
  description: string
  is_public: boolean
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

    /** 快捷记账并直接写入，返回本批条目。 */
    async quickCommit(text: string): Promise<LedgerEntry[]> {
      const body = (await ensureOk(
        await request.post('/api/ledger/entries/quick', { data: { text } }),
        '快捷记账',
      )) as { batch: { items: LedgerEntry[] }; errors: unknown[] }
      expect(body.errors, '快捷记账不应有解析错误').toEqual([])
      return body.batch.items
    },

    async ledgerEntries(): Promise<{ items: LedgerEntry[]; total: number }> {
      return (await ensureOk(await request.get('/api/ledger/entries?limit=100'), '列出记账明细')) as {
        items: LedgerEntry[]
        total: number
      }
    },

    async createPortfolioItem(input: {
      title: string
      description?: string
      content?: string
      isPublic?: boolean
    }): Promise<PortfolioItem> {
      return (await ensureOk(
        await request.post('/api/portfolio', {
          data: {
            title: input.title,
            description: input.description ?? '',
            content: input.content ?? '',
            is_public: input.isPublic ?? false,
          },
        }),
        '创建作品',
      )) as PortfolioItem
    },

    async addRepo(itemId: string, url: string, title = ''): Promise<void> {
      await ensureOk(await request.post(`/api/portfolio/${itemId}/repos`, { data: { url, title } }), '添加仓库')
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
