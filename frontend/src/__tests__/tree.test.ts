import { describe, expect, it } from 'vitest'
import {
  folderDropPosition,
  folderIndent,
  isFolderDescendant,
  isInteractiveDragTarget,
  noteDropPosition,
  noteIndent,
} from '@/utils/tree'

/**
 * 笔记树的纯函数：缩进、拖拽落点、子树判断。
 *
 * 这些逻辑原先埋在 NoteListPanel（1400+ 行）里，只能靠手点验证；
 * 抽出来后在这里锁定行为，后续拆分组件时不会悄悄改坏。
 */
describe('笔记树工具', () => {
  describe('缩进', () => {
    it('文件夹与笔记都按 16px 步长缩进', () => {
      expect(folderIndent(0)).toBe('8px')
      expect(folderIndent(1)).toBe('24px')
      expect(folderIndent(3)).toBe('56px')
    })

    it('笔记比同级文件夹多让出箭头宽度', () => {
      // 8 + 0*16 + 26 = 34
      expect(noteIndent(0)).toBe('34px')
      expect(noteIndent(2)).toBe('66px')
    })

    it('深度为 0 时不能出现负缩进', () => {
      expect(folderIndent(0).startsWith('-')).toBe(false)
      expect(noteIndent(0).startsWith('-')).toBe(false)
    })
  })

  describe('拖拽落点', () => {
    const rect = { top: 100, height: 40 }

    it('文件夹：上 1/4 之前、下 1/4 之后、中间移入', () => {
      expect(folderDropPosition(105, rect)).toBe('before')
      expect(folderDropPosition(200, rect)).toBe('after')
      expect(folderDropPosition(120, rect)).toBe('inside')
    })

    it('边界值落在「移入」一侧', () => {
      // 恰好 25% 处（110）不算 before
      expect(folderDropPosition(110, rect)).toBe('inside')
      // 恰好 75% 处（130）不算 after
      expect(folderDropPosition(130, rect)).toBe('inside')
    })

    it('笔记只有之前 / 之后，按中线切分', () => {
      expect(noteDropPosition(119, rect)).toBe('before')
      expect(noteDropPosition(120, rect)).toBe('after')
      expect(noteDropPosition(140, rect)).toBe('after')
    })
  })

  describe('子树判断', () => {
    const folders = [
      { id: 'root', parent_id: null },
      { id: 'a', parent_id: 'root' },
      { id: 'b', parent_id: 'a' },
      { id: 'c', parent_id: null },
    ]

    it('直接子节点属于子树', () => {
      expect(isFolderDescendant(folders, 'root', 'a')).toBe(true)
    })

    it('孙节点也属于子树', () => {
      expect(isFolderDescendant(folders, 'root', 'b')).toBe(true)
    })

    it('其他分支不属于子树', () => {
      expect(isFolderDescendant(folders, 'root', 'c')).toBe(false)
    })

    it('自己不是自己的后代（避免拖到自己身上）', () => {
      expect(isFolderDescendant(folders, 'root', 'root')).toBe(false)
    })

    it('找不到的节点不算后代', () => {
      expect(isFolderDescendant(folders, 'root', 'missing')).toBe(false)
    })

    it('数据成环时不死循环', () => {
      const looped = [
        { id: 'x', parent_id: 'y' },
        { id: 'y', parent_id: 'x' },
      ]
      expect(isFolderDescendant(looped, 'target', 'x')).toBe(false)
    })
  })

  describe('可交互元素判断', () => {
    it('按钮、输入框、右键菜单内不算拖拽起点', () => {
      const wrapper = document.createElement('div')
      wrapper.innerHTML = '<button id="b">x</button><input id="i" /><div class="tree-menu" id="m"></div>'
      expect(isInteractiveDragTarget(wrapper.querySelector('#b'))).toBe(true)
      expect(isInteractiveDragTarget(wrapper.querySelector('#i'))).toBe(true)
      expect(isInteractiveDragTarget(wrapper.querySelector('#m'))).toBe(true)
    })

    it('普通元素可以开始拖拽', () => {
      const div = document.createElement('div')
      expect(isInteractiveDragTarget(div)).toBe(false)
    })

    it('null 目标不报错', () => {
      expect(isInteractiveDragTarget(null)).toBe(false)
    })
  })
})
