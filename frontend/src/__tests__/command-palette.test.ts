import { describe, expect, it } from 'vitest'

/**
 * 命令面板的前缀解析（docs/v6/frontend/frontend.md 1.3）。
 *
 * 与 CommandPalette.vue 保持一致：`s` 搜笔记、`n` 新建，前缀后面可以没有空格。
 * 中文输入法容易打出全角 s / 全角空格，这里一并归一化。
 */
const PREFIX = /^([sSnN])[\s\u3000]?(.*)$/

function normalizePrefix(raw: string): string {
  return raw
    .replace(/^ｓ/, 's')
    .replace(/^Ｓ/, 'S')
    .replace(/^ｎ/, 'n')
    .replace(/^Ｎ/, 'N')
}

function parse(raw: string): { mode: 'command' | 'search' | 'new-title'; arg: string } {
  const m = PREFIX.exec(normalizePrefix(raw))
  if (!m) return { mode: 'command', arg: '' }
  const arg = m[2].trim()
  if (arg === '') return { mode: 'command', arg: '' }
  return { mode: m[1].toLowerCase() === 's' ? 'search' : 'new-title', arg }
}

describe('命令面板前缀', () => {
  it('s + 空格 + 关键词', () => {
    expect(parse('s 架构')).toEqual({ mode: 'search', arg: '架构' })
  })

  it('s 直接跟关键词（没有空格）', () => {
    expect(parse('s架构')).toEqual({ mode: 'search', arg: '架构' })
  })

  it('全角 s 也能识别', () => {
    expect(parse('ｓ 架构')).toEqual({ mode: 'search', arg: '架构' })
    expect(parse('Ｓ 架构')).toEqual({ mode: 'search', arg: '架构' })
  })

  it('全角空格也能识别', () => {
    expect(parse('s\u3000架构')).toEqual({ mode: 'search', arg: '架构' })
  })

  it('n 前缀进入新建模式', () => {
    expect(parse('n 今天的日志')).toEqual({ mode: 'new-title', arg: '今天的日志' })
    expect(parse('ｎ 标题')).toEqual({ mode: 'new-title', arg: '标题' })
  })

  it('只有前缀没有内容时按命令处理', () => {
    expect(parse('s').mode).toBe('command')
    expect(parse('s ').mode).toBe('command')
    expect(parse('n').mode).toBe('command')
  })

  it('d / w 等无前缀按命令处理', () => {
    expect(parse('d')).toEqual({ mode: 'command', arg: '' })
    expect(parse('新建')).toEqual({ mode: 'command', arg: '' })
    expect(parse('')).toEqual({ mode: 'command', arg: '' })
  })
})

describe('命令别名匹配', () => {
  const commands = [
    { key: 'new', alias: 'n', label: '新建笔记' },
    { key: 'dashboard', alias: 'd', label: '打开仪表盘' },
    { key: 'workbench', alias: 'w', label: '打开工作台' },
    { key: 'tags', alias: 't', label: '打开标签' },
    { key: 'trash', alias: 'g', label: '打开回收站' },
    { key: 'portfolio', alias: 'p', label: '打开作品集' },
    { key: 'settings', alias: ',', label: '打开设置' },
  ]

  function filter(q: string) {
    const key = q.trim().toLowerCase()
    if (!key) return commands
    return commands.filter((c) => c.alias === key || c.key.startsWith(key) || c.label.toLowerCase().includes(key))
  }

  it('单字母别名都能匹配到对应命令', () => {
    expect(filter('n')[0].key).toBe('new')
    expect(filter('d')[0].key).toBe('dashboard')
    expect(filter('w')[0].key).toBe('workbench')
    expect(filter('t')[0].key).toBe('tags')
    expect(filter('g')[0].key).toBe('trash')
    expect(filter('p')[0].key).toBe('portfolio')
    expect(filter(',')[0].key).toBe('settings')
  })

  it('中文名也能匹配', () => {
    expect(filter('标签').map((c) => c.key)).toEqual(['tags'])
    expect(filter('回收').map((c) => c.key)).toEqual(['trash'])
  })

  it('英文 key 前缀也能匹配', () => {
    expect(filter('port').map((c) => c.key)).toContain('portfolio')
  })

  it('空输入返回全部命令', () => {
    expect(filter('').length).toBe(commands.length)
  })

  it('匹配不到时返回空', () => {
    expect(filter('zzz')).toEqual([])
  })
})
