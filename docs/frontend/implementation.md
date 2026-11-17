# 前端实现细节

整体结构见 [architecture.md](../architecture.md#4-前端结构)，API 契约见
[api-conventions.md](../api-conventions.md)。本文件讲具体实现。

## 1. 启动时序

```text
main.ts
  ├─ 创建 app / router / pinia
  ├─ 注册全局快捷键、错误处理器
  └─ 挂载前：GET /api/app-config
       ├─ 记录 private_hosts
       ├─ 决定用公开路由表还是私有路由表
       └─ 拉一次 GET /api/me 确定登录态
```

`useAuthStore` 在**路由守卫首次执行前**就要知道当前域名是不是私有域，否则会出现
"私有域被当成公开域"或反之的瞬间闪烁。

## 2. 两套路由

| 范围 | 前缀 | 守卫 |
| --- | --- | --- |
| 公开域 | `/`、`/notes`、`/notes/:id`、`/portfolio`、`/search` | 无 |
| 私有域 | `/dashboard`、`/notes/...`、`/ledger`、`/issues`、`/settings/*` | 未登录跳 `/login` |

公开域**没有登录入口**，私有域**不重定向到公开域名**——两个域名是两台不同的站点，共用一个构建产物。

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

## 4. 状态管理

| store | 内容 |
| --- | --- |
| `auth` | 当前用户、是否私有域、登录 / 登出、401 处理 |
| `theme` | 主题模式与配色，持久化到 localStorage |
| `ui` | 布局（侧栏折叠、选中笔记/文件夹/作品）、跨组件事件（`notesChanged` 等） |

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

组件测试最后考虑，避免断言 DOM 结构导致改动即失败。

## 7.1 组件目录

`src/components/` 按**角色**分组，不按领域照搬后端。原因：后端一个领域是
controller→service→mapper 的闭环；前端组件常常跨领域复用（`ConfirmDialog` 被笔记、
记账、Issue、作品集四处使用），硬按领域分会造出 `common` 垃圾场。

```
components/
├── layout/   7  布局骨架（私有/公开两套壳、页脚、返回顶部空态）
├── common/   5  跨领域通用（确认弹窗、命令面板、Logo、设置区间、空态）
├── editor/   4  编辑器一族（富文本、工具栏、斜杠菜单、版本浮层）
├── note/    10  笔记域（列表、文件夹、搜索、标签、回收站、大纲）
└── (根)      7  单领域且数量少的：记账 2、统计 1、Issue 1、作品集 1、认证 2
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

1. `views/private/` 或 `views/public/` 下建 `.vue`
2. `router/index.ts` 注册到对应路由表
3. 需要的接口加到 `api/*.ts`
4. 纯逻辑抽到 `utils/` 并补测试
5. 侧栏入口（`components/PrivateSidebar.vue`）按需添加

## 8.1 已知限制

| 限制 | 说明 |
| --- | --- |
| `NoteEditView` chunk 约 700 KB | ProseMirror + TipTap 扩展 + lowlight 的固有体积，超过 Vite 默认 600 KB 阈值时会告警。当前用 common 语言集，已是合理下限；不为消警告削减编辑器功能 |
| 无 `@vue/test-utils` 组件测试 | 现有 23 个测试文件覆盖 utils / router / 纯逻辑；组件层靠手动验证 |

## 9. 常见坑

| 坑 | 正确做法 |
| --- | --- |
| 请求体直接写 camelCase | 写 `snake_case`，client 会转 |
| `v-html` 直接渲染正文 | 走 `renderMarkdown` |
| 在 store 里放列表数据 | 放页面局部 `ref` |
| 新增分类只改了一处 | 四处都要改（见上） |
| 用 `any` 绕过后端字段变化 | 改 `api/*.ts` 的类型，让 `vue-tsc` 报错 |
