// ===== 配置 =====
// 建议：不要把 API Token 明文写在脚本里，见文件末尾「安全建议」。
const BASE = 'https://note.vorin.icu/'

// 在「设置 → API Token」里创建一个 read 权限的 Token 填到这里。
// 注意：仓库里的这份是占位符，换成你自己的再运行。
const TOKEN = 'haven_r_把这里换成你自己的Token'

// 或改用 Keychain（推荐，见文末）：
//   Keychain.set('haven_token', 'haven_r_xxx')   // 先跑一次
//   const TOKEN = Keychain.get('haven_token')

// 小组件参数填 month 或 week；不填默认 month
const MODE = (args.widgetParameter ?? 'month').trim()

// ─────────────────────────────────────────────────────────────
// 颜色
//
// 文字统一用 dynamic（WidgetText 原生支持明暗两套）。
// 只有需要「色块」的地方才用固定色——DynamicColor 在图片/画布里不可用。
// ─────────────────────────────────────────────────────────────
const C = {
  text: Color.dynamic(new Color('#1C1C1E'), new Color('#F2F2F7')),
  sub: Color.dynamic(new Color('#6C6C70'), new Color('#AEAEB2')),
  faint: Color.dynamic(new Color('#8E8E93'), new Color('#8E8E93')),
  green: Color.dynamic(new Color('#1E8E3E'), new Color('#30D158')),
  red: Color.dynamic(new Color('#D70015'), new Color('#FF453A')),
  bg: Color.dynamic(new Color('#FFFFFF'), new Color('#1C1C1E')),
  track: Color.dynamic(new Color('#E5E5EA'), new Color('#38383A')),
}

// ─────────────────────────────────────────────────────────────
// 工具
// ─────────────────────────────────────────────────────────────
const yuan = (cents) =>
  '¥' +
  (cents / 100).toLocaleString('zh-CN', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })

/** 大额用万，节省横向空间。 */
const yuanShort = (cents) => {
  const v = cents / 100
  if (Math.abs(v) >= 10000) return `¥${(v / 10000).toFixed(1)}万`
  return `¥${Math.round(v).toLocaleString('zh-CN')}`
}

async function getJSON(path) {
  const req = new Request(BASE + path)
  req.headers = { Authorization: `Bearer ${TOKEN}` }
  req.timeoutInterval = 15

  let data
  try {
    data = await req.loadJSON()
  } catch (e) {
    throw new Error('网络或解析失败')
  }
  if (req.response.statusCode !== 200 || !data) {
    throw new Error(`HTTP ${req.response.statusCode}`)
  }
  return data
}

/** 「今天 / 昨天 / 11/14」 */
function dayLabel(iso) {
  const d = new Date(iso)
  const now = new Date()
  const day = (x) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime()
  const diff = Math.round((day(now) - day(d)) / 86400000)
  if (diff === 0) return '今天'
  if (diff === 1) return '昨天'
  return `${d.getMonth() + 1}/${d.getDate()}`
}

// ─────────────────────────────────────────────────────────────
// 组件：一行「标签 + 数值」
// ─────────────────────────────────────────────────────────────
function addStatRow(widget, label, value, color, valueFont = 15) {
  const row = widget.addStack()
  row.layoutHorizontally()
  row.centerAlignContent()

  const l = row.addText(label)
  l.font = Font.systemFont(11)
  l.textColor = C.sub

  row.addSpacer()

  const v = row.addText(value)
  v.font = Font.semiboldSystemFont(valueFont)
  v.textColor = color
  v.lineLimit = 1
  v.minimumScaleFactor = 0.75
}

/**
 * 分类占比条：色点 + 名称 + 金额，下面一条细进度条。
 *
 * 进度条用 DrawContext 画成一张小图片：
 * WidgetStack 的宽度设为 0 表示「自动」，没法按比例设宽度，
 * 所以纯靠 stack 拼不出「占 37% 的长条」。
 * 画布只用纯色填充，不涉及 DrawContext 不支持的渐变。
 */
function makeBarImage(ratio, color, width = 300, height = 3) {
  const ctx = new DrawContext()
  ctx.size = new Size(width, height)
  ctx.respectScreenScale = true
  // 透明背景，让进度条的底轨颜色透出来
  ctx.opaque = false

  const filled = Math.max(2, Math.round(width * Math.min(1, ratio)))
  ctx.setFillColor(color)
  const rect = new Rect(0, 0, filled, height)
  const path = new Path()
  // addRoundedRect 让两端圆角，和 iOS 的进度条观感一致
  path.addRoundedRect(rect, height / 2, height / 2)
  ctx.addPath(path)
  ctx.fillPath()
  return ctx.getImage()
}

function addCategoryBar(widget, item, maxAmount, tone) {
  const box = widget.addStack()
  box.layoutVertically()
  box.spacing = 3

  const line = box.addStack()
  line.layoutHorizontally()
  line.centerAlignContent()

  const dot = line.addText('●')
  dot.font = Font.systemFont(9)
  dot.textColor = tone

  const name = line.addText(' ' + item.category)
  name.font = Font.systemFont(11)
  name.textColor = C.text
  name.lineLimit = 1

  line.addSpacer()

  const amount = line.addText(yuanShort(item.amountCents))
  amount.font = Font.mediumSystemFont(11)
  amount.textColor = C.sub

  // 底轨
  const track = box.addStack()
  track.size = new Size(0, 3)
  track.backgroundColor = C.track
  track.cornerRadius = 1.5

  // 填充：贴在同一行的图片上，宽度自动 = 底轨宽度
  const ratio = item.amountCents / maxAmount
  const bar = box.addImage(makeBarImage(ratio, tone))
  bar.imageSize = new Size(0, 3)
  bar.resizable = false
}

/**
 * 中号布局：总额 + 分类前 N + 最近一笔。
 * 信息密度比原来高，但每块都有明确用途。
 */
function buildMedium(w) {
  return async function (data, isWeek) {
    // ── 标题行 ──
    const head = w.addStack()
    head.layoutHorizontally()
    head.centerAlignContent()

    const title = head.addText(isWeek ? '最近 7 天' : `${data.month} 收支`)
    title.font = Font.semiboldSystemFont(12)
    title.textColor = C.sub

    head.addSpacer()

    const count = head.addText(`${data.total_count} 笔`)
    count.font = Font.systemFont(10)
    count.textColor = C.faint

    w.addSpacer(6)

    // ── 支出 / 收入：两个数字并排，支出为主 ──
    const totals = w.addStack()
    totals.layoutHorizontally()

    const expenseCol = totals.addStack()
    expenseCol.layoutVertically()
    expenseCol.spacing = 0
    const eLabel = expenseCol.addText('支出')
    eLabel.font = Font.systemFont(10)
    eLabel.textColor = C.faint
    const eValue = expenseCol.addText(yuanShort(data.total_expense_cents))
    eValue.font = Font.boldSystemFont(20)
    eValue.textColor = C.text
    eValue.lineLimit = 1
    eValue.minimumScaleFactor = 0.7

    totals.addSpacer()

    const incomeCol = totals.addStack()
    incomeCol.layoutVertically()
    incomeCol.spacing = 0
    const iLabel = incomeCol.addText('收入')
    iLabel.font = Font.systemFont(10)
    iLabel.textColor = C.faint
    const balance = data.total_income_cents - data.total_expense_cents
    const iValue = incomeCol.addText(yuanShort(data.total_income_cents))
    iValue.font = Font.semiboldSystemFont(15)
    iValue.textColor = C.green
    iValue.lineLimit = 1
    iValue.minimumScaleFactor = 0.7

    const bLabel = incomeCol.addText(`结余 ${balance < 0 ? '-' : ''}${yuanShort(Math.abs(balance))}`)
    bLabel.font = Font.systemFont(9)
    bLabel.textColor = balance < 0 ? C.red : C.faint
    bLabel.lineLimit = 1

    // ── 分隔线 ──
    w.addSpacer(6)
    addDivider(w)
    w.addSpacer(5)

    // ── 分类排行（支出）──
    const ranking = (data.category_ranking ?? []).slice(0, 3)
    if (ranking.length) {
      const max = ranking[0].amountCents
      const tones = [C.red, C.sub, C.faint]
      for (let i = 0; i < ranking.length; i++) {
        addCategoryBar(w, ranking[i], max, tones[i])
        if (i < ranking.length - 1) w.addSpacer(4)
      }
    } else {
      const empty = w.addText('这个月还没有支出')
      empty.font = Font.systemFont(11)
      empty.textColor = C.faint
    }

    // ── 最近一笔 ──
    const recent = (data.recent ?? [])[0]
    if (recent) {
      w.addSpacer(6)
      addDivider(w)
      w.addSpacer(4)

      const row = w.addStack()
      row.layoutHorizontally()
      row.centerAlignContent()

      const note = row.addText(recent.note?.trim() || recent.category)
      note.font = Font.systemFont(10)
      note.textColor = C.sub
      note.lineLimit = 1
      note.minimumScaleFactor = 0.8

      row.addSpacer()

      const amt = row.addText(
        `${recent.type === 'income' ? '+' : '-'}${yuanShort(recent.amount_cents)}`,
      )
      amt.font = Font.mediumSystemFont(11)
      amt.textColor = recent.type === 'income' ? C.green : C.text
      amt.lineLimit = 1
    }
  }
}

/**
 * 小号布局：只有两项，必须一眼看完。
 * 支出大字 + 结余小字，不放分类。
 */
function buildSmall(w) {
  return async function (data, isWeek) {
    const title = w.addText(isWeek ? '最近 7 天' : `${Number(data.month.slice(5))} 月支出`)
    title.font = Font.semiboldSystemFont(11)
    title.textColor = C.sub

    w.addSpacer(2)

    const value = w.addText(yuanShort(data.total_expense_cents))
    value.font = Font.boldSystemFont(24)
    value.textColor = C.text
    value.lineLimit = 1
    value.minimumScaleFactor = 0.7

    const balance = data.total_income_cents - data.total_expense_cents
    const sub = w.addText(`收 ${yuanShort(data.total_income_cents)} · ${data.total_count} 笔`)
    sub.font = Font.systemFont(9)
    sub.textColor = C.faint
    sub.lineLimit = 1
    sub.minimumScaleFactor = 0.8

    w.addSpacer()

    // 最大的分类作为唯一附加信息
    const top = (data.category_ranking ?? [])[0]
    if (top) {
      const row = w.addStack()
      row.layoutHorizontally()
      row.centerAlignContent()
      const dot = row.addText('●')
      dot.font = Font.systemFont(8)
      dot.textColor = C.red
      const t = row.addText(` ${top.category} ${yuanShort(top.amount_cents)}`)
      t.font = Font.systemFont(9)
      t.textColor = C.sub
      t.lineLimit = 1
      t.minimumScaleFactor = 0.8
    } else {
      const empty = w.addText('暂无支出')
      empty.font = Font.systemFont(9)
      empty.textColor = C.faint
    }

    // 结余只在有收入时出现，避免小号信息过载
    if (data.total_income_cents > 0) {
      const b = w.addText(`结余 ${balance < 0 ? '-' : ''}${yuanShort(Math.abs(balance))}`)
      b.font = Font.systemFont(9)
      b.textColor = balance < 0 ? C.red : C.faint
      b.lineLimit = 1
    }
  }
}

/** 细分隔线：用一个 1pt 高的 stack 模拟。 */
function addDivider(widget) {
  const line = widget.addStack()
  line.size = new Size(0, 1)
  line.backgroundColor = C.track
}

async function buildWidget() {
  const w = new ListWidget()
  w.setPadding(12, 14, 12, 14)
  w.backgroundColor = C.bg
  // 点进去直接到记账页
  w.url = `${BASE}/ledger`

  try {
    const isWeek = MODE === 'week'
    const data = await getJSON(isWeek ? '/api/ledger/trend?days=7' : '/api/ledger/summary')

    // 按尺寸选择布局：小号放不下分类排行
    const isSmall = config.widgetFamily === 'small'
    await (isSmall ? buildSmall(w) : buildMedium(w))(data, isWeek)
  } catch (e) {
    const t = w.addText('记账加载失败')
    t.font = Font.semiboldSystemFont(13)
    t.textColor = C.red

    const d = w.addText(String(e.message ?? e))
    d.font = Font.systemFont(10)
    d.textColor = C.sub
  }

  // 30 分钟刷新一次；实际由 iOS 调度，可能更慢
  w.refreshAfterDate = new Date(Date.now() + 30 * 60 * 1000)
  return w
}

// ===== 入口 =====
const widget = await buildWidget()

if (config.runsInWidget) {
  Script.setWidget(widget)
} else if (config.runsInShortcut) {
  Script.setShortcutOutput('请在 Scriptable 里预览或添加到主屏幕')
} else {
  await widget.presentMedium()
}

Script.complete()

// ===== 安全建议 =====
// Token 明文写在脚本里，一旦分享脚本就会泄露。更稳的做法：
//
// 1. 首次运行时手动存一次（在 Scriptable 里新建一个临时脚本执行）：
//      Keychain.set('haven_token', 'haven_r_xxx')
// 2. 然后把上面配置里的 TOKEN 改成：
//      const TOKEN = Keychain.get('haven_token')
//
// 另外这个脚本只需要读，建议用 read 权限的 Token。
