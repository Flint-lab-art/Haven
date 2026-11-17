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
// 注意 Scriptable 的两个限制：
// 1. Color.dynamic 在 DrawContext 里不生效（文档明确写了不支持）。
//    所以图表颜色只能用固定的中等亮度色，保证白底/黑底下都看得清。
// 2. Device.isUsingDarkAppearance() 在小组件里不可用，无法按外观分支。
// 文字部分继续用 dynamic 色，那是 WidgetText 的原生能力。
// ─────────────────────────────────────────────────────────────
const C = {
  text: Color.dynamic(new Color('#1C1C1E'), new Color('#F2F2F7')),
  sub: Color.dynamic(new Color('#6C6C70'), new Color('#AEAEB2')),
  faint: Color.dynamic(new Color('#8E8E93'), new Color('#8E8E93')),
  green: Color.dynamic(new Color('#1E8E3E'), new Color('#30D158')),
  red: Color.dynamic(new Color('#D70015'), new Color('#FF453A')),
  bg: Color.dynamic(new Color('#FFFFFF'), new Color('#1C1C1E')),
}

// 固定色：白底与黑底都可辨识
const DRAW = {
  expense: new Color('#FF3B30'), // 系统红
  income: new Color('#34C759'), // 系统绿
  grid: new Color('#8E8E93', 0.25),
  label: new Color('#8E8E93'),
}
// 面积填充：同色低透明度
const DRAW_FILL = {
  expense: new Color('#FF3B30', 0.16),
  income: new Color('#34C759', 0.16),
}

const yuan = (cents) =>
  '¥' +
  (cents / 100).toLocaleString('zh-CN', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })

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

/**
 * 画双折线图（支出 / 收入），带半透明面积。
 *
 * 用 DrawContext 手绘：Scriptable 没有内置图表库，
 * 加载第三方脚本在小组件里不稳定。
 *
 * @param {ListWidget} widget 承载图片的容器
 * @param {{date:string, expenseCents:number, incomeCents:number}[]} points
 * @param {number} height 图片高度（pt）
 */
function drawChart(widget, points, height) {
  // 按固定宽度绘制，塞进 widget 时会等比缩放，适配中/大号尺寸
  const width = 320
  const ctx = new DrawContext()
  ctx.size = new Size(width, height)
  ctx.respectScreenScale = true
  // 透明背景：让 widget 自身的背景色透出来，深色模式下不会出现白边
  ctx.opaque = false

  const padTop = 6
  const padBottom = 14 // 日期标签
  const plotH = height - padTop - padBottom

  const values = points.flatMap((p) => [p.expenseCents, p.incomeCents])
  const maxValue = Math.max(1, ...values)

  const stepX = points.length <= 1 ? 0 : width / (points.length - 1)
  const xAt = (i) => (points.length <= 1 ? width / 2 : i * stepX)
  const yAt = (v) => padTop + plotH - (v / maxValue) * plotH

  // 横向基准线：底部 / 中线
  ctx.setStrokeColor(DRAW.grid)
  ctx.setLineWidth(0.5)
  for (const ratio of [0, 0.5]) {
    const y = padTop + plotH - ratio * plotH
    const path = new Path()
    path.move(new Point(0, y))
    path.addLine(new Point(width, y))
    ctx.addPath(path)
    ctx.strokePath()
  }

  // DrawContext 的 fillPath 只作用在「最后添加的那条路径」上，
  // 所以必须分步：先两块面积，再两条线，否则后画的会盖住先画的。
  const buildArea = (key) => {
    const area = new Path()
    area.move(new Point(xAt(0), yAt(points[0][key])))
    for (let i = 1; i < points.length; i++) {
      const prevX = xAt(i - 1)
      const prevY = yAt(points[i - 1][key])
      const curX = xAt(i)
      const curY = yAt(points[i][key])
      area.addQuadCurve(new Point(curX, curY), new Point((prevX + curX) / 2, prevY))
    }
    area.addLine(new Point(width, padTop + plotH))
    area.addLine(new Point(0, padTop + plotH))
    area.closeSubpath()
    return area
  }

  const buildLine = (key) => {
    const line = new Path()
    line.move(new Point(xAt(0), yAt(points[0][key])))
    for (let i = 1; i < points.length; i++) {
      const prevX = xAt(i - 1)
      const prevY = yAt(points[i - 1][key])
      const curX = xAt(i)
      const curY = yAt(points[i][key])
      line.addQuadCurve(new Point(curX, curY), new Point((prevX + curX) / 2, prevY))
    }
    return line
  }

  // 1) 两块面积
  for (const [key, color] of [
    ['expenseCents', DRAW_FILL.expense],
    ['incomeCents', DRAW_FILL.income],
  ]) {
    ctx.addPath(buildArea(key))
    ctx.setFillColor(color)
    ctx.fillPath()
  }

  // 2) 两条线（收入在上层，避免被支出的面积盖住）
  for (const [key, color] of [
    ['expenseCents', DRAW.expense],
    ['incomeCents', DRAW.income],
  ]) {
    ctx.addPath(buildLine(key))
    ctx.setStrokeColor(color)
    ctx.setLineWidth(1.8)
    ctx.strokePath()
  }

  // 3) 日期标签：首、中、尾
  ctx.setFont(Font.systemFont(9))
  ctx.setTextColor(DRAW.label)
  ctx.setTextAlignedCenter()
  const marks = points.length <= 2 ? [0, points.length - 1] : [0, Math.floor((points.length - 1) / 2), points.length - 1]
  for (const i of [...new Set(marks)]) {
    const d = points[i].date
    const text = `${Number(d.slice(5, 7))}/${Number(d.slice(8, 10))}`
    // 两端的内边距，避免标签被裁掉
    const left = Math.max(0, Math.min(width - 34, xAt(i) - 17))
    ctx.drawTextInRect(text, new Rect(left, height - padBottom + 2, 34, 12))
  }

  widget.addImage(ctx.getImage())
}

/** 一行紧凑的收支摘要：支出 ¥x · 收入 ¥y · 结余 ¥z */
function addSummaryLine(widget, data) {
  const row = widget.addStack()
  row.layoutHorizontally()
  row.centerAlignContent()

  const seg = (label, value, color) => {
    const l = row.addText(label + ' ')
    l.font = Font.systemFont(11)
    l.textColor = C.sub
    const v = row.addText(value)
    v.font = Font.semiboldSystemFont(13)
    v.textColor = color
    v.minimumScaleFactor = 0.7
    v.lineLimit = 1
  }

  const balance = data.total_income_cents - data.total_expense_cents
  seg('支出', yuan(data.total_expense_cents), C.text)
  row.addSpacer()
  seg('收入', yuan(data.total_income_cents), C.green)
  row.addSpacer()
  seg('结余', yuan(balance), balance < 0 ? C.red : C.text)
}

/** 左下角的小图例，说明两条线各代表什么。 */
function addLegend(widget) {
  const row = widget.addStack()
  row.layoutHorizontally()
  const item = (color, text) => {
    const t = row.addText('● ')
    t.font = Font.systemFont(9)
    t.textColor = color
    const l = row.addText(text + '  ')
    l.font = Font.systemFont(10)
    l.textColor = C.sub
  }
  // dynamic 色在这里可用（是 WidgetText，不是 DrawContext）
  item(C.red, '支出')
  item(C.green, '收入')
  row.addSpacer()
}

async function buildWidget() {
  const w = new ListWidget()
  w.setPadding(12, 14, 12, 14)
  w.backgroundColor = C.bg

  try {
    const isWeek = MODE === 'week'
    const data = await getJSON(isWeek ? '/api/ledger/trend?days=7' : '/api/ledger/summary')

    // 标题 + 笔数
    const head = w.addStack()
    head.layoutHorizontally()
    const title = head.addText(isWeek ? '最近 7 天' : `${data.month} 收支`)
    title.font = Font.semiboldSystemFont(12)
    title.textColor = C.sub
    head.addSpacer()
    const count = head.addText(`${data.total_count} 笔`)
    count.font = Font.systemFont(10)
    count.textColor = C.faint

    w.addSpacer(4)

    // 数字压成一行，把高度让给图表
    addSummaryLine(w, data)

    w.addSpacer(6)

    const points = data.daily ?? []
    if (points.length > 1) {
      drawChart(w, points, 74)
      addLegend(w)
    } else {
      w.addSpacer()
      const empty = w.addText('这段时间还没有记录')
      empty.font = Font.systemFont(11)
      empty.textColor = C.faint
      w.addSpacer()
    }
  } catch (e) {
    const t = w.addText('记账加载失败')
    t.font = Font.semiboldSystemFont(13)
    t.textColor = C.red

    const d = w.addText(String(e.message ?? e))
    d.font = Font.systemFont(10)
    d.textColor = C.sub
  }

  w.refreshAfterDate = new Date(Date.now() + 30 * 60 * 1000)
  w.url = `${BASE}/ledger`
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
//      Keychain.set('haven_token', 'haven_rw_xxx')
// 2. 然后把上面配置里的 TOKEN 改成：
//      const TOKEN = Keychain.get('haven_token')
//
// 另外这个 Token 是 read_write 权限，能改写账本。
// 小组件只需要读，建议在「设置 → API Token」里换成 read 权限的 Token。
