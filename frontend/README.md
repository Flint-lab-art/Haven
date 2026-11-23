# Haven Frontend

Haven 的前端：Vue 3 + TypeScript + Vite 单页应用。只有登录后的私有工作台，一张路由表、一份构建产物，部署在什么域名由反向代理决定。

**设计文档在 [`../docs/`](../docs/README.md)**——本文件只讲怎么跑、有哪些能力、有哪些约定。

> **版本号规则与标准 SemVer 不同**，且需与后端保持一致。
> 见 [`../docs/versioning.md`](../docs/versioning.md)。版本号以根目录 `VERSION` 文件为准，与后端一致。

## 功能

- **工作台**
  - 仪表盘：笔记 / 字数 / 写作热力图、最近编辑、最近 7 天记账图表、文件夹与 Issue 概览
  - 笔记工作台：文件夹树、标签筛选、搜索、三栏布局
  - 富文本编辑器：标题、列表、任务列表、表格、代码块（高亮 / 复制）、图片上传、折叠块、颜色、对齐、字数统计、斜杠菜单、气泡菜单
  - 自动保存（防抖 1 秒）、历史版本与 Diff、回收站
  - 记账：多行输入解析预览（行首可写日期）、确认后按 `batch_id` 幂等写入、月度汇总与支出 / 收入分类排行、每日走势与分类占比图表、明细改分类 / 金额 / 时间
    - 支出分类：餐饮 / 购物 / 交通 / 居家 / 娱乐 / 医疗 / **还款** / Token / 订阅 / 未分类
    - 收入分类：工资 / 奖金 / 报销 / 退款 / 红包 / 其他收入
  - 标签、记账、Issue、设置（外观、账号安全、登录日志、会话、授信设备、API Token、导入账单）
- **通用**
  - 命令面板、全局快捷键、多主题、响应式三栏布局
  - 图片粘贴 / 拖拽上传、代码块一键复制、外链安全处理

## 技术栈

| 组件 | 说明 |
| --- | --- |
| Vue 3.5 | Composition API + `<script setup>` |
| TypeScript | 严格模式，路径别名 `@` → `src` |
| Vite 8 | 开发服务器与构建 |
| Vue Router 4 | 单一路由表 + 登录守卫 |
| Pinia | 登录态、界面状态、主题 |
| TipTap 3 | 富文本编辑器（ProseMirror） |
| marked + DOMPurify | Issue 描述 Markdown 渲染与全部 HTML 消毒 |
| highlight.js / lowlight | 代码高亮 |
| Vitest + jsdom | 单元测试 |

## 环境要求

- Node.js 20.19+ 或 22.12+
- pnpm（仓库使用 `pnpm-lock.yaml`）
- 后端运行在 `http://127.0.0.1:8080`（或通过 `HAVEN_API_TARGET` 指定）

## 快速开始

> **本地开发通常不需要单独起前端。** 构建时前端产物会被复制进
> `backend/src/main/resources/static/`，后端同源托管，`./scripts/run.sh` 一条命令即可。
> 只有需要前端热更新时才起 Vite。

```bash
# 方式一：随后端一起跑（推荐日常使用）
./scripts/build.sh frontend      # 构建一次，产物进 backend/src/main/resources/static/
./scripts/run.sh                 # 只跑后端

# 方式二：起 Vite 开发服务器（需要热更新时）
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
├── main.ts               # 启动：创建 Pinia / Router → 应用主题 → 挂载
├── App.vue               # 根组件
├── env.d.ts              # 构建期全局声明（__APP_VERSION__）
├── style.css             # 全局样式与 CSS 变量
├── api/                  # 每类后端资源一个文件，统一走 client.ts
│   ├── client.ts         # fetch 封装、ApiError、401 回调
│   ├── auth.ts           # 登录、TOTP、改密
│   ├── me.ts             # 当前用户
│   ├── notes.ts          # 笔记、回收站、历史版本
│   ├── folders.ts / tags.ts / search.ts / stats.ts
│   ├── issues.ts
│   ├── ledger.ts         # 解析、批量写入、汇总、明细
│   ├── sessions.ts / devices.ts / tokens.ts / login-logs.ts
│   └── uploads.ts        # multipart 图片上传
├── components/           # 按角色分组，见下方「组件目录」
├── composables/          # useGlobalShortcuts、useNoteAutoSave、useTreeDrag…
├── router/
│   ├── index.ts          # 单一路由表、登录守卫、标题
│   └── meta.ts           # RouteMeta 类型扩展（title / section / public / noList）
├── stores/
│   ├── auth.ts           # 登录态与 401 处理
│   ├── ui.ts             # 三栏布局共享状态、侧边栏折叠
│   └── theme.ts          # 主题切换与持久化
├── utils/                # 纯函数：markdown、diff、统计、主题、图标…
├── views/
│   └── private/          # 全部页面
└── __tests__/            # Vitest 单元测试
```

## 路由

| 路径 | 页面 |
| --- | --- |
| `/login` | 登录（唯一 `meta.public` 页面） |
| `/` | 仪表盘 |
| `/notes` | 工作台（空详情） |
| `/notes/new` | 新建笔记 |
| `/notes/:id` | 笔记编辑 |
| `/search` | 搜索 |
| `/tags` | 标签 |
| `/ledger` | 记账（汇总、快速记账、明细） |
| `/issues`、`/issues/:id` | Issue 列表 / 详情 |
| `/trash` | 回收站 |
| `/settings` | 设置概览 |
| `/settings/appearance` | 外观 |
| `/settings/security` | 账号安全 |
| `/settings/login-logs` | 登录日志 |
| `/settings/sessions` | 会话 |
| `/settings/devices` | 授信设备 |
| `/settings/tokens` | API Token |
| `/settings/import` | 导入账单 |
| `/:pathMatch(.*)*` | 404 |

除 `/login` 外，路由都要求登录；未登录会跳转到 `/login?redirect=<原路径>`。

## 域名无关

`createHavenRouter()` 不接收参数，`src/router/index.ts` 只有一张路由表：应用不知道也没必要知道自己部署在哪个域名，域名与 TLS 都由反向代理决定。启动时不再请求 `/api/app-config`，也没有任何域名配置。

版本号来自构建期注入的 `__APP_VERSION__`（`vite.config.ts` 读取 `package.json`），设置页直接显示，不经网络请求。

## API 层约定

所有请求走 `src/api/client.ts`：

- 路径一律使用相对 `/api/...`，不写死域名
- 请求与响应**都是 `snake_case`**：后端 Jackson 3 的 `SNAKE_CASE` 策略双向生效，
  请求体原样序列化即可，`api/*.ts` 一律按 `snake_case` 书写
- 不要在前端做键名转换：`tempToken` 这类 camelCase 字段后端**接收不到**
- 返回 204 时为 `undefined`
- 非 2xx 统一抛 `ApiError`，包含 `status`、`code`、`message`、`fields`
- 401 默认触发全局登出回调；登录接口通过 `skipUnauthorizedHandler` 跳过
- 列表响应类型为 `{ items: T[], total: number }`

`src/api/` 只负责请求与类型定义，不保存状态；状态放在 Pinia store 或页面组件里。

### 两个特殊形状

| 接口 | 响应 |
| --- | --- |
| `GET /api/issues/{id}` | `{ issue, status_events }`；`api/issues.ts` 的 `getIssue()` 内部摊平成页面直接用的 `IssueDetail` |
| `POST /api/ledger/entries/quick` | `{ batch, errors }`，注意不是扁平的批次对象 |

## 状态管理

| Store | 职责 |
| --- | --- |
| `auth` | 启动时 `GET /api/me` 初始化；登录 / 登出；注册全局 401 处理；判断 `isSession` / `canWrite` |
| `ui` | 侧边栏折叠状态、笔记 / 标签 / 文件夹 / 回收站版本号、跨栏选中项、编辑器保存回调 |
| `theme` | 主题读写与 `<html data-theme>` 同步 |

持久化使用 `localStorage`：

- `haven.ui.theme`：当前主题
- `haven.ui.sidebarMini`：侧边栏是否折叠为 Mini 模式

主题定义在 `src/utils/theme.ts`：浅色（默认）、Tokyo Night、Gruvbox、Catppuccin、Nord。新增主题需要同时修改 `THEMES` 和 `style.css` 中对应的 `[data-theme='...']` 变量块。

## 编辑器与内容渲染

- 笔记正文由 TipTap 生成 **HTML**，保存的是 `editor.getHTML()`
- 阅读态 HTML 先经过 DOMPurify，再补代码高亮、复制按钮、只读复选框、表格包裹等增强
- Issue 描述是 **Markdown**，用 `marked` 渲染后再走同一套消毒流程
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
- 输入 `n` / `d` / `w` / `t` / `g` / `,` 或直接回车：新建笔记、仪表盘、工作台、标签、回收站、设置

## 测试

```bash
./scripts/test.sh frontend   # vue-tsc + vitest
```

或手动：

```bash
pnpm test         # 单次运行
pnpm test:watch   # 监听模式
```

测试使用 Vitest + jsdom，文件位于 `src/__tests__/*.test.ts`（31 个文件、237 个用例），覆盖纯函数、路由行为与请求体契约：

| 文件 | 覆盖 |
| --- | --- |
| `ledger.test.ts` | 分类数组与长度、色阶、金额格式化 / 解析 |
| `diff.test.ts` | 版本 Diff |
| `text-stats.test.ts` | 字数统计 |
| `theme.test.ts` | 主题解析 |
| `command-palette.test.ts` | 命令面板匹配 |

> **新增分类要同步四处**：后端 `LedgerCategories`、数据库 CHECK 约束（新迁移）、
> `api/ledger.ts` 的联合类型、`utils/ledger.ts` 的数组与色阶。前端这两处有测试守着。

## 构建与部署

```bash
./scripts/build.sh frontend      # 构建 + 复制到 backend/src/main/resources/static/
./scripts/build.sh all           # 再打包成一个 jar
```

脚本会先清空 `static/`（避免旧哈希文件残留），再复制 `dist/` 内容。
生产部署只需要分发 `backend/target/haven-<版本>.jar` 一个文件（当前 `haven-2.4.0.jar`）。

`vite.config.ts` 会把 `package.json` 的 `version` 注入为 `__APP_VERSION__`，设置页直接显示这个版本号。
后端版本在 `backend/pom.xml`，产物名为 `haven-<版本>.jar`（版本号见根目录 `VERSION`）。

构建时开启了路由懒加载，编辑器单独成块；`chunkSizeWarningLimit` 为 600 KB。

## 开发约定

- 组件与页面使用 `<script setup lang="ts">`，注释使用中文
- 路径别名统一用 `@/...`，不写 `../../`
- `src/api/` 不保存状态；跨页面状态放 `stores/`
- 纯函数放 `src/utils/`，便于单测
- 新增页面时同步补路由的 `meta.title` 与 `meta.section`（三栏布局依赖 `section`）
- 所有渲染 HTML 的地方必须先消毒，禁止直接 `v-html` 未处理的内容
- 测试与实现放在同一个 `src/__tests__/` 目录，文件名以 `.test.ts` 结尾
