/**
 * 相关链接的展示文案（docs/v3/frontend/frontend.md 3.3）。
 *
 * 后端只给出 `kind`（github / gogs / link），具体显示什么文字由这里决定，
 * 避免同一个字符串散落在多个页面里。
 */
import type { PortfolioRepo } from '@/api/portfolio'

/** 自建 Git 服务的显示名。改品牌只改这里。 */
export const GOGS_LABEL = 'Vorin Git'

/** GitHub 的显示名。 */
export const GITHUB_LABEL = 'GitHub'

/**
 * 链接在公开页显示的文字。
 *
 * - 仓库链接：显示平台名；
 * - 普通链接：显示抓到的标题，没有标题时退回地址。
 */
export function repoLabel(repo: PortfolioRepo): string {
  if (repo.kind === 'link') return repo.title || repo.url
  return repo.kind === 'gogs' ? GOGS_LABEL : GITHUB_LABEL
}
