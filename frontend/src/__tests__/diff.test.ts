import { describe, expect, it } from 'vitest'
import { diffLines, diffStats } from '@/utils/diff'

/** 行级 DIFF（docs/v2/frontend/frontend.md 5.2）：基准是「旧版本 ↔ 当前内容」。 */
describe('diffLines', () => {
  it('完全相同的内容全部标记为 same', () => {
    const lines = diffLines('a\nb\nc', 'a\nb\nc')
    expect(lines.map((l) => l.kind)).toEqual(['same', 'same', 'same'])
  })

  it('新增的行标记为 added', () => {
    const lines = diffLines('a\nc', 'a\nb\nc')
    const added = lines.filter((l) => l.kind === 'added')
    expect(added).toHaveLength(1)
    expect(added[0].text).toBe('b')
  })

  it('删除的行标记为 removed', () => {
    const lines = diffLines('a\nb\nc', 'a\nc')
    const removed = lines.filter((l) => l.kind === 'removed')
    expect(removed).toHaveLength(1)
    expect(removed[0].text).toBe('b')
  })

  it('替换同时产生 removed 与 added', () => {
    const lines = diffLines('旧内容', '新内容')
    expect(lines.map((l) => l.kind).sort()).toEqual(['added', 'removed'])
  })

  it('空文本与有内容比较', () => {
    expect(diffLines('', 'a').map((l) => l.kind)).toEqual(['added'])
    expect(diffLines('a', '').map((l) => l.kind)).toEqual(['removed'])
    expect(diffLines('', '')).toEqual([])
  })

  it('行号正确：same 同时有旧号与新号，added 只有新号，removed 只有旧号', () => {
    const lines = diffLines('a\nb\nc', 'a\nx\nc')
    const same = lines.filter((l) => l.kind === 'same')
    expect(same[0]).toMatchObject({ oldLine: 1, newLine: 1 })

    const removed = lines.find((l) => l.kind === 'removed')!
    expect(removed.oldLine).toBe(2)
    expect(removed.newLine).toBeUndefined()

    const added = lines.find((l) => l.kind === 'added')!
    expect(added.newLine).toBe(2)
    expect(added.oldLine).toBeUndefined()
  })

  it('CRLF 与 LF 视为同一种换行', () => {
    const lines = diffLines('a\r\nb', 'a\nb')
    expect(lines.every((l) => l.kind === 'same')).toBe(true)
  })

  it('末尾换行不额外产生空行', () => {
    expect(diffLines('a\n', 'a')).toHaveLength(1)
    expect(diffLines('a\n', 'a')[0].kind).toBe('same')
  })

  it('保留空行本身作为一行', () => {
    const lines = diffLines('a\n\nb', 'a\n\nb')
    expect(lines).toHaveLength(3)
    expect(lines[1].text).toBe('')
  })

  it('首行插入不破坏后续对齐', () => {
    const lines = diffLines('b\nc', 'a\nb\nc')
    expect(lines[0]).toMatchObject({ kind: 'added', text: 'a' })
    expect(lines.slice(1).every((l) => l.kind === 'same')).toBe(true)
  })
})

describe('diffStats', () => {
  it('统计新增与删除行数', () => {
    const lines = diffLines('a\nb', 'a\nc')
    const stats = diffStats(lines)
    expect(stats.added).toBe(1)
    expect(stats.removed).toBe(1)
  })

  it('无差异时都是 0', () => {
    expect(diffStats(diffLines('same', 'same'))).toEqual({ added: 0, removed: 0 })
  })
})
