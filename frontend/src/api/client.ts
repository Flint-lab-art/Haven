/**
 * 统一的 API 客户端。
 *
 * 约定（docs/frontend/frontend.md 第七节）：
 * - 路径一律相对 /api/...，不写死域名；
 * - 错误统一转成 ApiError（含 error / message / fields）；
 * - 这一层不做状态管理。
 */

/** 后端错误响应（docs/api.md 1.4）。 */
export interface ApiErrorBody {
  error: string
  message: string
  fields?: Record<string, string>
}

/** 所有 API 失败的统一异常。 */
export class ApiError extends Error {
  readonly status: number
  /** 机器可读的错误码，如 unauthorized / validation_failed。 */
  readonly code: string
  readonly fields?: Record<string, string>

  constructor(status: number, body: ApiErrorBody) {
    super(body.message || '请求失败')
    this.name = 'ApiError'
    this.status = status
    this.code = body.error
    this.fields = body.fields
  }

  get isUnauthorized(): boolean {
    return this.status === 401
  }

  get isForbidden(): boolean {
    return this.status === 403
  }

  get isNotFound(): boolean {
    return this.status === 404
  }
}

/** 遇到 401 时的全局回调，由 auth store 注册（清空登录态并跳转登录页）。 */
type UnauthorizedHandler = () => void
let onUnauthorized: UnauthorizedHandler | null = null

export function setUnauthorizedHandler(handler: UnauthorizedHandler | null): void {
  onUnauthorized = handler
}

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE'
  body?: unknown
  query?: Record<string, string | number | undefined | null>
  /** 调用方自行处理 401（如登录接口），不触发全局登出。 */
  skipUnauthorizedHandler?: boolean
}

function buildUrl(path: string, query?: RequestOptions['query']): string {
  if (!query) return path
  const params = new URLSearchParams()
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined && value !== null && value !== '') {
      params.set(key, String(value))
    }
  }
  const qs = params.toString()
  return qs ? `${path}?${qs}` : path
}

/**
 * 发请求并解析响应。
 *
 * - 204 返回 undefined；
 * - 非 2xx 抛 ApiError；
 * - 401 默认触发全局登出回调。
 */
export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', body, query, skipUnauthorizedHandler } = options

  const init: RequestInit = {
    method,
    credentials: 'same-origin',
    headers: {},
  }

  if (body !== undefined) {
    init.headers = { 'Content-Type': 'application/json' }
    init.body = JSON.stringify(body)
  }

  let response: Response
  try {
    response = await fetch(buildUrl(path, query), init)
  } catch {
    throw new ApiError(0, { error: 'network_error', message: '网络连接失败，请检查网络后重试' })
  }

  if (response.status === 204) {
    return undefined as T
  }

  const text = await response.text()
  let payload: unknown = null
  if (text) {
    try {
      payload = JSON.parse(text)
    } catch {
      payload = null
    }
  }

  if (!response.ok) {
    const errBody = (payload ?? {}) as Partial<ApiErrorBody>
    const err = new ApiError(response.status, {
      error: errBody.error ?? 'unknown_error',
      message: errBody.message ?? `请求失败（${response.status}）`,
      fields: errBody.fields,
    })
    if (err.isUnauthorized && !skipUnauthorizedHandler) {
      onUnauthorized?.()
    }
    throw err
  }

  return payload as T
}

/** 统一的列表响应（docs/api.md 1.3）。 */
export interface ListResult<T> {
  items: T[]
  total: number
}
