/**
 * 记账工具：金额与月份。
 *
 * 分类清单已入库（`ledger_categories`），不再在前端维护常量。
 */

/** 分 → ¥ 文本，保留两位小数但省略整数后的 .00。 */
export function formatYuan(cents: number): string {
  const sign = cents < 0 ? '-' : ''
  const abs = Math.abs(cents)
  const yuan = Math.floor(abs / 100)
  const fen = abs % 100
  const yuanText = yuan.toLocaleString('zh-CN')
  if (fen === 0) return `${sign}¥${yuanText}`
  return `${sign}¥${yuanText}.${String(fen).padStart(2, '0')}`
}

/** 带正负号：收入 +、支出 −、转账不显示符号。 */
export function formatSignedYuan(type: string, cents: number): string {
  if (type === 'income') return `+${formatYuan(cents)}`
  if (type === 'transfer') return formatYuan(cents)
  return `-${formatYuan(cents)}`
}

/**
 * 解析用户输入为整数分。
 *
 * 支持 `12`、`12.5`、`12.50`、`¥12`、`12元`；非法返回 null。
 * 用字符串拆分而不是浮点乘法，避免 0.1 + 0.2 这类精度误差。
 */
export function parseYuanToCents(input: string): number | null {
  const cleaned = input.trim().replace(/[¥￥元,\s]/g, '')
  if (!/^\d+(\.\d{0,2})?$/.test(cleaned)) return null
  const [yuanPart, fenPart = ''] = cleaned.split('.')
  const yuan = Number(yuanPart)
  const fen = Number(fenPart.padEnd(2, '0'))
  if (!Number.isFinite(yuan) || !Number.isFinite(fen)) return null
  return yuan * 100 + fen
}

/** 当前月份 YYYY-MM。 */
export function currentMonth(now = new Date()): string {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

/** 月份加减。 */
export function shiftMonth(month: string, delta: number): string {
  const [y, m] = month.split('-').map(Number)
  const total = y * 12 + (m - 1) + delta
  const ny = Math.floor(total / 12)
  const nm = (total % 12) + 1
  return `${ny}-${String(nm).padStart(2, '0')}`
}

/** 月份的中文标签：2026-11 → 2026 年 11 月。 */
export function monthLabel(month: string): string {
  const [y, m] = month.split('-')
  return `${y} 年 ${Number(m)} 月`
}

/** ISO 时间 → datetime-local 输入框的值（本地时区）。 */
export function toLocalDateTimeInput(value: string | Date): string {
  const d = typeof value === 'string' ? new Date(value) : value
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

/** datetime-local 的值 → ISO；空值返回 null。 */
export function fromLocalDateTimeInput(value: string): string | null {
  if (!value) return null
  const d = new Date(value)
  return Number.isNaN(d.getTime()) ? null : d.toISOString()
}

/** 账户类型的中文名。 */
export function accountTypeLabel(type: string): string {
  switch (type) {
    case 'cash':
      return '现金'
    case 'bank':
      return '储蓄卡'
    case 'credit':
      return '信用卡'
    case 'ewallet':
      return '电子钱包'
    default:
      return type
  }
}

/** 流水类型的中文名。 */
export function entryTypeLabel(type: string): string {
  switch (type) {
    case 'expense':
      return '支出'
    case 'income':
      return '收入'
    case 'transfer':
      return '转账'
    default:
      return type
  }
}

/**
 * 按分类名散列出一个稳定的色相。
 *
 * 同一个分类永远同色（不随排序变化），不同分类尽量分散。
 * 用简单的字符串哈希而不是查表：加分类时不用同步维护颜色。
 */
function hueOf(name: string): number {
  let hash = 0
  for (let i = 0; i < name.length; i++) {
    hash = (hash * 31 + name.charCodeAt(i)) % 360
  }
  return hash
}

/** 分类的图谱颜色。 */
export function categoryColor(name: string): string {
  return `hsl(${hueOf(name)} 62% 58%)`
}

/** 分类的色调名，用于 CSS 类（`ledger-dot--<tone>`）。 */
export function categoryTone(name: string): string {
  const hue = hueOf(name)
  if (hue < 30 || hue >= 330) return 'red'
  if (hue < 90) return 'orange'
  if (hue < 150) return 'green'
  if (hue < 210) return 'teal'
  if (hue < 270) return 'blue'
  return 'purple'
}
