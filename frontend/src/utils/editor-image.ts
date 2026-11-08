import type { Editor } from '@tiptap/core'
import { ApiError } from '@/api/client'
import { isUploadableImage, uploadImage, type UploadResult } from '@/api/uploads'

/**
 * 上传一组图片并按顺序插入编辑器。
 *
 * 规则沿用 v4（docs-ai/v7/frontend/frontend.md 第四节）：
 * 只有 image/* 才拦截，失败提示后不插入半截内容，正文只存相对 URL。
 */
export async function insertImageFiles(
  editor: Editor,
  files: File[],
  pos?: number,
): Promise<void> {
  const images = files.filter(isUploadableImage)
  if (images.length === 0) return

  const results: UploadResult[] = []
  try {
    for (const file of images) {
      results.push(await uploadImage(file, 'note'))
    }
  } catch (err) {
    window.alert(err instanceof ApiError ? err.message : '图片上传失败')
    return
  }

  if (editor.isDestroyed) return

  if (typeof pos === 'number') {
    const nodes = results.map((result) => ({
      type: 'image',
      attrs: { src: result.url, alt: result.name },
    }))
    editor.chain().focus().insertContentAt(pos, nodes).run()
    return
  }

  const chain = editor.chain().focus()
  for (const result of results) {
    chain.setImage({ src: result.url, alt: result.name })
  }
  chain.run()
}

/** 打开系统文件选择器，选中后上传并插入。 */
export function pickImage(editor: Editor): void {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/png,image/jpeg,image/gif,image/webp'
  input.addEventListener('change', () => {
    const file = input.files?.[0]
    if (file) void insertImageFiles(editor, [file])
  })
  input.click()
}
