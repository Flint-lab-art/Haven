# frontend — Web 前端页面与交互

> 本文件回答：公开域与私有域各有哪些页面、每页调哪些接口、登录态与路由规则。
> 依赖：api.md、auth.md、architecture.md

## 一、部署形态

前端为单一 Vue 3 + Vite SPA 构建，通过**两个域名**区分公开与私有：

| 域名 | 角色 | 说明 |
|---|---|---|
| `example.com` | 公开域 | 匿名可访问，展示公开内容，无登录入口 |
| `app.example.com` | 私有域 | 登录后使用，笔记管理、设置、Token 等 |

- `www.example.com` 301 重定向到 `example.com`；
- 两个域名指向**同一份前端构建**，前端启动时按 `window.location.hostname` 判断当前域，加载对应的路由表；
- API 请求一律发往当前域名下的 `/api/*`（后端同源托管，不跨域）。

## 二、cookie 域配置

- 会话 cookie、授信设备 cookie 的 `Domain` 设为 `app.example.com`，**不设 `.example.com`**；
- 效果：公开域收不到任何 cookie，公开域的请求天然无凭证，减少 CSRF 面；
- 私有域内的所有请求自带 cookie。

该配置由环境变量 `HAVEN_COOKIE_DOMAIN` 提供，见 `architecture.md` 第四节。cookie 属性细节见 `auth.md` 第三节规则 2。

## 三、公开域路由

| 路径 | 页面 | 调用的接口 |
|---|---|---|
| `/` | 公开笔记列表（首页） | `GET /api/public/notes` |
| `/notes/:id` | 公开笔记详情 | `GET /api/public/notes/:id` |
| `/search?q=` | 公开搜索 | `GET /api/public/search` |
| `/portfolio` | 作品集展示 | `GET /api/public/portfolio` |

**规则**：

- 公开域**没有登录页、没有设置页、没有任何写操作入口**；
- 公开域**不暴露任何后台入口**。后台地址由使用者手动输入，不在页面上放链接；
- 所有页面匿名可访问，不需要登录态判断；
- 公开笔记详情页展示笔记的 tag，点击 tag 跳转到 `/search?q=<tag 名>`。

## 四、私有域路由

| 路径 | 页面 | 调用的接口 |
|---|---|---|
| `/login` | 登录页（含 TOTP 第二步） | `POST /api/auth/login`、`POST /api/auth/login/totp` |
| `/` | 笔记列表（工作台首页） | `GET /api/notes` |
| `/notes/:id` | 笔记详情 / 编辑 | `GET /api/notes/:id`、`PATCH /api/notes/:id`、`POST /api/notes/:id/publish`、`POST /api/notes/:id/unpublish`、`DELETE /api/notes/:id` |
| `/notes/new` | 新建笔记 | `POST /api/notes` |
| `/search?q=` | 私有搜索 | `GET /api/search` |
| `/tags` | 标签管理 | `GET /api/tags`、`POST /api/tags`、`DELETE /api/tags/:id` |
| `/portfolio` | 作品集管理 | `GET /api/public/portfolio`、`POST /api/portfolio`、`PATCH /api/portfolio/:id`、`DELETE /api/portfolio/:id`、仓库链接的增删改 |
| `/settings` | 设置入口 | `GET /api/me` |
| `/settings/security` | 密码、TOTP | `POST /api/auth/password`、`POST /api/auth/totp/*` |
| `/settings/sessions` | 会话管理 | `GET /api/sessions`、`DELETE /api/sessions/:id` |
| `/settings/devices` | 授信设备管理 | `GET /api/trusted-devices`、`DELETE /api/trusted-devices/:id` |
| `/settings/tokens` | API Token 管理 | `GET /api/tokens`、`POST /api/tokens`、`DELETE /api/tokens/:id` |
| `/preview/notes/:id` | 公开笔记预览（可选） | `GET /api/public/notes/:id` |

**规则**：

- 除 `/login` 外，所有页面需要登录，router guard 统一处理；
- 未登录访问任意受保护路径 → 重定向到 `/login`；
- 登录成功后回到原本要访问的路径（`?redirect=` 参数）；
- 私有域的工作台首页就是笔记列表，不再有“三合一主页”；
- `/settings/tokens` 页面若收到 403（当前会话未通过 TOTP），页面内提示“管理 Token 需要完成 TOTP 验证”，并提供跳转到 `/settings/security` 完成验证的按钮，不强制登出。

## 五、登录流程（前端视角）

1. `/login` 页面显示账号密码表单；
2. 提交 → `POST /api/auth/login`；
3. 若响应 `totp_required: false` → 登录完成，跳转目标页；
4. 若响应 `totp_required: true` → 表单切换为 TOTP 输入框，暂存 `temp_token`（内存变量，不落 localStorage）；
5. 用户输入 6 位码 → `POST /api/auth/login/totp`；
6. 成功 → 跳转目标页；失败 → 提示错误，可重试（5 分钟内有效）；
7. `temp_token` 过期 → 回到账号密码步骤，提示“登录已超时，请重新登录”。

## 六、全局状态

- `auth` store（Pinia）：当前用户、`auth_type`、`totp_enabled`、Token 的 `scope`；
- 启动时调 `GET /api/me` 初始化；
- 401 响应统一处理：清空 store、跳转 `/login`；
- 403 响应：提示“权限不足”，不跳转（页面自行处理特殊情况，如 `/settings/tokens` 的 TOTP 引导）。

## 七、API 客户端约定

- `frontend/src/api/` 下按领域分文件：`auth.ts`、`notes.ts`、`tags.ts`、`search.ts`、`portfolio.ts`、`sessions.ts`、`devices.ts`、`tokens.ts`、`me.ts`；
- 统一封装 `ApiError`，含 `error`、`message`、`fields`；
- 请求路径一律相对路径（`/api/...`），不写死域名，靠当前域自动路由；
- 公开域与私有域共用同一套 API 客户端代码，页面决定调哪个函数。

## 八、样式与组件

- 不做组件库锁定，用原生 CSS 或轻量库，优先可读性；
- 公共组件：`NoteCard`、`TagBadge`、`SearchBar`、`LoginForm`、`TotpForm`、`SettingsNav`；
- 不做深色模式切换（如需要，后期加，不在本期）。

## 九、不做的事

- 不做 SSR / SEO；
- 不做移动端专门适配（响应式布局即可，不做独立 App）；
- 不做 PWA；
- 公开域不做登录入口以外的任何写操作；
- 公开域不放后台链接；
- 不做多语言（中文界面固定）。
