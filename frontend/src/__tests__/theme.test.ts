import { beforeEach, describe, expect, it } from 'vitest'
import { THEMES, isKnownTheme, readStoredTheme, writeStoredTheme } from '@/utils/theme'

describe('主题列表', () => {
  it('默认浅色 id 为空字符串', () => {
    expect(THEMES[0].id).toBe('')
    expect(THEMES[0].dark).toBe(false)
  })

  it('包含浅色 + 四套深色主题', () => {
    expect(THEMES).toHaveLength(5)
    expect(THEMES.filter((theme) => theme.dark)).toHaveLength(4)
  })

  it('id 唯一', () => {
    const ids = THEMES.map((theme) => theme.id)
    expect(new Set(ids).size).toBe(ids.length)
  })

  it('深色主题都带完整色块用于预览', () => {
    for (const theme of THEMES.filter((item) => item.dark)) {
      expect(theme.swatch.bg).toMatch(/^#/)
      expect(theme.swatch.fg).toMatch(/^#/)
      expect(theme.swatch.accent).toMatch(/^#/)
    }
  })
})

describe('isKnownTheme', () => {
  it('已知主题返回 true', () => {
    expect(isKnownTheme('')).toBe(true)
    expect(isKnownTheme('tokyo-night')).toBe(true)
    expect(isKnownTheme('gruvbox')).toBe(true)
    expect(isKnownTheme('catppuccin')).toBe(true)
    expect(isKnownTheme('nord')).toBe(true)
  })

  it('未知主题返回 false', () => {
    expect(isKnownTheme('solarized')).toBe(false)
    expect(isKnownTheme('TOKYO-NIGHT')).toBe(false)
  })
})

describe('主题持久化', () => {
  // jsdom 在无 origin 的文档里不提供 localStorage，这里用内存实现替身
  let store: Record<string, string>

  beforeEach(() => {
    store = {}
    Object.defineProperty(window, 'localStorage', {
      configurable: true,
      value: {
        getItem: (key: string) => (key in store ? store[key] : null),
        setItem: (key: string, value: string) => {
          store[key] = String(value)
        },
        removeItem: (key: string) => {
          delete store[key]
        },
        clear: () => {
          store = {}
        },
      },
    })
  })

  it('未存过时返回默认浅色', () => {
    expect(readStoredTheme()).toBe('')
  })

  it('存过的主题能读回', () => {
    writeStoredTheme('gruvbox')
    expect(readStoredTheme()).toBe('gruvbox')
  })

  it('存了已失效的主题名时回退到默认', () => {
    window.localStorage.setItem('haven.ui.theme', 'removed-theme')
    expect(readStoredTheme()).toBe('')
  })
})
