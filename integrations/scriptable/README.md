# Scriptable 记账小组件

在 iPhone 主屏显示当月（或最近 7 天）的收支概况：一行摘要 + 双折线图。

```
2026-11 收支                    128 笔
支出 ¥13,781  收入 ¥34,945  结余 ¥21,164
┌─────────────────────────────────────┐
│        ╱╲                           │  ← 支出
│   ╱╲  ╱  ╲___                       │
│  ╱  ╲╱       ╲______                │  ← 收入
│ 11/01      11/16        11/30       │
└─────────────────────────────────────┘
● 支出  ● 收入
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

## 实现上的两个限制（改代码前先看）

Scriptable 的画布比想象中受限，这两个坑踩过：

1. **`DrawContext` 不支持渐变**
   文档里没有 `createLinearGradient` / `setFillGradient`；
   `LinearGradient` 只能用于 WidgetStack 的 `backgroundGradient`。
   所以图表用的是半透明纯色面积，不是渐变。

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
