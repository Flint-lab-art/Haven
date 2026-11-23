# Haven 前端 UI / 交互 / 动效评审

> 评审对象：`frontend/`（Vue 3 + TypeScript + Vite）  
> 基线：`VERSION=2.5.0`，`HEAD=1137b2e`（工作区存在未提交改动）  
> 方式：只读静态审阅 + 全量代码检索；未启动浏览器、未做真机录制、未安装依赖、未修改源码。  
> 口径：文中【事实】为代码可直接验证的内容；【建议】为改进方案；【待确认】需要真机、浏览器或性能面板验证。  
> 行号以当前工作区文件为准。

---

## 1. 执行摘要

1. **这套界面的问题不是“动效太多”，而是“动效没有收尾”。** 全站 73 处 `transition`、7 组 `@keyframes`，却没有任何 `<Transition>` / `<TransitionGroup>`；所有弹窗、抽屉、菜单都只有进入动画，关闭时随 `v-if` 立即消失（`style.css:2473-2516`、`9214-9241`，`IssueFormDialog.vue:127` 等）。

2. **最高风险在移动端滚动大标题。** `MobilePageHeader` 用滚动时间线逐帧修改 `font-size` 与 `padding`（`style.css:11610-11664`），这两者都会触发布局与重绘，和组件注释“跑在合成线程上”（`MobilePageHeader.vue:10-11`）相矛盾。叠加 `sticky` 与 `backdrop-filter: blur(12px)`，中低端手机上滚动手感有明确风险。

3. **键盘与读屏可用性有明显缺口。** 多数弹层没有焦点陷阱、没有 Esc、关闭后不归还焦点；命令面板虽然视觉完整，但缺少 combobox/listbox 语义与 `aria-activedescendant`（`CommandPalette.vue:374-411`）。移动端时间滚轮、底部抽屉同样没有键盘退出路径。

4. **`prefers-reduced-motion` 只是“名义覆盖”。** 全局把 `animation-duration` / `transition-duration` 压到 `0.01ms`（`style.css:1626-1635`），但滚动驱动动画由时间线决定进度，不受 duration 影响；`scrollIntoView({ behavior: 'smooth' })`（`RichTextEditor.vue:164`）也不会被这条规则拦下。

5. **视觉基础不错，但对比度与触控目标不达标。** 动效 token（`style.css:58-63`）统一、缓动曲线选得克制，`scale(0)`、`transition: all`、`ease-in` 等常见坏味道为零；但浅色主题的 `--label-2` 仅 3.26:1、`--label-3` 仅 2.16:1，大量 12–15px 辅助文字低于 WCAG AA；桌面按钮 30–34px、筛选按钮 26px，低于移动端 44px 建议。

**总体判断：** 不需要引入动效库，也不建议给高频操作加动画。优先级应是“修掉布局属性动画 + 补全退出与焦点管理 + 提升对比度”，其次才是少量高价值动效机会。

---

## 2. 项目概览

### 2.1 技术栈

| 项目 | 现状 | 说明 |
| --- | --- | --- |
| 框架 | Vue `3.5.44` | 全部使用 `<script setup lang="ts">` |
| 构建 | Vite `8.3.4` + `vue-tsc` | `pnpm build` 先类型检查再构建 |
| 语言 | TypeScript `~6.0.3` | strict |
| 状态 | Pinia `4.1` | setup store（`stores/ui.ts` 等） |
| 路由 | Vue Router `4.6.4` | PC 私有域 + `/m/` 移动域两套路由树 |
| 编辑器 | TipTap `3.32.2` 全家桶 | 斜杠菜单、气泡菜单、历史版本 |
| UI 库 | **无** | 原生 CSS + 自研组件 |
| 动效库 | **无** | 纯 CSS transition / keyframes；无 GSAP、Motion、VueUse |
| CSS | 单一全局 `style.css` | **11,685 行 / 225,153 字节**；仅 `SiteFooter.vue` 有 scoped style |
| 图标 | 内联 SVG + `simple-icons` | 避免图标库运行时 |
| 图表 | 手写 SVG | `LedgerTrendChart`、`LedgerDonutChart`、`HeatmapChart`、`MobileStatsChart` |

### 2.2 目录与页面

```text
frontend/src/
├── api/            # 唯一 HTTP 入口经 client.ts
├── components/
│   ├── common/     # CommandPalette、ConfirmDialog、HavenMark
│   ├── editor/     # RichTextEditor、EditorToolbar、VersionHistoryDialog、斜杠菜单
│   ├── layout/     # PrivateLayout / PrivateSidebar / SiteFooter
│   ├── ledger/     # LedgerEntryDialog、分类选择、列表
│   ├── mobile/     # MobileLayout、MobilePageHeader、MobileTimePicker、SwipeRow…
│   └── note/       # 目录树、TagDropdown、FolderPicker、IconPicker…
├── composables/    # 快捷键、自动保存、滑动、拖拽、代码复制
├── router/         # index.ts（PC）/ mobile.ts（/m/）
├── stores/         # auth / ledger / theme / ui
├── views/
│   ├── private/    # 19 个 PC 页面（三栏布局）
│   └── mobile/     # 11 个移动页面（/m/，四 tab）
└── style.css       # 设计系统 + 全部页面样式
```

主要交互面：

- **PC 三栏**：左侧导航（可折叠 Mini）、中间目录/列表、右侧详情；命令面板 `Cmd/Ctrl+K`。
- **移动端**：`/m/` 下底部四 tab（统计 / 记账 / 账户 / 我的），悬浮玻璃 tabbar、吸顶大标题、底部抽屉、时间滚轮、左滑删除。
- **弹层**：命令面板、Issue 表单、确认框、标签笔记、文件夹选择器、历史版本、记账表单、移动端 sheet / 时间选择器、用户菜单、标签下拉。

### 2.3 动效资产盘点（事实）

| 指标 | 数量 / 结论 | 位置 |
| --- | --- | --- |
| `transition` 声明 | 73 处 | `style.css` 全局 |
| `transition: all` | 0 | — |
| `@keyframes` | 7 组：骨架脉冲、遮罩进入、弹窗进入、下拉进入、移动 sheet 进入、移动大标题两段 | `style.css:1606`、`2486`、`2504`、`2907`、`9232`、`11631`、`11642` |
| Vue `<Transition>` / `<TransitionGroup>` | **0** | 全仓检索无结果 |
| `v-show` | 0 | 全部条件渲染走 `v-if` |
| `@media (hover: hover)` | **0** | 所有 hover 动效未按指针能力收口 |
| `will-change` | 0 | 未滥用，值得保持 |
| `prefers-reduced-motion` 块 | 4 处 | `style.css:344`、`1626`、`2511`、`2914` |
| 动画库 | 无 | 现有体量不需要引入 |

**结论：** 动效语言是“克制、短、快”，方向正确；缺的是退出阶段、跨组件一致性，以及两处“用布局属性做动画”的性能债。

---

## 3. 问题清单

### 3.1 高严重度

| # | 位置 | 现象（事实） | 影响 | 建议 |
| --- | --- | --- | --- | --- |
| H1 | `frontend/src/style.css:11610-11664`；`frontend/src/components/mobile/MobilePageHeader.vue:9-11` | 滚动驱动动画在 `@supports (animation-timeline: scroll())` 内同时改 `padding-block`（11631-11640）和 `font-size / letter-spacing`（11642-11651）。注释声称“跑在合成线程上”，但 `font-size`、`padding` 会触发 layout + paint，无法仅靠合成完成。 | 滚动每一帧都可能做样式重算、文本重排、布局与重绘；`sticky` 头部自身高度在 64px 滚动区间内缩小约 17px，还可能触发滚动锚定与内容位移。中低端 Android 上最可能掉帧。 | 保持头部高度恒定；标题改用 `transform: scale()` + `transform-origin: left center`，或叠两层标题做纯 `opacity` 交叉淡化；`backdrop-filter` 降级为不透明/低模糊背景。若不愿承担复杂度，直接去掉滚动缩放，保留静态大标题。 |
| H2 | `IssueFormDialog.vue:127`；`LedgerEntryDialog.vue:105`；`MobileTimePicker.vue:108`；`MobileLedger.vue:395`；`MobileAccounts.vue:218`；`MobileStats.vue:262`；`ConfirmDialog.vue:44` | 多数弹层只有 `role="dialog"` / `aria-modal="true"`，但没有焦点陷阱、打开时不移动焦点、关闭后不归还焦点；Issue 表单、记账表单、时间选择器、移动 sheet 没有 Esc 关闭。`ConfirmDialog` 会把焦点放到“取消”，但关闭后焦点落回 `body`。 | 键盘用户 Tab 会跑到遮罩后的页面；读屏用户仍能浏览背景内容；Esc 期望失效；关闭后失去位置感。这是功能级无障碍缺陷，不是“锦上添花”。 | 抽一个共享 `useDialog` / `DialogShell`：打开时记录 `activeElement` 并聚焦首焦点、Tab 循环、Esc 关闭、关闭后 restore、背景 `inert`（或 `aria-hidden`）。优先套到上述 6 类弹层。 |
| H3 | `style.css:66-69`、`80`；大量使用见 `:1002`、`:1141`、`:1379`、`:1570` 等 | 浅色主题 `--label-2: #8e8e93` 对白底 **3.26:1**，`--label-3: #b0b0b6` **2.16:1**；白字配 `--accent: #007aff` **4.02:1**。`--label-2` 被用于 13–15px 的说明、元信息、空状态，`--label-3` 用于占位符与更次要文字。深色主题里 `--label-3` 同样不达标（Tokyo Night 2.76:1、Nord 3.39:1、Catppuccin 3.36:1）。 | WCAG AA 正文要求 4.5:1；当前大量辅助文本对低视力用户不可读，且这是全站性问题。 | 把浅色 `--label-2` 提到约 `#6e6e73`（5.07:1）、`--label-3` 提到可读灰（至少 4.5:1，或只用于装饰）；纯文本链接/强调文字改用更深的 `--accent-text`（如 `#0062cc`，5.8:1），`#007aff` 留给填充按钮。深色主题逐套校验 `--label-3`。 |
| H4 | `style.css:1626-1635`；`RichTextEditor.vue:164` | 全局 reduced-motion 规则把 duration 压到 `0.01ms`，但滚动驱动动画的进度由 `animation-timeline` 决定，duration 被忽略，因此 H1 的标题缩放仍会发生；`scrollIntoView({ behavior: 'smooth' })` 是显式平滑滚动，也不受 CSS `scroll-behavior` 影响。 | 对前庭敏感用户，减少动态的承诺没有兑现；也说明“全局一刀切”掩盖了逐组件遗漏。 | 在 `prefers-reduced-motion: reduce` 下显式 `animation: none` 掉滚动时间线，或用 `@media` 关闭 `@supports` 内的规则；平滑滚动改为读取 `matchMedia('(prefers-reduced-motion: reduce)')` 后选择 `auto`。把“全局 0.01ms”作为兜底，而不是唯一策略。 |

### 3.2 中严重度

| # | 位置 | 现象（事实） | 影响 | 建议 |
| --- | --- | --- | --- | --- |
| M1 | `style.css:601-620`、`3357-3359` | 侧边栏折叠时过渡 `width`（240px ↔ 64px）与 `padding`，两项都是布局属性；`.app` 是三栏 flex，宽度变化会让中间列表与右侧详情每帧重排。 | 折叠 180ms 内整页 reflow，低端设备可能掉帧；宽度变化还会让内部文字换行/截断过程抖动。 | 宽度直接切换（无过渡），只对图标、文字做 `opacity` / `transform` 的 120ms 过渡；或接受“瞬时折叠”。不要用 `scaleX` 压扁侧栏（会扭曲内容）。 |
| M2 | `style.css:2473-2516`、`2892-2918`、`9214-9241`；`IssueFormDialog.vue:127`、`TagNotesDialog.vue:81`、`MobileTimePicker.vue:108` | 进入用 keyframes（`modal-in`、`dropdown-in`、`m-sheet-in`），退出没有任何规则；关闭由 `v-if` 直接移除 DOM。 | 进入 180ms、退出 0ms，节奏不对称；遮罩与面板同时“啪”地消失，比完全不动画更像故障。 | 用 `<Transition>` 包裹（或等价的 leave 类），进入 180ms、退出 100–140ms；遮罩淡出与面板退出同向。退出必须比进入快，符合“系统响应要快”的原则。 |
| M3 | `CommandPalette.vue:374-411`、`287-301` | `role="dialog"` + `aria-modal="true"`，但：输入框与选项列表没有 `role="combobox"` / `listbox` / `aria-activedescendant`；用上下键移动高亮时焦点始终在输入框，读屏不会播报当前项；Tab 可离开对话框；关闭后不归还焦点到打开前元素。 | 键盘可用但读屏不可用；焦点可能落到背景；与“命令面板”这一高频入口的体验不匹配。 | 采用 combobox 模式：输入框 `role="combobox" aria-expanded aria-controls aria-activedescendant`，列表 `role="listbox"`，选项 `role="option" aria-selected`；补焦点陷阱与 restore。打开/关闭仍保持无动画（键盘高频，见 §4）。 |
| M4 | `style.css:1314-1316`、`1373-1391`、`947-968`、`663-679` | 桌面 `.btn` 的按压反馈只有 `opacity: 0.75`；`.icon-btn`、`.side-link`、`.note-row` 没有 `:active`；全站没有 `@media (hover: hover)`。移动端 `.m-tab:hover`（`8712`）、`.m-menu__row:hover`（`9366`）、`.m-issue:hover`（`10759`）会在触摸后留下粘滞 hover。 | 点击“手感”偏软；触屏上点过的行会保持灰色/高亮，像选中态；这是跨端一致性缺口。 | 给可点击元素统一 `transition: transform 160ms var(--ease-snappy)` + `:active { transform: scale(0.97) }`；hover 抬升/变色包进 `@media (hover: hover) and (pointer: fine)`。移动端已有 `.m-cat`、`.m-fab` 的 `scale(0.94–0.96)` 可作范式。 |
| M5 | `style.css:8642-8662`、`11610-11624`；`MobilePageHeader.vue` | 移动端固定 tabbar 使用 `backdrop-filter: saturate(180%) blur(24px)`；吸顶大标题再加 `blur(12px)`。两者都覆盖在持续滚动的内容上。 | 背景模糊需要在滚动时持续采样与合成，GPU 压力大；低端 Android 上可能掉帧或发热。与 H1 叠加时风险更高。 | 先降 blur（8–12px）或改为高不透明度纯色底；用真机 Performance 面板确认。不要同时保留“大面积模糊 + 逐帧布局动画”。 |
| M6 | `SwipeRow.vue:34-56`、`102-111`；`useSwipe.ts:97-115` | `onMove` 每收到一次 `touchmove` 就写 `dragX` ref，触发组件重渲染；位移被硬夹在 `[-76, 0]`，没有阻尼、速度判定或回弹。 | 单行重渲染成本不高，但连续拖动会产生每帧 Vue 更新；到边界是“撞墙”，手感偏硬。监听器清理正确（`detach` + `onBeforeUnmount`），无泄漏。 | 拖动阶段直接写 `contentEl.style.transform`（或 `requestAnimationFrame` 合并），松手再交回响应式状态；边界外做 0.2–0.3 的阻尼。属于手感优化，不是正确性缺陷。 |
| M7 | `LedgerTrendChart.vue:149-160`、`236-250`；`MobileStatsChart.vue:128-131` | 折线图只有 `role="img"` + 一句 `aria-label`；单日明细只能 `pointermove` 悬停查看，键盘无法聚焦到数据点，触屏没有 tap 提示。圆环图相同。 | 读屏用户只能知道“有一张收支图”，拿不到数值；键盘用户无法查看明细；触屏上“悬停”不可用。 | 提供可聚焦的数据点或隐藏的数据表摘要（`sr-only` 表格）；折线图支持左右键切换、`aria-live` 播报；触屏用 tap 选中最近点。 |
| M8 | `LedgerEntryDialog.vue:120-135`；`NoteTreeItem.vue:52-53`；`FolderTreeNode.vue:83-84`；`NoteListPanel.vue:471` | 记账类型用 `role="tablist"` / `role="tab"`，但没有方向键切换、没有 `tabpanel`；目录树每行 `role="treeitem"` 且 `tabindex="0"`，缺少 `aria-level`，几十篇笔记会产生几十个 Tab 停靠点。 | 键盘用户需要逐项 Tab；读屏无法获知层级；tab 语义与实际行为不符。 | 树使用 roving tabindex（容器一个 Tab 停靠点，方向键移动），补 `aria-level`；tablist 补左右键与 `aria-controls`，或降级为普通按钮组（`aria-pressed`）。 |
| M9 | `frontend/src/components/note/SearchPanel.vue:23-45`（`run()`）、`54-61`（`watch`） | 搜索请求没有 `AbortController`，也没有请求序号；快速切换关键词时，旧响应可能后到并覆盖新结果。 | 结果与当前关键词不一致，属于低频但难复现的状态 bug。 | 复用命令面板的 `requestSeq` 模式或 `AbortController`；`onBeforeUnmount` 中止。 |
| M10 | `style.css:8669`；`utils/theme.ts:12-13`、`84-93` | 深色 tabbar 的专用样式写在 `:root[data-theme='dark']` 下，但实际主题 id 是 `tokyo-night` / `gruvbox` / `catppuccin` / `nord`，**没有 `dark`**。该规则永远不会命中。 | 深色主题下 tabbar 的高光/阴影仍是浅色主题的强度，玻璃质感偏亮、发灰。 | 改成 `:root[data-theme='tokyo-night'] .m-tabbar, ...`，或用 `:root[style*="color-scheme: dark"]` / 在 `<html>` 上同时加 `data-dark`。 |

### 3.3 低严重度

| # | 位置 | 现象（事实） | 影响 | 建议 |
| --- | --- | --- | --- | --- |
| L1 | `style.css:1616-1624` | 定义了 `.fade-enter-active` / `.fade-enter-from`，但全站没有 `<Transition>` 使用它们。 | 死代码，误导后续实现者以为已有过渡机制。 | 删除，或真正用 `<Transition name="fade">` 接管（先决定哪些场景需要）。 |
| L2 | `style.css:9520-9552` 与 `10094-10126`；`9845-9918` 与 `10419-10490`；`8697` 与 `8708` | `m-swipe`、`m-nav`、`m-tab--active` 等选择器整块重复；单文件 11,685 行，改一处需要全文件搜索。 | 后置同名规则容易覆盖前一条，维护成本高；样式回归定位困难。 | 按域拆分（tokens / pc / mobile / editor / ledger），去重；用构建后的 CSS 体积与覆盖率为准，不为拆而拆。 |
| L3 | `style.css:8778-8795` | `.m-acc-pill` 有 `transform: scale(0.96)` 的 `:active`，但 `transition` 只列了 `border-color / background-color / color`，按下与回弹都是瞬变。 | 移动端账户类型切换的按压感不完整。 | 把 `transform` 加入 transition；或统一到全局按压 token。 |
| L4 | `style.css:7751-7760` | `.ledger-fab` 使用 `transition: transform 120ms ease, box-shadow 120ms ease`；`box-shadow` 每帧重绘，且用了内置 `ease` 而非项目 token。 | 悬浮按钮 hover 时多一次 paint；与全站缓动语言不一致。 | 用 `filter: drop-shadow()` 或静态阴影 + 仅 transform；缓动改用 `var(--ease-snappy)`。 |
| L5 | `style.css:5879-5887`、`6870-6877`、`8080-8089`、`8470-8478`、`11462-11470` | 多处进度条过渡 `width`。多数宽度在挂载时直接写入，首次渲染不会产生动画；只有数据刷新时才会逐帧改宽度。 | 收益很小，却留下布局属性动画的坏范式。 | 如需动画，改 `transform: scaleX()` + `transform-origin: left`；否则删掉 transition。 |
| L6 | `TrashPanel.vue:69`；`SettingsAccounts.vue:236`；`MobileLedger.vue:459` | 3 个 `<button>` 未写 `type`。 | 若被放进表单，默认 `submit` 会触发意外提交。 | 统一补 `type="button"`（表单提交按钮用 `submit`）。 |
| L7 | `NoteEditView.vue:426`；`style.css:3216-3238` | 保存状态 `span` 用 `v-if` 出现/消失，没有 `aria-live`；状态文案长度变化会让右侧 meta 行轻微位移。 | 读屏不会播报“已保存/保存失败”；高频编辑时工具栏有细微跳动。 | 给状态容器 `aria-live="polite"`；为状态保留固定最小宽度，或把文案放进不参与布局的绝对定位层。 |
| L8 | `RichTextEditor.vue:164` | 标题跳转固定 `behavior: 'smooth'`。 | 忽略 reduced-motion（与 H4 同源）。 | 读取 `matchMedia`，reduce 时用 `auto`。 |
| L9 | `style.css:400-404`、`5552` | 全局 `:focus-visible` 用 `box-shadow` 并强制 `border-radius: var(--r-sm)`，会让圆形按钮在聚焦时短暂变方；`.cmdk__input` 直接 `outline: none` 且没有替代焦点样式。 | 焦点视觉不连续；命令面板输入框缺少可见焦点指示。 | 焦点环不要改 `border-radius`（用 `outline` + `outline-offset` 或只加 box-shadow）；输入框补 `:focus-visible` 样式。 |
| L10 | `style.css:5245-5262` | 仪表盘统计卡 hover 抬升 `translateY(-2px)`。 | 统计数据是“阅读对象”，hover 位移属于装饰；触屏上还会粘滞。 | 去掉位移，只保留边框/底色变化；或按 M4 统一 gating。 |

### 3.4 关键修复对照（Before / After）

| Before | After | Why |
| --- | --- | --- |
| `transition: width var(--dur-base), padding var(--dur-base)`（侧栏，`style.css:616`） | 宽度瞬时切换；`.sidebar__brand-text` 用 `opacity 120ms` 淡出 | `width` / `padding` 触发 layout，三栏布局每帧重排 |
| `@keyframes m-page-head-title-shrink { font-size: 28px → 17px }`（`style.css:11642`） | 固定头部高度；标题 `transform: scale(0.6)` + `transform-origin: left center`，或双标题 opacity 交叉 | `font-size` 无法合成，滚动时逐帧布局 |
| `v-if="open"` + 只有 enter keyframes（`IssueFormDialog.vue:127`） | `<Transition name="modal">`，enter 180ms / leave 120ms，遮罩同步淡出 | 进入有、退出无，节奏不对称 |
| 所有 `:hover` 直接生效（`style.css:566`、`960`、`9366`） | `@media (hover: hover) and (pointer: fine) { ... }` | 触屏 tap 会触发并粘滞 hover |
| `.btn:active { opacity: 0.75 }`（`style.css:1314`） | `transform: scale(0.97)`，`transition: transform 160ms var(--ease-snappy)` | 按压反馈更像“物理按下”，且不影响文字对比度 |
| `@media (prefers-reduced-motion) { * { animation-duration: 0.01ms } }`（`style.css:1626`） | 逐项处理：滚动时间线 `animation: none`；平滑滚动改 `auto`；只保留 opacity/color | 滚动驱动动画不受 duration 影响；reduce 应是“更温和”，不是“全局假关闭” |
| `--label-2: #8e8e93`（`style.css:67`） | `--label-2: #6e6e73`（5.07:1），文本链接用 `#0062cc` | 13–15px 辅助文字需要 4.5:1 |
| `.cmdk__item` 按钮 + 焦点留在输入框（`CommandPalette.vue:401`） | `role="combobox"` + `aria-activedescendant` + `role="option"` | 读屏需要知道“当前选中哪一项” |

---

## 4. 动效机会清单

> 原则：只列“用户会偶尔看到、且有明确目的”的位置；高频导航、键盘操作、正在阅读的数据不加动画。最多 7 条，按“用户影响 ÷ 实现成本”排序。

| # | 位置 | 现状 | 目的 | 频率 | 建议实现 | 成本 | 优先级 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `PrivateSidebar.vue:234-251`、`style.css:740-751` | 用户菜单 `v-if` 瞬间出现/消失，无 origin、无淡入淡出 | 空间一致性：从底部触发器向上展开，关闭时原路收回 | 偶尔（设置/退出） | `<Transition name="pop">`；enter `opacity 0 → 1` + `translateY(4px) scale(0.97) → 0/1`，125ms `var(--ease-snappy)`，`transform-origin: bottom left`；leave 100ms | S | P1 |
| 2 | `TagDropdown.vue:181-205`（已选标签胶囊） | 新增/移除标签时胶囊直接插入/消失，行内元素瞬间位移 | 反馈 + 防止突兀变化 | 偶尔（编辑笔记时加标签） | `<TransitionGroup name="tag">`：enter `opacity 0 + scale(0.97)` 120ms，leave 90ms；只动 `transform/opacity`，不做高度动画 | S | P1 |
| 3 | `style.css:3689-3712`、`3715-3729`（目录树拖放指示） | 拖过不同行时，插入线/整行高亮直接切换，快速移动会闪 | 反馈：让“当前落点”稳定可读 | 中频（整理目录时） | 伪元素常驻但 `opacity: 0`，命中时 `opacity: 1`，`transition: opacity 120ms var(--ease-smooth)`；`tree-row--drop-inside` 的底色同样加 120ms | S | P1 |
| 4 | `MobileLedger.vue:345-350`（记账列表） | 保存成功后新行随列表刷新出现，无定位提示 | 状态指示：让用户确认“记到哪了” | 偶尔（每笔记账） | 记录 `lastAddedId`，仅给该行加 600ms 背景高亮淡出（伪元素 opacity，不改高度）；不移动其他行 | M | P2 |
| 5 | `HomeView.vue:132-138`、`197-224`（仪表盘首屏） | 骨架屏与图表/统计内容硬切换 | 防止突兀变化 | 偶尔（每次进仪表盘） | 内容容器 `@starting-style { opacity: 0 }`，`transition: opacity 150ms var(--ease-smooth)`；不加位移，先修骨架与真实高度差造成的 CLS | S | P2 |
| 6 | `SwipeRow.vue:34-56`、`useSwipe.ts` | 滑到 76px 处硬停；拖动每帧写 ref | 反馈：边界有“阻力”，松手有确定落点 | 偶尔（删除流水） | 越界阻尼 `offset = ACTION_WIDTH + (raw - ACTION_WIDTH) * 0.25`；松手用 180ms `var(--ease-smooth)` 回弹；保持“点删除才真删”的现有安全策略 | M | P3 |

**明确不建议加动画的地方（Rejected）：**

| 位置 | 为什么不加 |
| --- | --- |
| `CommandPalette.vue` 打开/关闭 | 键盘发起、每天 100+ 次。Raycast 式“瞬时”才是正确体验；加 150ms 都会显得迟钝。 |
| PC 路由 / 笔记详情切换 | 每天几十次，且用户正在阅读内容；内容位移会干扰阅读。保持瞬时切换。 |
| `LedgerTrendChart` 折线“画出来” | 数据是用户要读的对象，装饰性描边动画会拖延信息到达；且 SVG `stroke-dashoffset` 在长路径上成本不低。 |
| 主题切换 crossfade | 全页颜色重绘，收益低；主题切换是低频设置操作，瞬时更干净。 |
| 保存状态“已保存”脉冲 | 每次编辑都会出现，频率过高；改用 `aria-live` 播报，而不是视觉动画。 |
| 目录树展开/折叠高度动画 | 高频操作 + `height` 触发布局；chevron 已有 120ms 旋转（`style.css:3744-3753`），足够。 |
| 移动端 tab 切换 | 每天几十次；底部 tab 已有选中底色，内容瞬时切换更跟手。 |

**结论：** 这个产品真正需要的不是“更多动效”，而是“把已有动效收好尾”。单条最高杠杆是 #1 用户菜单（成本最低、最容易被感知为精致）；但整体优先级仍低于 §3 的 H1–H4。

---

## 5. 性能风险

### 5.1 按属性分层

| 层级 | 现有用法 | 风险判断 |
| --- | --- | --- |
| 合成友好（`transform` / `opacity`） | 按压缩放、tooltip、modal 进入、m-sheet 进入、chevron 旋转、swipe 位移 | 方向正确；`m-sheet-in` 从 `translateY(12%)` + `opacity 0.6` 起，克制且不“从无到有” |
| 绘制（`box-shadow` / `background-color` / `border-radius`） | `.ledger-fab` hover 阴影、`.tree-row` 拖放底色、`:focus-visible` 阴影 | 单次成本可接受；不要与大面积模糊叠加 |
| 布局（`width` / `padding` / `font-size`） | 侧栏折叠 `width/padding`；移动大标题 `font-size/padding`；多处进度条 `width` | **主要风险源**：H1、M1、L5 |

### 5.2 主线程与滚动

- **H1 的滚动时间线**：虽然不监听 `scroll` 事件，但 `font-size` / `padding` 的插值仍要在主线程完成样式与布局；`sticky` + 高度变化还可能触发滚动锚定。**需要真机验证**，不能仅凭“用了 CSS 时间线”判断为合成线程。
- **`MobileTimePicker` 的滚轮**：`scroll-snap-type: y mandatory` 是正确的；`scrollIntoView` 仅在三列初始化时调用，不是滚动回调，风险低。
- **图表 hover**：`LedgerTrendChart.vue:140-158` 每次 `pointermove` 写 `hovered`，触发整个 SVG 组件重渲染。节点量不大（数十个），桌面可接受；触屏设备没有 hover，不构成持续压力。若后续数据点增多，改为按点绑定 `pointerenter` 或直接操作 DOM。
- **`SwipeRow`**：每帧写 ref 触发组件更新（M6）。单行节点少，实测可能无感，但这是“用响应式做逐帧动画”的范式风险，列表变复杂后会放大。

### 5.3 模糊与合成层

- `.modal-backdrop`：`backdrop-filter: blur(6px)`（`style.css:2478`），只在桌面弹窗出现，一次性成本。
- `.m-tabbar`：`saturate(180%) blur(24px)`（`8659`），固定悬浮在滚动内容上，**持续采样**。
- `.m-page-head`：`blur(12px)`（`11616`），吸顶且随滚动移动。
- `.site-footer`：`blur(4px)`（`4301`），小面积，可忽略。

建议：移动端先把 tabbar 的 blur 降到 8–12px 或改半透明纯色，再测 H1 修复前后的滚动帧率；不要用 `will-change` 掩盖布局动画的问题。

### 5.4 清理与内存（结论：未发现泄漏）

已核对并确认清理正确：

- `useSwipe.ts:97-115`：`detach` + `onBeforeUnmount`。
- `CommandPalette.vue:366-370`：卸载时移除 `pointerdown` / `keydown`，清 debounce。
- `PrivateSidebar.vue:66-74`：document 监听成对移除。
- `VersionHistoryDialog.vue:168-178`、`TagNotesDialog.vue:63-76`：按 `open` 增删监听并在卸载时兜底。
- `useNoteAutoSave.ts:307-314` + `NoteEditView.vue:358-359`：卸载时 `cancelPending()`。
- `useGlobalShortcuts.ts`：捕获阶段监听，卸载移除。
- `MobileTimePicker` / `FolderPicker`：只使用 `nextTick` + `scrollIntoView`，无长期监听。

**唯一需要留意的“异步后写状态”**：`NoteEditView.vue:178-184` 在 `finally` 里 `requestAnimationFrame` 写保存状态；若期间卸载，回调仍会执行一次（对已卸载组件写 ref，通常无害，但可在回调里加 `if (!mounted) return`）。`SearchPanel` 的旧响应覆盖见 M9。

---

## 6. 可访问性检查

| 项目 | 现状（事实） | 结论 / 建议 |
| --- | --- | --- |
| `prefers-reduced-motion` | 4 个媒体块；全局 0.01ms + 局部 `animation: none`（modal、tag dropdown） | **部分覆盖**：滚动时间线与显式 smooth scroll 漏网（H4）；建议逐项处理，保留 opacity/color 这类有助理解的过渡 |
| 键盘可达 | 大部分原生按钮可用；树、命令面板、移动滚轮有键盘路径 | 基本可用，但存在焦点陷阱缺失（H2）、树 Tab 停靠点过多（M8）、命令面板读屏语义不足（M3） |
| 焦点管理 | 只有 `ConfirmDialog` 主动聚焦“取消”，`FolderPicker` / `CommandPalette` 聚焦输入/容器 | **缺口**：打开不聚焦、关闭不归还、无 trap；建议共享 dialog 原语 |
| Esc 关闭 | `ConfirmDialog` / `CommandPalette` / `FolderPicker` / `VersionHistoryDialog` / `TagNotesDialog` / 用户菜单支持 | **缺口**：`IssueFormDialog`、`LedgerEntryDialog`、`MobileTimePicker`、移动 sheet 不支持 |
| ARIA 角色 | 弹窗普遍有 `role="dialog"` + `aria-modal`；树/列表有部分 role | `VersionHistoryDialog` 缺 `aria-modal`；树缺 `aria-level`；`role="tablist"` 无方向键；图表只有笼统 `aria-label` |
| 动态内容播报 | 仅 `MobileLedger.vue:428` 有 `aria-live="polite"` | 保存状态、搜索结果数、列表刷新、表单错误（部分有 `role="alert"`）缺少播报 |
| 对比度 | `--label-2` 3.26:1、`--label-3` 2.16:1、白/强调 4.02:1；深色 `--label-3` 2.76–4.02:1 | **不达标**（H3）；优先修浅色辅助文字与链接 |
| 触控目标 | `.btn` 34px、`.btn--sm` 28px、`.icon-btn` 30px、`.filter-tab` 26px、`.tag` 22px；移动端 `.m-key` 52px 达标 | 桌面尚可，移动端偏小；至少把移动端可点区域用 padding/伪元素扩到 44px |
| 仅颜色传达状态 | tab 选中同时有底色 + 字色；优先级有圆点 + 文本；基本合格 | 保持；图表分类色建议配文字/图例（已有图例） |
| 跳过导航 / 地标 | `nav`、`main`、`header` 使用合理；无 skip link | 三栏布局 Tab 键路径较长，建议加“跳到内容” skip link（低成本） |

---

## 7. Vue 实现细节

| 检查项 | 结论 | 证据 |
| --- | --- | --- |
| `<Transition>` / `<TransitionGroup>` | **完全未使用** | 全仓检索 0 结果；退出动画缺失的根因 |
| `v-if` / `v-show` | 全部用 `v-if`，无 `v-show` | 弹层关闭即销毁，无法播放 leave；对需要保留状态的面板可考虑 `v-show` + `opacity/visibility` |
| 列表 `key` | 稳定业务 ID 为主；仅 `MobileStatsChart` 的柱状 `v-for` 用 index（时间序列整体替换，可接受） | `NoteListPanel.vue:486`、`MobileLedger.vue:345`、`NoteEditView` 标签等 |
| `v-if` 与 `v-for` 同元素 | 未发现 | 目录树用 `<template v-for>` + 内层 `v-if`，正确 |
| watch 清理 | 监听器基本都成对增删；`CommandPalette` 对 `open` 建了两个 watch（287、351），可合并但无 bug | — |
| 事件监听清理 | 未发现泄漏（见 §5.4） | — |
| 异步竞态 | `CommandPalette` 有 `requestSeq`；`SearchPanel` 没有（M9） | — |
| 逐帧响应式更新 | `SwipeRow` 每 `touchmove` 写 ref（M6）；图表每 `pointermove` 写 ref（可接受） | — |
| 第三方动效/组件库 | 无；TipTap 的气泡/浮动菜单由 Floating UI 定位，出现是瞬时的，符合高频编辑场景 | 不建议为现有缺口引入 GSAP/Motion；退出与焦点管理用原生 Vue + CSS 即可 |
| CSS 作用域 | 99% 样式在全局 `style.css`，仅 `SiteFooter` scoped | 与项目“无组件库、统一设计系统”的取向一致，但已经出现重复与死规则（L1/L2/M10） |

---

## 8. 建议路线图

### 立即修复（P0，1–2 天）

1. **H1**：移动端大标题改为固定高度 + `transform/opacity`，或直接移除滚动缩放；同时把 `m-page-head` 注释改成与实现一致。
2. **H4**：在 `prefers-reduced-motion` 下关闭滚动时间线；`RichTextEditor` 的平滑滚动改为条件 `auto`。
3. **H2**：抽出最小 `DialogShell`（焦点陷阱、Esc、restore、`aria-modal`、背景 inert），先覆盖 Issue 表单、记账表单、时间选择器、移动 sheet、确认框。
4. **H3**：调整 `--label-2` / `--label-3` / 文本链接色，逐主题校验 4.5:1。

### 近期改进（P1，3–5 天）

5. **M2**：给 modal / sheet / 下拉 / 用户菜单补 leave（120ms 左右），进入 180ms，退出更快。
6. **M4**：统一按压反馈与 hover gating；桌面按钮补 `scale(0.97)`，触屏禁用 hover 位移。
7. **M1**：去掉侧栏 `width/padding` 过渡，改为宽度瞬时 + 文字淡出。
8. **M3**：命令面板补 combobox/listbox 语义与 `aria-activedescendant`，加焦点陷阱。
9. **M5**：移动端 tabbar / 大标题的 blur 降级，真机对比滚动帧率。
10. **M7/M8**：图表可键盘读取、树 roving tabindex、tablist 键盘行为。

### 长期优化（P2，按需）

11. 拆分并去重 `style.css`（PC / mobile / editor / ledger / tokens），清理死规则与重复块。
12. 建立动效约定文档：只允许 `transform/opacity`（例外：手风琴高度、`clip-path`），退出时长 ≤ 进入，所有 hover 必须 gating，所有新增动画必须写 reduced-motion 分支。
13. 加两条低成本回归测试：`prefers-reduced-motion` 下滚动头部不缩放；弹层打开/关闭后焦点回到触发元素。视觉回归可用 Playwright 截图对比（项目已有 E2E 基建）。
14. 每次发版前用中端 Android 真机跑一次滚动 + 打开/关闭弹层的 Performance 录制；不要以开发机为准。

---

## 9. 附录

### 9.1 已检查文件

**配置与入口**

- `frontend/package.json`、`frontend/vite.config.ts`
- `frontend/src/main.ts`、`frontend/src/App.vue`
- `frontend/src/router/index.ts`、`frontend/src/router/mobile.ts`、`frontend/src/router/meta.ts`

**样式与主题**

- `frontend/src/style.css`（全量检索 + 重点段落：tokens、布局、弹窗、命令面板、移动端、滚动头部）
- `frontend/src/utils/theme.ts`、`frontend/src/stores/theme.ts`、`frontend/src/stores/ui.ts`

**布局与通用组件**

- `components/layout/PrivateLayout.vue`、`PrivateSidebar.vue`、`SiteFooter.vue`
- `components/common/CommandPalette.vue`、`ConfirmDialog.vue`、`HavenMark.vue`
- `components/mobile/MobileLayout.vue`、`MobilePageHeader.vue`、`MobileTimePicker.vue`、`SwipeRow.vue`

**业务组件与页面（重点阅读）**

- `components/note/NoteListPanel.vue`、`FolderTreeNode.vue`、`NoteTreeItem.vue`、`FolderPicker.vue`、`TagDropdown.vue`、`TagNotesDialog.vue`、`SearchPanel.vue`
- `components/IssueFormDialog.vue`、`components/ledger/LedgerEntryDialog.vue`
- `components/LedgerTrendChart.vue`、`LedgerDonutChart.vue`、`components/mobile/MobileStatsChart.vue`
- `components/editor/VersionHistoryDialog.vue`、`RichTextEditor.vue`、`EditorToolbar.vue`、`EditorSlashMenu.vue`
- `views/private/HomeView.vue`、`NoteEditView.vue`、`IssuesView.vue`、`LedgerView.vue`
- `views/mobile/MobileLedger.vue`、`MobileAccounts.vue`、`MobileStats.vue`
- `composables/useSwipe.ts`、`useTreeDrag.ts`、`useGlobalShortcuts.ts`、`useNoteAutoSave.ts`

**检索覆盖**

- 全量 grep：`transition` / `animation` / `@keyframes` / `prefers-reduced-motion` / `will-change` / `transform` / `hover` / `<Transition>` / `v-show` / `v-html` / `role=` / `aria-` / `Escape` / `focus` / `scrollIntoView` / `requestAnimationFrame` / `setTimeout` / `addEventListener`。
- 结构统计：74 个 `.vue`、11,685 行 CSS、194 个 `<button>`（3 个缺 `type`）。

### 9.2 未覆盖范围

- 未启动开发服务器，未做真实浏览器渲染、截图或动效慢放；所有“手感”结论均来自代码与设计规则。
- 未做 Lighthouse / Performance / Memory 录制；H1、M5 的掉帧判断需要真机确认。
- 未测试 Safari / Firefox 对 `animation-timeline: scroll()`、`color-mix()`、`backdrop-filter` 的实际支持差异。
- 未做读屏软件（VoiceOver / NVDA / TalkBack）实测；ARIA 结论来自静态语义审阅。
- 未审阅后端、E2E 测试与 `integrations/`（Scriptable 小组件）；仅覆盖 `frontend/src`。
- 未检查实际主题对比度的视觉观感（只计算了 WCAG 对比度）。

### 9.3 待确认问题

1. 移动端大标题的滚动缩放，是否在目标机型（中端 Android / iPhone SE 级别）上实际掉帧？需要 Performance 面板与 CPU 节流录制。
2. 移动端底部 tabbar 的 24px 模糊，在滚动时是否出现明显掉帧或发热？如果否，可只修 H1，不动 M5。
3. 弹层打开时，背景滚动是否真的会穿透？桌面与移动端的滚动容器不同，当前没有 body scroll lock，需要真机触摸验证。
4. `prefers-reduced-motion` 在目标浏览器中是否确实忽略滚动时间线的 duration？建议用 Chrome DevTools 的 Rendering 面板模拟验证。
5. 浅色主题把 `--label-2` 加深后，是否会破坏现有的“低对比辅助信息”视觉层级？需要设计确认，而不是直接改 token。
6. 目录树是否必须保持每行 `tabindex="0"`（当前便于逐行 Tab）？改 roving tabindex 会改变部分用户的操作习惯，需要产品确认。
7. 是否计划支持公开域/多用户？当前评审仅覆盖单用户私有域，公开页面（登录、404）动效极少。
8. 是否接受“退出动效比进入更快”的统一规范（例如 enter 180ms / leave 120ms）？需要与现有 `--dur-*` token 一起定稿。

### 9.4 技能使用说明

- 已使用：`emil-design-eng`、`animate`、`improve-animations`、`find-animation-opportunities`、`animation-performance`、`vue3-frontend`。
- 请求中提到的 `review-animations`、`pick-ui-library`、`prototype`、`gestures` 在当前工作区**未安装**；本报告用 `improve-animations` 的审查清单与 `animate` 的构建规则替代，组件库/手势结论来自现有依赖与代码审阅，未声称使用未安装技能。
- 报告只读：除本文件外，未修改任何源码或配置。
