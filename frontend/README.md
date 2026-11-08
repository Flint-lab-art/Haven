# Haven Frontend

Haven 的前端：Vue 3 + TypeScript + Vite 单页应用。同一份构建产物同时服务公开站点和私有工作台，启动时根据域名选择路由表。

## 功能

- **私有域**
  - 仪表盘：笔记 / 字数 / 公开数量、写作热力图、最近编辑、文件夹与 Issue 概览
  - 笔记工作台：文件夹树、标签筛选、搜索、三栏布局
  - 富文本编辑器：标题、列表、任务列表、表格、代码块（高亮 / 复制）、图片上传、折叠块、颜色、对齐、字数统计、斜杠菜单、气泡菜单
  - 自动保存（防抖 1 秒）、历史版本与 Diff、回收站、发布 / 撤回
  - 标签、作品集、Issue、设置
- **公开域**
  - 首页、全部笔记、笔记详情、作品集、作品详情、站内搜索
  - 只读，无登录入口和后台链接
- **通用**
  - 命令面板、全局快捷键、多主题、响应式三栏布局
  - 图片粘贴 / 拖拽上传、代码块一键复制、外链安全处理

## 技术栈

| 组件 | 说明 |
| --- | --- |
| Vue 3.5 | Composition API + `<script setup>` |
| TypeScript | 严格模式，路径别名 `@` → `src` |
| Vite 8 | 开发服务器与构建 |
| Vue Router 4 | 公开 / 私有两套路由 |
| Pinia | 登录态、界面状态、主题 |
| TipTap 3 | 富文本编辑器（ProseMirror） |
| marked + DOMPurify | 作品集 Markdown 渲染与 HTML 消毒 |
| highlight.js / lowlight | 代码高亮 |
| Vitest + jsdom | 单元测试 |

## 环境要求

- Node.js 20.19+ 或 22.12+
- pnpm（仓库使用 `pnpm-lock.yaml`）
- 后端运行在 `http://127.0.0.1:8080`（或通过 `HAVEN_API_TARGET` 指定）

## 快速开始

```bash
cd frontend
pnpm install
pnpm dev
```

打开 `http://127.0.0.1:5173`。

开发服务器：

- 固定 `5173` 端口，被占用时直接报错（避免反向代理指错端口）
- 把 `/api` 代理到 `http://127.0.0.1:8080`
- 后端地址可用 `HAVEN_API_TARGET` 覆盖：

  ```bash
  HAVEN_API_TARGET=http://127.0.0.1:9090 pnpm dev
  ```

- 通过 HTTPS 反向代理访问开发服务器时，设置 `HAVEN_DEV_PROXY=1`，让 HMR WebSocket 指向 443：

  ```bash
  HAVEN_DEV_PROXY=1 pnpm dev
  ```

## 脚本

| 命令 | 说明 |
| --- | --- |
| `pnpm dev` | 启动 Vite 开发服务器 |
| `pnpm build` | `vue-tsc` 类型检查 + 生产构建，输出 `dist/` |
| `pnpm preview` | 预览 `dist/` |
| `pnpm test` | Vitest 单次运行 |
| `pnpm test:watch` | Vitest 监听模式 |

## 目录结构

```text
src/
├── main.ts               # 启动：加载运行时配置 → 创建 Pinia / Router → 挂载
├── App.vue               # 根组件
├── config.ts             # 运行时配置（GET /api/app-config）
├── style.css             # 全局样式与 CSS 变量
├── api/                  # 每类后端资源一个文件，统一走 client.ts
│   ├── client.ts         # fetch 封装、ApiError、401 回调
│   ├── auth.ts           # 登录、TOTP、改密
│   ├── notes.ts          # 笔记、回收站、历史版本
│   ├── folders.ts / tags.ts / search.ts / stats.ts
│   ├── portfolio.ts / issues.ts
│   ├── sessions.ts / devices.ts / tokens.ts
│   └── uploads.ts        # multipart 图片上传
├── components/           # 布局、编辑器、弹窗、列表等可复用组件
├── composables/          # useGlobalShortcuts、useCodeCopy
├── router/
│   ├── index.ts          # 公开 / 私有路由表、登录守卫、标题
│   └── domain.ts         # 当前域名属于公开域还是私有域
├── stores/
│   ├── auth.ts           # 登录态与 401 处理
│   ├── ui.ts             # 三栏布局共享状态、侧边栏折叠
│   └── theme.ts          # 主题切换与持久化
├── utils/                # 纯函数：markdown、diff、统计、主题、图标…
├── views/
│   ├── private/          # 私有域页面
│   └── public/           # 公开域页面
└── __tests__/            # Vitest 单元测试
```

## 路由

### 公开域

| 路径 | 页面 |
| --- | --- |
| `/` | 首页 |
| `/notes` | 全部公开笔记 |
| `/notes/:id` | 公开笔记详情 |
| `/search` | 公开搜索 |
| `/portfolio` | 作品集 |
| `/portfolio/:id` | 作品详情 |
| `/:pathMatch(.*)*` | 404 |

公开域不做登录态判断，也没有任何写入口。

### 私有域

| 路径 | 页面 |
| --- | --- |
| `/login` | 登录（唯一公开页面） |
| `/` | 仪表盘 |
| `/notes` | 工作台（空详情） |
| `/notes/new` | 新建笔记 |
| `/notes/:id` | 笔记编辑 |
| `/search` | 搜索 |
| `/tags` | 标签 |
| `/portfolio` | 作品集 |
| `/issues`、`/issues/:id` | Issue 列表 / 详情 |
| `/trash` | 回收站 |
| `/settings` | 设置概览 |
| `/settings/appearance` | 外观 |
| `/settings/security` | 账号安全 |
| `/settings/sessions` | 会话 |
| `/settings/devices` | 授信设备 |
| `/settings/tokens` | API Token |
| `/preview/notes/:id` | 公开笔记预览 |
| `/:pathMatch(.*)*` | 404 |

除 `/login` 外，私有域路由都要求登录；未登录会跳转到 `/login?redirect=<原路径>`。

## 公开域 / 私有域判定

判定逻辑在 `src/router/domain.ts`：

1. 应用启动时先请求 `GET /api/app-config`，读取后端下发的 `private_hosts`
2. 请求失败（纯静态部署、后端未启动）时，退回构建期变量 `VITE_PRIVATE_HOST`
3. 两者都没有时：

   - `localhost`、`*.localhost`、IP 地址 → 私有域
   - 其他域名 → 公开域

因此同一份 `dist/` 可以同时部署到 `note.example.com` 和 `www.example.com`，改域名不需要重新打包。后端配置：

```bash
HAVEN_PRIVATE_HOSTS=note.example.com,www.example.com
```

构建期兜底变量（可选，写在 `.env.local`）：

```bash
VITE_PRIVATE_HOST=note.example.com,www.example.com
```

## API 层约定

所有请求走 `src/api/client.ts`：

- 路径一律使用相对 `/api/...`，不写死域名
- 返回 204 时为 `undefined`
- 非 2xx 统一抛 `ApiError`，包含 `status`、`code`、`message`、`fields`
- 401 默认触发全局登出回调；登录接口通过 `skipUnauthorizedHandler` 跳过
- 列表响应类型为 `{ items: T[], total: number }`

`src/api/` 只负责请求与类型定义，不保存状态；状态放在 Pinia store 或页面组件里。

## 状态管理

| Store | 职责 |
| --- | --- |
| `auth` | 启动时 `GET /api/me` 初始化；登录 / 登出；注册全局 401 处理；判断 `isSession` / `canWrite` |
| `ui` | 侧边栏折叠状态、笔记 / 标签 / 文件夹 / 作品集 / 回收站版本号、跨栏选中项、编辑器保存回调 |
| `theme` | 主题读写与 `<html data-theme>` 同步 |

持久化使用 `localStorage`：

- `haven.ui.theme`：当前主题
- `haven.ui.sidebarMini`：侧边栏是否折叠为 Mini 模式

主题定义在 `src/utils/theme.ts`：浅色（默认）、Tokyo Night、Gruvbox、Catppuccin、Nord。新增主题需要同时修改 `THEMES` 和 `style.css` 中对应的 `[data-theme='...']` 变量块。

## 编辑器与内容渲染

- 笔记正文由 TipTap 生成 **HTML**，保存的是 `editor.getHTML()`
- 阅读态 HTML 先经过 DOMPurify，再补代码高亮、复制按钮、只读复选框、表格包裹等增强
- 作品集正文仍是 **Markdown**，用 `marked` 渲染后再走同一套消毒流程
- 图片粘贴 / 拖拽会走 `/api/uploads`，正文只保存相对 URL
- 编辑器扩展顺序固定；`CodeBlockLowlight` 与 StarterKit 的 `codeBlock` 不能同时启用

## 快捷键与命令面板

| 快捷键 | 行为 |
| --- | --- |
| `Cmd/Ctrl + K` | 打开 / 关闭命令面板 |
| `Cmd/Ctrl + N` | 新建笔记（输入框内不拦截） |
| `Cmd/Ctrl + S` | 在编辑器中立即保存 |

命令面板支持：

- `s 关键词`：按标题搜索笔记
- `n 标题`：新建笔记并预填标题（会先选择文件夹）
- 输入 `n` / `d` / `w` / `t` / `g` / `p` / `,` 或直接回车：新建笔记、仪表盘、工作台、标签、回收站、作品集、设置

## 测试

```bash
pnpm test         # 单次运行
pnpm test:watch   # 监听模式
```

测试使用 Vitest + jsdom，文件位于 `src/__tests__/*.test.ts`，覆盖路由、主题、快捷键、命令面板、Markdown 渲染、Diff、编辑器扩展等纯逻辑与路由行为。

## 构建与部署

```bash
pnpm build
```

产物在 `frontend/dist/`。生产环境由后端同源托管：

```bash
cd frontend
pnpm build
rm -rf ../backend/src/main/resources/static
cp -r dist ../backend/src/main/resources/static
```

`vite.config.ts` 会把 `package.json` 的 `version` 注入为 `__APP_VERSION__`，设置页直接显示这个版本号。

构建时开启了路由懒加载，编辑器单独成块；`chunkSizeWarningLimit` 为 600 KB。

## 开发约定

- 组件与页面使用 `<script setup lang="ts">`，注释使用中文
- 路径别名统一用 `@/...`，不写 `../../`
- `src/api/` 不保存状态；跨页面状态放 `stores/`
- 纯函数放 `src/utils/`，便于单测
- 新增页面时同步补路由的 `meta.title` 与 `meta.section`（私有域三栏布局依赖 `section`）
- 所有渲染 HTML 的地方必须先消毒，禁止直接 `v-html` 未处理的内容
- 测试与实现放在同一个 `src/__tests__/` 目录，文件名以 `.test.ts` 结尾
