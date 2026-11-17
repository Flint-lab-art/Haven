# Scriptable 记账小组件

在 iPhone 主屏显示当月（或最近 7 天）的收支概况：一行摘要 + 每日柱状图。

```
2026-11 收支                    128 笔
支出 ¥13,781  收入 ¥34,945  结余 ¥21,164
┌─────────────────────────────────────┐
│  ▁▂▁▃▁▂▁▁▁▂▁▁▁▂▁▃▁▁▂▁▁▁▂▁▁▁▂▁▁▁▁       │  ← 支出（向上）
│ ─────────────────────────────────── │
│  ▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁       │  ← 收入（向下）
│ 11/01      11/16        11/30       │
└─────────────────────────────────────┘
● 支出 ↑  ● 收入 ↓
```

## 安装

1. App Store 装 [Scriptable](https://apps.apple.com/app/scriptable/id1405459188)
2. 打开 Scriptable → 右上角 `+` → 把 `ledger-widget.js` 全文粘进去
3. 改文件顶部的 `BASE` 与 `TOKEN`
4. 长按主屏空白 → 左上角 `+` → 搜索 Scriptable → 选尺寸
5. 长按刚添加的小组件 → 编辑小组件 → Script 选这个脚本

**尺寸建议**：中号（Medium）刚好放下摘要与图表；大号会留白较多。

## 在小组件里传入参数

长按小组件 → 编辑小组件 → **Parameter** 填：

| 值 | 效果 |
| --- | --- |
| 留空 / `month` | 当月汇总 |
| `week` | 最近 7 天 |

## 关于 Token

脚本里默认是明文写死的。更稳的做法是存进 Keychain，避免分享脚本时泄露：

1. 在 Scriptable 里新建一个临时脚本，运行一次：
   ```js
   Keychain.set('haven_token', 'haven_rw_你的token')
   ```
2. 把 `ledger-widget.js` 里的
   ```js
   const TOKEN = 'haven_rw_...'
   ```
   改成
   ```js
   const TOKEN = Keychain.get('haven_token')
   ```

**权限建议**：小组件只需要读，用 **read** 权限的 Token 就够了。
`read_write` 的 Token 能改写账本，不该放在主屏脚本里。

## 为什么是柱状图而不是折线图

第一版画的是双折线，结果支出线被压成贴底的一条直线。原因是量级差太大：
单笔工资 3 万，日常支出几十到几百，共用一个 Y 轴时小额数据几乎看不见。

没有改双 Y 轴，因为两条线交叉处的「高低」会失去意义，容易误读。

最终用**上下对称柱状**：支出向上、收入向下，两组各自按自身最大值归一化。
量级差 100 倍也互不影响，形态也和支付宝/微信账单的每日明细一致。

代价：柱子高度只能横向比较（同方向内），不能直接比较「支出柱 vs 收入柱」。

## 实现上的两个限制（改代码前先看）

Scriptable 的画布比想象中受限，这两个坑踩过：

1. **`DrawContext` 不支持渐变**
   文档里没有 `createLinearGradient` / `setFillGradient`；
   `LinearGradient` 只能用于 WidgetStack 的 `backgroundGradient`。
   所以柱子用的是纯色填充，没有渐变。

2. **`Color.dynamic` 在 `DrawContext` 里不生效**
   文档明确写了 dynamic 色不支持画布。而 `Device.isUsingDarkAppearance()`
   在小组件里也不可用，无法按外观分支。
   因此图表颜色用固定的中亮度色（系统红/绿），保证白底黑底都看得清。
   文字部分仍用 `dynamic`，那是 `WidgetText` 的原生能力。

## 数据来源

| 模式 | 接口 |
| --- | --- |
| month | `GET /api/ledger/summary` |
| week | `GET /api/ledger/trend?days=7` |

两者都返回 `daily: [{ date, expenseCents, incomeCents, count }]`，图表直接用这份数据。

刷新频率：30 分钟一次（`w.refreshAfterDate`），实际由 iOS 决定，
系统会根据使用习惯调整，可能更慢。
