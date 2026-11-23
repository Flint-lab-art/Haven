# 前端实现细节

整体结构见 [architecture.md](../architecture.md#4-前端结构)，API 契约见
[api-conventions.md](../api-conventions.md)。本文件讲具体实现。

## 1. 启动时序

```text
main.ts
  ├─ createPinia() + createHavenRouter()   ← 立即返回，不做域名判定
  ├─ useThemeStore.init()                  ← 首次渲染前应用主题，避免深色闪白
  ├─ useAuthStore.installUnauthorizedHandler()  ← 401 清登录态并回 /login
  └─ createApp(App).use(pinia).use(router).mount('#app')
       └─ 首个导航触发路由守卫 → auth.refresh()（GET /api/me）→ 放行或跳 /login
```

**没有运行时配置加载**。早期版本会在挂载前请求 `GET /api/app-config` 拿 `private_hosts`
决定加载公开还是私有路由表；那套逻辑（`config.ts`、`router/domain.ts`、`api/system.ts`）已删除。
登录态在**路由守卫首次执行时**才拉，守卫内部会等 `auth.refresh()` 完成，所以不会出现"先当作未登录再跳回来"的闪烁。

## 2. 路由表

只有一张 `privateRoutes`（`router/index.ts`）。除 `/login`（`meta.public`）与 404 兜底外，全部挂在
`PrivateLayout` 三栏布局下，未登录一律跳 `/login?redirect=...`。

| 顶级路径 | 页面 | 中间列表栏 |
| --- | --- | --- |
| `/login` | 登录 | — |
| `/` | 仪表盘 | 无（`noList`） |
| `/notes`、`/notes/new`、`/notes/:id` | 工作台 / 新建 / 编辑 | `NoteListPanel` |
| `/search` | 搜索 | `SearchPanel` |
| `/trash` | 回收站 | `TrashPanel` |
| `/tags` | 标签 | 无 |
| `/ledger` | 记账 | 无 |
| `/issues`、`/issues/:id` | Issue 列表 / 详情 | 无 |
| `/settings/*` | 设置（`SettingsPanel` 作中间栏） | `SettingsPanel` |

`/settings/*` 子项：`概览`（`/settings`）、**账户**（`/settings/accounts`）、外观、账号安全、登录日志（`/settings/login-logs`）、会话、授信设备、API Token、导入账单。

`createHavenRouter()` 不接受参数，返回的 router 直接带登录守卫与标题逻辑；
未知路径落到 `NotFoundView`，且不标 `public`（未登录时也先登录）。

全局快捷键不在这里注册：由 `components/layout/PrivateLayout.vue` 挂载时通过 `composables/useGlobalShortcuts.ts` 启用，登录页没有快捷键。

### 移动端（`/m/`）

移动端是**同一份构建产物里的另一套路由树**（`router/mobile.ts`），与 PC 共用 `src/api/*`、`composables/*`，
但布局与页面完全独立：

| 路径 | 页面 | 说明 |
| --- | --- | --- |
| `/m/` | 统计 | 默认进去；周 / 月 / 季 / 年四粒度 |
| `/m/ledger` | 记账 | 流水列表 + 底部抽屉录入 |
| `/m/me` | 我的 | 身份卡 + 分组菜单 |
| `/m/me/accounts` | 账户 | 增删改归档 |
| `/m/me/appearance` | 外观 | 主题选择（原生） |
| `/m/me/login-logs` | 登录日志 | 原生 |
| `/m/me/settings` | 设置 | 外观 / 登录日志进原生页，其余三项跳 PC 页 |
| `/m/me/issues`、`/new`、`/:id` | Issue 列表 / 新建 / 详情 | 可改状态、编辑、删除 |

**入口由路径决定，不做 UA 嗅探**：PC 上也能打开 `/m/` 预览。

底部 tab 三只：统计 / 记账 / 我的（记账在中间，拇指最顺手）。`meta.mTab` 决定高亮。

**统计的四粒度不共用同一张图**：

| 粒度 | 形态 | 横轴 |
| --- | --- | --- |
| 周 | 折线 | 每天（7 点） |
| 月 | 折线 | 按自然周分桶（4~5 点） |
| 季 | 柱状 | 每月（3 根） |
| 年 | 柱状 | 每月（12 根） |

区域一律「不越过今天」：日期选择器只到今天，月份/区间切换到头时隐藏「下一段」。

**PWA**：`public/manifest.webmanifest`，`start_url` 为 `/m/`，`display: standalone`，竖屏。
只有 manifest，没有 Service Worker——记账要实时数据，缓存反而容易看到旧账。

如果要评估 iOS 原生 App（SwiftUI）的落地方式，见 [ios-native-design.md](ios-native-design.md)：
页面映射、设计 tokens、交互规范、鉴权与平台能力都在那里，本文只描述 Web 端现状。

## 3. API 层

### 请求

```ts
// client.ts
export async function request<T>(path: string, options: RequestOptions = {}): Promise<T>
```

- `body` 自动经 `toCamelCaseKeys` 递归转换（`tag_ids` → `tagIds`）
- `query` 会过滤 `undefined` / `null` / `''`
- 非 2xx 抛 `ApiError`（含 `status` / `code` / `fields`）
- 401 默认触发全局登出；登录接口传 `skipUnauthorizedHandler: true`

### 类型

每个领域一个文件，类型与后端 DTO 对齐：

```ts
export interface Note {
  id: string
  folder_id: string | null
  content_preview?: string
  tags: TagBrief[]
}
```

字段用 `snake_case`（与响应一致），不用在类型里做转换。

### 版本号

设置页显示的版本来自构建期注入的全局常量 `__APP_VERSION__`（`env.d.ts` 声明，`vite.config.ts`
从 `package.json` 读取），**不走接口**。`/api/app-config` 只是一个返回后端版本的占位端点，前端不用它。

## 4. 状态管理

| store | 内容 |
| --- | --- |
| `auth` | 当前用户、登录 / 登出、401 处理 |
| `theme` | 主题模式与配色，持久化到 localStorage |
| `ui` | 布局（侧栏折叠、选中笔记/文件夹）、跨组件事件（`notesChanged` 等） |

不放进 store 的东西：表单草稿、列表数据、加载状态——这些属于页面局部状态。

## 5. 编辑器

Tiptap 封装在 `views/private/NoteEditView.vue` 与相关扩展里：

| 能力 | 实现 |
| --- | --- |
| 富文本 | StarterKit + 表格、任务列表、折叠块、代码块高亮 |
| 图片 | 粘贴/拖拽 → `POST /api/uploads` → 插入 URL |
| 自动保存 | 防抖 1 秒，保存失败留在内存并提示 |
| 历史版本 | 保存时后端生成快照，前端做 Diff 展示 |
| 斜杠菜单 / 气泡菜单 | `utils/slash-command.ts` |

### 渲染安全

Markdown → HTML 必须经 `utils/markdown.ts`：

```ts
import DOMPurify from 'dompurify'
export function renderMarkdown(md: string, opts?): string {
  return DOMPurify.sanitize(marked.parse(md))
}
```

`v-html` 只用于这个函数的输出。**不要**直接 `v-html="note.content"`。

## 6. 记账页

见 [ledger.md](../ledger.md#9-前端约定)。要点：

- 分类数组、色阶、金额格式化集中在 `utils/ledger.ts`
- 新增分类要同步改四处（后端常量、迁移、前端联合类型、前端数组）
- 金额单位是分，只在展示时转元

## 7. 测试

```bash
pnpm test
```

优先测 `utils/` 里的纯函数：

| 文件 | 覆盖 |
| --- | --- |
| `ledger.test.ts` | 分类数组、金额格式化与解析、色阶 |
| `diff.test.ts` | 版本 Diff |
| `text-stats.test.ts` | 字数统计 |
| `theme.test.ts` | 主题解析 |
| `command-palette.test.ts` | 命令面板匹配 |

命令面板固定 6 条（新建笔记、仪表盘、工作台、标签、回收站、设置），由 `components/common/CommandPalette.vue` 内联定义。

## 7.1 组件目录

`src/components/` 按**角色**分组，不按领域照搬后端。原因：后端一个领域是
controller→service→mapper 的闭环；前端组件常常跨领域复用（`ConfirmDialog` 被笔记、
记账、Issue 三处使用），硬按领域分会造出 `common` 垃圾场。

```
components/
├── layout/   3  布局骨架（`PrivateLayout`、`PrivateSidebar`、页脚）
├── common/   5  跨领域通用（确认弹窗、命令面板、空详情、Logo、设置侧栏）
├── editor/   4  编辑器一族（富文本、工具栏、斜杠菜单、版本浮层）
├── note/    13  笔记域（列表、文件夹、搜索、标签、回收站、大纲）
├── ledger/   3  记账弹窗与图表
└── (根)      6  单领域且数量少的：统计 1、Issue 1、记账图表 2、认证 2
```

分组的门槛是**至少 3 个文件**。只有 1–2 个文件的领域留在根目录，
避免为了对称而制造空文件夹（同 `docs/backend`、`docs/frontend` 的处理方式）。

新增组件时：

| 情况 | 放哪 |
| --- | --- |
| 被 3 个以上领域使用 | `common/` |
| 只服务某一个页面族，且该族已有目录 | 对应目录（如 `note/`） |
| 新领域且只有 1 个组件 | 先放根目录；凑到 3 个再建目录 |

## 8. 新增一个页面

1. `views/private/` 下建 `.vue`（只有这一组页面）
2. `router/index.ts` 的 `privateRoutes` 里注册（需要中间列表栏就用 `components` 具名视图，默认 `default` 是右侧详情区）
3. 需要的接口加到 `api/*.ts`
4. 纯逻辑抽到 `utils/` 并补测试
5. 侧栏入口（`components/layout/PrivateSidebar.vue`）按需添加；命令面板命令在 `components/common/CommandPalette.vue` 里加

## 8.1 已知限制

| 限制 | 说明 |
| --- | --- |
| `NoteEditView` chunk 约 700 KB | ProseMirror + TipTap 扩展 + lowlight 的固有体积，超过 Vite 默认 600 KB 阈值时会告警。当前用 common 语言集，已是合理下限；不为消警告削减编辑器功能 |
| 无 `@vue/test-utils` 组件测试 | 现有 31 个测试文件覆盖 utils / router / 纯逻辑；组件层靠手动验证与 E2E |

## 9. 常见坑

| 坑 | 正确做法 |
| --- | --- |
| 请求体直接写 camelCase | 写 `snake_case`，client 会转 |
| `v-html` 直接渲染正文 | 走 `renderMarkdown` |
| 在 store 里放列表数据 | 放页面局部 `ref` |
| 新增分类只改了一处 | 四处都要改（见上） |
| 用 `any` 绕过后端字段变化 | 改 `api/*.ts` 的类型，让 `vue-tsc` 报错 |
| 想按域名分支加载不同路由 | 不存在这套逻辑：只有一张路由表，部署域名由反向代理决定 |
| `/m/` 下的浮层被底部 tab 压住 | `.m-main` 有 `overflow-y: auto`，会创建**新的层叠上下文**，内部 `fixed` 浮层的 `z-index` 只在这个容器内比较。所有 `fixed` 浮层（抽屉、弹窗、选择器）都要 `<Teleport to="body">` |
| 用函数式 ref 绑原生事件 | `` :ref="(el) => bind(el)" `` 在每次重渲染时会先传 `null` 再传新节点，配了 `attach` 里 `detach()` 的自定义手势会被反复摘掉。用模板 `ref` + `onMounted`（常驻元素）或 `watch(可见性)` + `nextTick`（条件渲染元素） |
