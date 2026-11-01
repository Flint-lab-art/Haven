import { describe, expect, it } from 'vitest'
import { GOGS_LABEL, repoLabel } from '@/utils/portfolio'
import type { PortfolioRepo } from '@/api/portfolio'

/** 相关链接的展示文案（docs/v3/frontend/frontend.md 3.3）。 */
function repo(kind: PortfolioRepo['kind'], title = '', url = 'https://example.com/x'): PortfolioRepo {
  return { id: '1', kind, title, url, is_primary: false }
}

describe('repoLabel', () => {
  it('自建 Git 服务显示 Vorin Git，不再显示 Gogs', () => {
    expect(repoLabel(repo('gogs'))).toBe(GOGS_LABEL)
    expect(GOGS_LABEL).toBe('Vorin Git')
  })

  it('GitHub 显示 GitHub', () => {
    expect(repoLabel(repo('github'))).toBe('GitHub')
  })

  it('普通链接优先显示标题', () => {
    expect(repoLabel(repo('link', 'Go 官方博客'))).toBe('Go 官方博客')
  })

  it('普通链接没有标题时退回地址', () => {
    expect(repoLabel(repo('link', '', 'https://go.dev/blog/'))).toBe('https://go.dev/blog/')
  })

  it('仓库链接忽略 title，始终显示平台名', () => {
    expect(repoLabel(repo('github', '随便写的标题'))).toBe('GitHub')
    expect(repoLabel(repo('gogs', '随便写的标题'))).toBe('Vorin Git')
  })
})
