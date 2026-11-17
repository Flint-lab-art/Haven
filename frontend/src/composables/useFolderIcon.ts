/**
 * 文件夹图标的设置逻辑。
 *
 * 三种来源最终都落到同一条写库路径：`updateFolder(id, { icon })`。
 * 组件只负责渲染 `IconPicker` 并把选中的值/文件交回来。
 */
import { ref, type Ref } from 'vue'
import { updateFolder, type Folder } from '@/api/folders'
import { uploadImage } from '@/api/uploads'

export interface FolderIconOptions {
  busy: Ref<boolean>
  error: Ref<string>
  /** 保存成功后刷新列表并通知其他面板。 */
  onSaved: () => Promise<void> | void
  /** 把异常转成提示文案。 */
  actionError: (err: unknown, fallback: string) => string
}

export interface FolderIconEditing {
  /** 正在设置图标的文件夹 id；null 表示面板关闭。 */
  iconFolderId: Ref<string | null>
  /** 打开（或切换）面板。 */
  open: (folder: Folder) => void
  /** 点击图标本身：再点一次收起。 */
  toggle: (folder: Folder) => void
  close: () => void
  /** 保存一个图标值（emoji / 品牌 key / 图片 URL）；null 表示恢复默认。 */
  save: (folder: Folder, value: string | null) => Promise<void>
  /** 上传本地图片并设为图标。 */
  upload: (folder: Folder, file: File) => Promise<void>
}

export function useFolderIcon(options: FolderIconOptions): FolderIconEditing {
  const iconFolderId = ref<string | null>(null)

  function open(folder: Folder): void {
    iconFolderId.value = folder.id
  }

  function toggle(folder: Folder): void {
    if (iconFolderId.value === folder.id) {
      close()
      return
    }
    open(folder)
  }

  function close(): void {
    iconFolderId.value = null
  }

  /** 提交图标值；与当前值相同则只关面板。 */
  async function save(folder: Folder, value: string | null): Promise<void> {
    if (options.busy.value) return
    const icon = value?.trim() || null
    if (icon === folder.icon) {
      close()
      return
    }

    options.busy.value = true
    options.error.value = ''
    try {
      await updateFolder(folder.id, { icon })
      close()
      await options.onSaved()
    } catch (err) {
      options.error.value = options.actionError(err, '更新图标失败')
    } finally {
      options.busy.value = false
    }
  }

  async function upload(folder: Folder, file: File): Promise<void> {
    if (options.busy.value) return

    options.busy.value = true
    options.error.value = ''
    try {
      const res = await uploadImage(file, 'icon')
      await updateFolder(folder.id, { icon: res.url })
      close()
      await options.onSaved()
    } catch (err) {
      options.error.value = options.actionError(err, '上传图标失败')
    } finally {
      options.busy.value = false
    }
  }

  return { iconFolderId, open, toggle, close, save, upload }
}
