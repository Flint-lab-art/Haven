/**
 * 图片上传（docs/v4/api.md 第三节）。
 *
 * 与其他接口的区别：请求体是 multipart/form-data，不能走 `request()` 的 JSON 封装，
 * 因此单独实现，但错误仍然统一成 ApiError。
 */
import { ApiError, request, type ApiErrorBody, type ListResult } from './client'

/** 一次上传的结果。 */
export interface UploadResult {
  /** 相对 URL，可直接放进 Markdown，如 `/uploads/2026/11/abc.png`。 */
  url: string
  /** 客户端原文件名，仅供回显。 */
  name: string
  size: number
  mime: string
}

/** 前端也做一次同样的限制，避免白传一个必然失败的大文件。 */
export const MAX_UPLOAD_BYTES = 10 << 20 // 10 MiB

const ALLOWED_TYPES = ['image/png', 'image/jpeg', 'image/gif', 'image/webp']

/** 已上传图片的摘要（docs/v4/api.md 4.1）。 */
export interface UploadedFile {
  url: string
  size: number
  created_at: string
}

/** 列出上传目录下的图片，最近上传的在前。 */
export function listUploads(limit = 60): Promise<ListResult<UploadedFile>> {
  return request('/api/uploads', { query: { limit } })
}

/** 判断一个文件是否是可以上传的图片。 */
export function isUploadableImage(file: File): boolean {
  return ALLOWED_TYPES.includes(file.type)
}

/** 上传用途：笔记插图或文件夹图标（docs/v4/api.md 3.1）。 */
export type UploadKind = 'note' | 'icon'

/** 上传单张图片。 */
export async function uploadImage(file: File, kind: UploadKind = 'note'): Promise<UploadResult> {
  if (!isUploadableImage(file)) {
    throw new ApiError(415, {
      error: 'unsupported_media_type',
      message: '只支持 png / jpeg / gif / webp 图片',
    })
  }
  if (file.size > MAX_UPLOAD_BYTES) {
    throw new ApiError(413, {
      error: 'payload_too_large',
      message: '图片超过 10 MiB',
    })
  }

  const form = new FormData()
  form.append('file', file)

  // 不要手动设置 Content-Type：浏览器要自己带上 multipart 的 boundary
  let response: Response
  try {
    response = await fetch(`/api/uploads?kind=${kind}`, {
      method: 'POST',
      credentials: 'same-origin',
      body: form,
    })
  } catch {
    throw new ApiError(0, { error: 'network_error', message: '图片上传失败，请检查网络' })
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
    const body = (payload ?? {}) as Partial<ApiErrorBody>
    throw new ApiError(response.status, {
      error: body.error ?? 'unknown_error',
      message: body.message ?? `图片上传失败（${response.status}）`,
      fields: body.fields,
    })
  }

  return payload as UploadResult
}
