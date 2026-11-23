/**
 * 账户可选图标。
 *
 * 全部来自 `public/icons/`：银行与支付应用都放同一目录，文件名即 key。
 * 不混用 `simple-icons`——它是单色矢量，和银行 logo 的彩色表现不一致。
 *
 * 存进数据库的是 key（如 `icbc`、`alipay`），不是路径：
 * 路径随部署变化，key 是稳定的领域标识。
 *
 * 尺寸对齐：所有图标统一渲染到 24×24 的容器里。
 * 银行 logo 通常内容占满画布，支付类图标留白较多，
 * 如果两者都按 viewBox 铺满，视觉重量会差一截——
 * 所以容器尺寸固定、内容按 `object-fit: contain` 等比缩放，
 * 个别偏小的图标在下面的 `scale` 里单独放大。
 */

export interface AccountIconOption {
  /** 存进 `ledger_accounts.icon` 的值，也是文件名（不含 .svg）。 */
  key: string
  /** 界面上显示的名称。 */
  label: string
  /**
   * 视觉补偿系数。
   *
   * 1 表示按容器铺满；小于 1 缩小（给留白多的图标用），
   * 大于 1 放大（给内容本身偏小、四周留白过多的图标用）。
   */
  scale?: number
}

/** 银行：`public/icons/<key>.svg`。 */
export const BANK_ICONS: AccountIconOption[] = [
  { key: 'icbc', label: '工商银行' },
  { key: 'abc', label: '农业银行' },
  { key: 'boc', label: '中国银行' },
  { key: 'cmb', label: '招商银行' },
]

/**
 * 支付应用：同样放 `public/icons/<key>.svg`，用彩色原图。
 *
 * 这三个的图形都撑满画布，而银行 logo 四周有留白，
 * 直接同尺寸并排会显得「支付类大一圈」，所以各自缩一点。
 * 微信的绿色圆块视觉最重，缩得最多；Apple Pay 字多，缩得最少。
 */
export const PAY_ICONS: AccountIconOption[] = [
  { key: 'alipay', label: '支付宝', scale: 0.82 },
  { key: 'wechat', label: '微信', scale: 0.78 },
  { key: 'applepay', label: 'Apple Pay', scale: 0.86 },
]

/** 全部可选图标，选择面板按这个顺序展示。 */
export const ACCOUNT_ICONS: AccountIconOption[] = [...BANK_ICONS, ...PAY_ICONS]

/** key → 图标；未知 key 返回 undefined，调用方回退到默认样式。 */
export const ACCOUNT_ICON_MAP = new Map(ACCOUNT_ICONS.map((i) => [i.key, i]))

/** 取图标；没有匹配时返回 undefined。 */
export function findAccountIcon(key: string | null | undefined): AccountIconOption | undefined {
  if (!key) return undefined
  return ACCOUNT_ICON_MAP.get(key)
}

/** 图标的静态路径。 */
export function iconSrc(key: string): string {
  return `/icons/${key}.svg`
}
