# Haven 视觉规则

> 这不是设计稿，也不是 token 清单（token 在 `frontend/src/style.css` 的 `:root` 里）。
> 这里只写**判断规则**：什么该有面、什么该动、什么该是几号字。
> 加新样式前先对一遍，比事后统一便宜得多。

## 1. 一条主轴：内容平面，只有临时层浮起

| 层 | 谁在這一层 | 允许什么 | 禁止什么 |
| --- | --- | --- | --- |
| **内容** | 笔记正文、列表、目录树、流水、设置项 | 1px 分割线、间距、`--fill` 分组块 | 阴影、hover 位移、嵌套两层卡片 |
| **导航 chrome** | 侧栏、移动 tabbar、吸顶标题、编辑器工具栏 | 1px 边框、半透明底；**只有 tabbar 允许 blur** | 阴影堆叠、大圆角 |
| **临时层** | 弹窗、命令面板、下拉、菜单、toast、tooltip | `--shadow-pop` / `--shadow-modal`、`--r-xl` | 里面再套带阴影的卡片 |

判断一句：**能点开又关掉的，才配拥有阴影。**

## 2. 字号：九档，封顶 40px

| 角色 | token | 用在哪 |
| --- | --- | --- |
| 页面标题 | `--text-large-title` 32/700 | `.detail-title`、`.article__title` |
| 阅读标题 1 | `--text-title1` 28/400 | 移动吸顶大标题（收缩前） |
| 区块标题 | `--text-title3` 20/600 | `.panel-title`、`.modal__title`、空态标题 |
| 条目标题 | `--text-headline` 16/600 | 卡片标题、设置项标题 |
| 正文 | `--text-body` 16/1.7 | 阅读与编辑正文 |
| 正文紧凑 | `--text-body-tight` 16/1.5 | 单行输入、短句 |
| 次正文 | `--text-subheadline` 14/1.5 | 列表副标题、说明 |
| 元信息 | `--text-footnote` 13/1.5 | 时间、计数、来源 |
| 图注 | `--text-caption` 12/1.4 | 辅助标签、kbd |

规则：
- **大数字**（结余、笔数）用 40/700 + `tabular-nums`，全站只此一档放宽；
- 22px 只给统计块的次要数字；
- 不再新增 19 / 26 / 30 / 34 这类中间档——需要层级时换字重和颜色，不靠字号。
- 中文正文行高不低于 1.6；字距只在 ≥22px 时收紧（-0.3 ~ -1.2px）。

## 3. 颜色

- 只有一个强调色 `--accent`。**它只做交互态与焦点**，不做大面积填充，也不做数据编码。
- 文字三级：`--label`（正文）/ `--label-2`（说明，对白底 5.07:1）/ `--label-3`（**只做装饰**：分隔、禁用、占位）。
  可读文字不许用 `--label-3`（2.16:1）。
- 金额正负用 `--success` / `--danger`，不用强调色。
- 分类色（记账分类图标底色）目前是硬编码，**不随主题变化**，属于已知欠账（见 `docs/ui-motion-review.md`）。
- 深色主题的补丁选择器一律用 `:root[data-theme]`，**不要写 `data-theme='dark'`**——没有这个主题 id，
  写错了规则会静默失效（踩过：`.m-tabbar`、`.m-hero`）。

## 4. 形状与间距

- 圆角四档：`--r-xs` 4（小于 6px 的装饰）/ `--r-md` 8（控件）/ `--r-lg` 10（容器）/ `--r-xl` 12（临时层）。
  胶囊一律 `--r-capsule`，不要写 `999px` 或 `23px`。
- 间距只用 `--sp-*`；例外仅两处：`2px`（图标与文字）、`6px`（紧凑胶囊内部）。
- 图标：统一 lucide，24 网格、`stroke-width` 走默认值；尺寸 13 / 14 / 15 / 16 / 18 / 22 由各自的容器规则给，
  不要在模板里写 `:size` 覆盖（会与 CSS 打架）。品牌标志 `HavenMark` 与图表 SVG 例外。

## 5. 交互反馈三档

| 对象 | 按压 | 说明 |
| --- | --- | --- |
| 按钮 `.btn` | `scale(0.97)` | 陷进去，不改透明度（深色下会闪） |
| 图标按钮 `.icon-btn` | `scale(0.94)` | 圆形按钮用更小的缩放 |
| 整行（列表行、树行、菜单项） | 只变底色 | 行级缩放会像整块在抖 |

- hover 只在有指针的设备生效：新写的 hover 一律包进 `@media (hover: hover) and (pointer: fine)`。
- 焦点统一 `outline: 2px solid var(--accent); outline-offset: 2px`，不改圆角；输入框用同一套外环。
- 禁用态统一 `opacity: 0.38` + `cursor: not-allowed`。

## 6. 动效

- token：`--dur-fast` 120ms（退出、按压）、`--dur-base` 180ms（进入）、`--dur-slow` 300ms（进度条）。
  缓动只用 `--ease-smooth` / `--ease-snappy`。
- **退出永远比进入快**：modal / sheet / 下拉都是进 180、出 120。
- 浮层的进出场一律由 `[data-state='open'|'closed']` 驱动（Reka 的 Presence 负责保留节点到动画结束），
  不要再用「只有 enter 的 keyframes + v-if」。
- 只动 `transform` / `opacity`。例外：手风琴高度、`clip-path`。**不动** `width` / `height` / `padding` / `font-size`。
- 列表增删用 `<TransitionGroup>`，只淡出淡入，不动高度。

**不该加动画的**：命令面板开关、路由切换、图表描边、主题切换、保存状态脉冲、tab 切换。
理由统一是「高频」或「用户正在读内容」。

## 7. 状态文案

- 空态：`还没有 X`（不带句号）+ 一句「怎么做」；列表内的小空态降级为灰字，不放大标题。
- 加载：能预测形状就用骨架屏，否则用一行灰字；**禁止用 `—` 占位**（会被读成 0）。
- 成功：走全局 `toast.success()`，不要各页面自己 `ref + setTimeout`。
- 错误：页内 `notice--error` + 重试按钮；一次性操作失败用 `toast.error()`。

## 8. 组件归属

| 能力 | 由谁负责 |
| --- | --- |
| 焦点陷阱、Esc、焦点归还、背景滚动锁定、Portal 挂载 | **Reka UI**（`Dialog` / `AlertDialog` / `Popover` / `Tooltip` / `Toast`） |
| 外观 | 项目自己的 `.modal` / `.m-sheet` / `.user-menu` 等类 |
| 图标 | `lucide-vue-next` |
| 全局提示条 | `@/composables/useToast` + `components/common/ToastHost.vue` |

换皮时只换 class，不换行为组件；换行为时只换 Reka 的 Root，不动 class。

### 浮层必须有触发锚点

`Popover` / `DropdownMenu` 是「点某个东西、贴着它弹一层」的控件，**锚点本身就是语义的一部分**：

```vue
<PopoverRoot v-model:open="open">
  <PopoverTrigger as-child>
    <button class="user-trigger">…</button>
  </PopoverTrigger>
  <PopoverPortal>
    <PopoverContent class="user-menu">…</PopoverContent>
  </PopoverPortal>
</PopoverRoot>
```

漏掉 `PopoverTrigger` 时，那个 `<button>` 只是一个普通的、没有 `onClick` 的按钮：语法合法、
`vue-tsc` 不报错，运行时**点了毫无反应**，而且 `aria-expanded` 永远是 `false`（踩过：侧栏账户菜单）。

- `PopoverTrigger` 自己会设 `onClick` / `aria-expanded` / `aria-controls` / `data-state`，
  不要在子元素上再手写这几个属性，会覆盖它算出的值；需要别的语义（如 `aria-haspopup="menu"`）可以保留。
- 开合相关的副作用（打开后聚焦输入框、关闭时清空）用 `watch(open, …)`，不要在手写 click 里做。
- `Dialog` / `AlertDialog` 没有这条限制：它们常由父组件的 `v-if` 或 `:open` 驱动，本来就不需要 Trigger。

`scripts/check-component-imports.mjs` 会检查这条规则。
