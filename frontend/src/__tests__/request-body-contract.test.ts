import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/api/client'

/**
 * 请求体契约：前端发出的 JSON 必须保持 snake_case。
 *
 * 后端用的是 Jackson 3（tools.jackson），`SNAKE_CASE` 命名策略在反序列化时
 * 同样生效——DTO 只认 snake_case，camelCase 字段会被静默忽略：
 * 必填字段变成 400「不能为空」，可空字段静默变 null。
 *
 * 这个测试的作用是：任何人往 `client.ts` 里加「snake_case → camelCase」的
 * 键名转换，都会在这里立刻失败，而不是等到用户登录时才发现。
 */

describe('请求体契约', () => {
  let body: unknown

  beforeEach(() => {
    body = undefined
    // 拦截 fetch，只记录实际发出的 body
    vi.stubGlobal(
      'fetch',
      vi.fn(async (_url: string, init: RequestInit) => {
        body = init.body ? JSON.parse(String(init.body)) : undefined
        return new Response('{}', { status: 200, headers: { 'Content-Type': 'application/json' } })
      }),
    )
  })

  it('下划线命名的键原样发出，不做大小写转换', async () => {
    await request('/api/auth/login', {
      method: 'POST',
      body: { username: 'alice', password: 'secret', trust_device: true },
    })

    expect(body).toEqual({ username: 'alice', password: 'secret', trust_device: true })
  })

  it('嵌套对象与数组里的键同样保持 snake_case', async () => {
    await request('/api/ledger/entries/batch', {
      method: 'POST',
      body: {
        batch_id: 'b-1',
        raw_text: '午饭 12',
        items: [{ type: 'expense', amount_cents: 1200, occurred_at: '2026-01-02T00:00:00Z' }],
      },
    })

    expect(body).toEqual({
      batch_id: 'b-1',
      raw_text: '午饭 12',
      items: [{ type: 'expense', amount_cents: 1200, occurred_at: '2026-01-02T00:00:00Z' }],
    })
  })

  it('多词字段用下划线表达（temp_token / clear_folder / sort_order）', async () => {
    await request('/api/auth/login/totp', {
      method: 'POST',
      body: { temp_token: 'abc', code: '123456' },
    })

    await request('/api/notes/1', {
      method: 'PATCH',
      body: { clear_folder: true, tag_ids: [], sort_order: 1 },
    })

    // 最后一次请求的 body
    expect(body).toEqual({ clear_folder: true, tag_ids: [], sort_order: 1 })
  })

  it('没有 body 时不发送请求体', async () => {
    await request('/api/notes')

    expect(body).toBeUndefined()
  })
})
