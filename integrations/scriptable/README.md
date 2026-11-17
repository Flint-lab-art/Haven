# Scriptable 记账小组件

在 iPhone 主屏显示当月（或最近 7 天）的收支概况。

## 效果

**中号**（推荐）

```
2026-11 收支                 128 笔
支出                    收入
¥13,781                ¥34,945
                       结余 ¥21,164
─────────────────────────────────
● 餐饮              ¥4,568
  ████████████░░░░░░░░░
● 购物              ¥3,240
  ████████░░░░░░░░░░░░░
● 交通              ¥1,286
  ███░░░░░░░░░░░░░░░░░░
─────────────────────────────────
午饭 · 和同事             -¥32
```

**小号**

```
11 月支出
¥13,781
收 ¥34,945 · 128 笔

● 餐饮 ¥4,568
结余 ¥21,164
```

## 安装

1. App Store 装 [Scriptable](https://apps.apple.com/app/scriptable/id1405459188)
2. 打开 Scriptable → 右上角 `+` → 把 `ledger-widget.js` 全文粘进去
3. 改文件顶部的 `BASE` 与 `TOKEN`
4. 长按主屏空白 → 左上角 `+` → 搜索 Scriptable → 选尺寸
5. 长按刚添加的小组件 → 编辑小组件 → Script 选这个脚本

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
   Keychain.set('haven_token', 'haven_r_你的token')
   ```
2. 把 `ledger-widget.js` 里的
   ```js
   const TOKEN = 'haven_r_...'
   ```
   改成
   ```js
   const TOKEN = Keychain.get('haven_token')
   ```

**权限建议**：小组件只需要读，用 **read** 权限的 Token 就够了。
`read_write` 的 Token 能改写账本，不该放在主屏脚本里。

## 设计演进（改代码前先看）

这里踩过的坑值得记一下：

### 1. 为什么不做图表

最初两版分别画了**双折线**和**上下对称柱状图**，都放弃了：

- **双折线**失败得很明显：单笔工资 3 万、日常支出几十到几百，
  共用一个 Y 轴时支出线被压在底部 0.1pt 内，看起来就是一条横轴。
- 改成双 Y 轴会让两条线交叉处的「高低」失去意义，容易误读。
- 柱状图虽然能用独立归一化规避量级问题，但在 141pt 的高度里
  图表只能占 40pt，挤掉了本可以展示的分类与最近记录。

结论：**空间太小时，图表的信息效率不如文字**。

### 2. Scriptable 的三个限制

| 限制 | 影响 |
| --- | --- |
| `DrawContext` 不支持渐变 | `LinearGradient` 只能用于 WidgetStack，画布里只能纯色 |
| `Color.dynamic` 在 `DrawContext` 里不生效 | 画布内容无法跟随深色模式 |
| `Device.isUsingDarkAppearance()` 在小组件里不可用 | 无法按外观分支 |

因此：文字全部走 `WidgetText`（原生支持 dynamic 色），
只有进度条这类必须画图的元素才用 `DrawContext`，颜色取固定的中亮度色。

### 3. 进度条为什么用图片

`WidgetStack.size` 的宽度设为 **0 表示「自动」**，不能按比例设宽度，
所以无法用两个 stack 拼出「占 37% 的长条」。改用 `DrawContext`
画一张 300×3 的小图，`imageSize` 宽度设为 0 让它跟随容器宽度。

## 数据来源

| 模式 | 接口 | 用到的字段 |
| --- | --- | --- |
| month | `GET /api/ledger/summary` | `total_expense_cents` / `total_income_cents` / `total_count` / `category_ranking` / `recent` |
| week | `GET /api/ledger/trend?days=7` | 同上，`recent` 为空 |

刷新频率：30 分钟一次（`w.refreshAfterDate`），实际由 iOS 决定，
系统会根据使用习惯调整，可能更慢。
