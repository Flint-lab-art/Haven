import { describe, expect, it } from 'vitest'
import { GITEE_LABEL, GIT_LABEL, repoLabel } from '@/utils/portfolio'
import type { PortfolioRepo } from '@/api/portfolio'

/** 相关链接的展示文案（docs/v3/frontend/frontend.md 3.3）。 */
function repo(kind: PortfolioRepo['kind'], title = '', url = 'https://example.com/x'): PortfolioRepo {
  return { id: '1', kind, title, url, is_primary: false }
}

describe('repoLabel', () => {
  it('Gitee 显示 Gitee', () => {
    expect(repoLabel(repo('gitee'))).toBe(GITEE_LABEL)
    expect(GITEE_LABEL).toBe('Gitee')
  })

  it('其他 Git 站点显示通用 Git', () => {
    expect(repoLabel(repo('git'))).toBe(GIT_LABEL)
    expect(GIT_LABEL).toBe('Git')
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
    expect(repoLabel(repo('gitee', '随便写的标题'))).toBe('Gitee')
    expect(repoLabel(repo('git', '随便写的标题'))).toBe('Git')
  })
})
