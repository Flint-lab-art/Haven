/**
 * 主题定义。
 *
 * 全站颜色都走 style.css 里 :root 的 CSS 变量，切换主题只是换一套变量值：
 * 把 `data-theme` 写到 <html> 上，对应选择器里的变量就会覆盖默认值。
 *
 * 每个主题只列需要覆盖的变量；没列的沿用默认浅色主题的值。
 * 新增主题时：在下面加一项，并在 style.css 里加同名 [data-theme='x'] 块。
 */

export interface ThemeOption {
  /** 对应 <html data-theme="...">，空字符串表示默认浅色。 */
  id: string
  name: string
  /** 预览用的三个色块：背景 / 文字 / 强调色。 */
  swatch: { bg: string; fg: string; accent: string }
  dark: boolean
}

export const THEMES: ThemeOption[] = [
  {
    id: '',
    name: '浅色（默认）',
    swatch: { bg: '#ffffff', fg: '#1a1a1a', accent: '#007aff' },
    dark: false,
  },
  {
    id: 'tokyo-night',
    name: 'Tokyo Night',
    swatch: { bg: '#1a1b26', fg: '#c0caf5', accent: '#7aa2f7' },
    dark: true,
  },
  {
    id: 'gruvbox',
    name: 'Gruvbox',
    swatch: { bg: '#282828', fg: '#ebdbb2', accent: '#fabd2f' },
    dark: true,
  },
  {
    id: 'catppuccin',
    name: 'Catppuccin',
    swatch: { bg: '#1e1e2e', fg: '#cdd6f4', accent: '#cba6f7' },
    dark: true,
  },
  {
    id: 'nord',
    name: 'Nord',
    swatch: { bg: '#2e3440', fg: '#eceff4', accent: '#88c0d0' },
    dark: true,
  },
]

const STORAGE_KEY = 'haven.ui.theme'

/** 主题 id 是否合法，防止 localStorage 里存了已删除的主题名。 */
export function isKnownTheme(id: string): boolean {
  return THEMES.some((theme) => theme.id === id)
}

export function readStoredTheme(): string {
  try {
    const saved = window.localStorage.getItem(STORAGE_KEY) ?? ''
    return isKnownTheme(saved) ? saved : ''
  } catch {
    return ''
  }
}

export function writeStoredTheme(id: string): void {
  try {
    window.localStorage.setItem(STORAGE_KEY, id)
  } catch {
    // 存不进去不影响本次会话
  }
}

/**
 * 把主题应用到 <html>。
 *
 * 同时设置 color-scheme，让滚动条、下拉框、日期选择器等原生控件
 * 也跟着变深或变浅，否则深色主题下这些控件会突兀地发白。
 */
export function applyTheme(id: string): void {
  const root = document.documentElement
  if (id) {
    root.dataset.theme = id
  } else {
    delete root.dataset.theme
  }
  const theme = THEMES.find((item) => item.id === id)
  root.style.colorScheme = theme?.dark ? 'dark' : 'light'
}
