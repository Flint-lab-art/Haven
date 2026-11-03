# TODO

> 执行清单，不是事实来源。所有实现细节以 `docs/` 为准；本文件与 `docs/` 冲突时以 `docs/` 为准。
> `docs/` 只读，需求变更请先改文档，再勾选这里的条目。

当前阶段：**六期（v6）已完成**。一期至五期已完成并归档在本文下半部分。

图例：`[ ]` 未做 · `[x]` 已完成 · `[~]` 部分完成

---

# 二期（v2）

文档：`docs/v2/`，入口为 `docs/v2/changes.md`。范围与顺序：**F3 → F1 → F2**。

## 二期.0 开工前置

- [x] 按 `docs/v2/backend/test-plan.md` 第二节确认基线：`go build ./...`、`go vet ./...`、`go test ./...`（**必须设置 `HAVEN_TEST_DB_DSN`，skip 不算通过**）、`pnpm test`、`pnpm build` 全绿（2026-10-31 实测：四项全通过）
- [x] 确认本地库已执行到 `0005_inbox_folder`，且 `schema_migrations` 无 `dirty`（实测 `version=5, dirty=f`）

## 二期.F3 测试补齐（最先做，见 `docs/v2/backend/test-plan.md`）

> 调整说明：F3.2 与 F3.3 的用例断言的是 F1 / F2 才引入的行为，先写只会是红的。
> 已按 `docs/v2/backend/test-plan.md` 的意图拆开：**现有代码的测试在 F3.1 完成**，
> **F1 / F2 的测试分别挂在 F1.4、F2.4**，与功能同一条提交完成。

### F3.1 纯函数单测（已完成）

- [x] `internal/search`：`escapeLike` 单测（`%`、`_`、`\` 转义；空串；中文多字节）——`internal/search/search_test.go`，12 个用例
- [x] `internal/notes`：`Preview` 单测（空串 / 恰好 200 rune / 201 rune / 多字节不按字节截断）——`internal/notes/preview_test.go`
- [x] `internal/notes`：`sameFolder` 单测（nil 与 nil / nil 与值 / 相同 / 不同）——`internal/notes/folder_test.go`
- [x] `internal/folders`：`isSelfOrDescendant` 单测（自身 / 直接子级 / 隔代 / 兄弟 / 无关节点，能识别成环）——依赖 `*sql.Tx` 无法纯函数单测，改为 `cmd/haven/folders_cycle_test.go` 通过 PATCH 防环验证（自身 / 直接子级 / 隔代 / 兄弟合法 / 先移动再成环）
- [x] `internal/folders`：`normalizeIcon` 单测（空 / 单 Emoji / 16 rune 边界 / 17 rune / 含换行）——`internal/folders/icon_test.go`；顺带确认纯空白与纯换行均按「未设置」处理
- [x] `internal/tags`：标签名长度单测（63 / 64 / 65 rune；trim 后为空；多字节按 rune 计数）——校验内联在 `Create` 且依赖数据库，改为 `cmd/haven/tags_length_test.go` 通过 API 验证边界

## 二期.F1 回收站（见 `docs/v2/api.md` 第二、四节，`docs/v2/backend/data-model.md` 第一、三节）

### F1.1 数据层

- [x] `migrations/0006_notes_recycle_bin.up.sql` / `.down.sql`：`notes.deleted_at` + `idx_notes_deleted` 部分索引（已应用，`up`/`down` 均验证通过）
- [x] `auth.VisibilityPublic` / `auth.VisibilityOwnedOrPublic` 追加 `deleted_at IS NULL`（**唯一一处**，不在 handler 另拼）——注意「自己的」分支也必须排除已删行，否则登录用户仍能看到自己删掉的笔记；同时补齐 `notes.Get`、`tags.NotesByTag`、`tags.List` 与 `search.Private` 的标签计数
- [x] `folders.Delete` 迁移笔记时加 `AND deleted_at IS NULL`，不搬动回收站中的笔记——`cmd/haven/folders_trash_test.go` 覆盖两条路径

### F1.2 接口层

- [x] `notes.Delete` 改为 `UPDATE notes SET deleted_at = now()`；已删除再删返回 404—`TestDeleteMovesToTrash`
- [x] `notes.Update` / `Publish` / `Unpublish` 对已删除笔记返回 404
- [x] `GET /api/notes/trash`：`deleted_at DESC`，返回 `content_preview`、`folder_path`、`deleted_at`，访问时顺带惰性清理
- [x] `POST /api/notes/:id/restore`：清 `deleted_at`；原文件夹不存在时归入收件箱
- [x] `DELETE /api/notes/:id/purge`：仅对回收站中的笔记有效
- [x] `DELETE /api/notes/trash`：清空回收站
- [x] 惰性清理：保留 30 天（代码常量，不走环境变量）——`TrashRetention`，`cmd/haven/trash_api_test.go` 覆盖

### F1.3 前端

- [x] `src/api/notes.ts` 增加回收站四个调用
- [x] 新增 `/trash` 路由（`meta.section: 'trash'`），未登录跳 `/login`——`src/__tests__/trash-route.test.ts`
- [x] 侧边栏：在 `sidebar__spacer` 与用户区之间新增「回收站」入口，Mini 模式显示 tooltip
- [x] 回收站页面：列表（标题 / 原路径 / 删除时间）+ 只读预览 + 还原 / 永久删除 / 清空
- [x] 删除确认文案改为「可在回收站中还原」（仅笔记，文件夹不变）

### F1.4 测试（与原 F3.2 / F3.3 对应，跟功能一起完成）

- [x] 软删除后 `GET /api/public/notes` 与 `/api/public/notes/:id` 不可见 —— `cmd/haven/trash_visibility_test.go`
- [x] 软删除后 `GET /api/public/search` 不返回
- [x] 软删除后 `GET /api/search` 不返回
- [x] 软删除后 `GET /api/tags/:id/notes` 不返回，且 `note_count` 不计已删
- [x] 软删除后 `GET /api/notes` 不返回
- [x] 还原后上述接口重新可见
- [x] 原文件夹已删除时还原，笔记落到收件箱
- [x] 超过 30 天的回收站记录在访问回收站时被清理
- [x] 跨用户无法查看他人的回收站
- [x] `/trash` 路由需要登录，未登录跳 `/login`——`src/__tests__/trash-route.test.ts`
- [x] 在 `/trash` 时侧边栏对应项高亮、其他项不高亮（校验 section 归属互不重叠）
- [x] 笔记删除确认框提示「可在回收站中还原」；文件夹删除仍为「不可恢复」

## 二期.F2 历史版本（见 `docs/v2/api.md` 第三、四节，`docs/v2/backend/data-model.md` 第二、三节）

### F2.1 数据层

- [x] `migrations/0007_note_versions.up.sql` / `.down.sql`：`note_versions` 表（`tag_ids uuid[]`）+ `idx_note_versions_note`（已应用）
- [x] `notes.Update` 事务内、更新前写快照；仅当标题 / 正文 / 文件夹 / 标签真的变化
- [x] 同一笔记 5 分钟内合并为一条（代码常量 `VersionMergeWindow`，不走环境变量）

### F2.2 接口层

- [x] `GET /api/notes/:id/versions`：`created_at DESC`，返回标题、时间、`content_size`，不返回正文
- [x] `GET /api/notes/:id/versions/:versionId`：返回完整快照含 `tag_ids`
- [x] `POST /api/notes/:id/versions/:versionId/restore`：覆盖标题 / 正文 / 文件夹 / 标签，还原本身也产生一条快照
- [x] 已删除笔记的版本接口一律 404；跨用户 404

### F2.3 前端

- [x] 编辑页 `editor-actions` 内、字数之后新增「历史版本」按钮；`/notes/new` 未创建时不显示
- [x] 浮层：左栏版本时间线，右栏为该版本与**当前编辑器内容**的 DIFF（基准 A）——`components/VersionHistoryDialog.vue`
- [x] 只对正文做 DIFF；标题变化在顶部单独提示
- [x] 还原前二次确认；还原时先 `sync()` 再覆盖，避免与自动保存竞争
- [x] 点击外部或 `Esc` 关闭浮层（`pointerdown` 判断，不用 `focusout`）

### F2.4 测试（与原 F3.2 / F3.3 对应，跟功能一起完成）

- [x] 标题 / 正文 / 文件夹 / 标签变化时产生版本快照；只改 `sort_order` 不产生——`cmd/haven/versions_test.go`
- [x] 5 分钟内的多次修改合并为一条快照
- [x] 版本还原后标题、正文、文件夹、标签与快照一致
- [x] 跨用户无法查看他人的版本
- [x] DIFF 行分类（新增 / 删除 / 未变）纯函数单测——`src/__tests__/diff.test.ts`，12 个用例

---

# 三期（v3）已完成

> 文档：`docs/v3/`，入口 `docs/v3/changes.md`。公开站改版、作品详情、标签页。

## 三.1 公开域

- [x] 首页改为「品牌标语 → 作品集卡片网格（双列）→ 近期笔记」，去掉搜索框
- [x] 内容区宽度放宽到 960px（`.container--wide`）
- [x] 新增 `/notes` 全部公开笔记页，保留「加载更多」
- [x] 首页作品卡片与作品集列表都链接到作品详情
- [x] 新增作品详情页 `/portfolio/:id`，渲染 Markdown 介绍正文

## 三.2 作品集正文

- [x] `0008` migration：`portfolio_items.content`
- [x] 创建 / 更新接受 `content`，私有详情一并返回
- [x] 新增 `GET /api/portfolio/:id`（私有）与 `GET /api/public/portfolio/:id`（公开）
- [x] 公开列表不返回正文

## 三.3 相关链接

- [x] `0009` migration：`portfolio_repos` 改为存完整 `url` + `title`，删 `platform` / `repo_path`
- [x] URL 必须是 http(s) 完整地址，非法返回 422
- [x] 标题留空时后端抓取页面 `<title>`（5s 超时、256KiB 上限、截断 120 字）
- [x] 响应新增只读的 `kind`（github / gogs / link），按域名判断
- [x] 自建 Git 服务统一显示为「Vorin Git」（`utils/portfolio.ts`）

## 三.4 标签页

- [x] 标签页改为只读卡片网格，按引用次数倒序
- [x] 色阶改为相对分档（以当前最大引用数为基准），配色用语义变量与 accent 混色
- [x] 点标签弹出居中窗口展示引用笔记
- [x] `GET /api/tags` 查询前删除 0 引用的标签（回收站里的笔记不算引用）

## 三.5 布局与样式

- [x] 表单与列表页占满详情区宽度，阅读正文仍守 800px
- [x] 中间栏改为内部列表滚动，导航栏与标题栏固定
- [x] 统一隐藏全部滚动条

---

# 四期（v4）

> 文档：`docs/v4/`，入口为 `docs/v4/changes.md`。范围与顺序：**U1 → U2 → U3 → U4**。

## U1 上传基础设施

- [x] `config` 新增 `HAVEN_UPLOAD_DIR`（默认 `./uploads`），目录创建失败拒绝启动
- [x] 新增 `internal/uploads`：文件名服务端生成、扩展名按 MIME 决定、`.part` + rename 保证原子性
- [x] 只接受 png / jpeg / gif / webp，**拒绝 SVG**；单文件上限 10 MiB
- [x] `POST /api/uploads`（登录 + write），返回相对 URL
- [x] `/uploads/*` 静态托管：匿名可访问、长缓存、拒绝 `..`、未命中 404 不回退 SPA
- [x] `httpx` 增加 413 / 415 错误响应
- [x] 部署三件套：`haven.service` 加 `ReadWritePaths`、`deploy.sh` 创建目录并排除 `--reset` 删除、`haven.env.example` 加变量
- [x] 测试：`internal/uploads` 9 条单测 + `cmd/haven` 端到端 1 条

## U2 笔记插图

- [x] 新增 `api/uploads.ts` 上传客户端（`FormData`，不手动设 `Content-Type`），前端预校验类型与大小
- [x] 编辑器粘贴图片改为上传后插入 `![](url)`，不再内嵌 base64——`MarkdownEditor.vue` 的 `imageUploadPlugin`
- [x] 拖拽图片同样走上传
- [x] 阅读态图片样式：最大宽度 100%、圆角、加载失败显示 alt

## U3 文件夹图标

- [x] `folders.MaxIconRunes` 从 16 放宽到 256（本期无 migration）
- [x] 图标面板增加「上传图片」入口，面板聚焦时也可直接粘贴图片
- [x] `icon` 以 `/` 开头时渲染 `<img>`，品牌 key 渲染 SVG，否则按 emoji 渲染（向后兼容）
- [x] 图片加载失败回退默认图标

## U4 图标库

- [x] 集成 simple-icons，在图标面板提供编程语言 / 工具 logo 的搜索与选择（46 个常用图标）
- [x] 按需加载：用 `?raw` 逐个引入，只打进入口 chunk；`NoteListPanel` 体积 22K → 88K


---

# 五期（v5）已完成

> 文档：`docs/v5/`，入口 `docs/v5/changes.md`。私有域新增概览首页。

## H1 统计接口

- [x] 新增 `internal/stats`：`GET /api/stats` 一次返回全部聚合结果
- [x] 只统计当前用户、统一排除回收站
- [x] 字数用 `length(content)`（按字符，不含标题）
- [x] 热力图近半年，按天聚合、按 `count(distinct id)` 计、后端补零
- [x] 最近编辑固定 5 条
- [x] 测试：`cmd/haven/stats_test.go` 8 条

## H2 首页页面

- [x] 四张统计卡片：笔记数、总字数、公开数、本周新建
- [x] 写作热力图：按周分列、按星期分行、五档 accent 混色
- [x] 最近编辑：5 条，点击进笔记详情
- [x] 空账号也显示全部模块（数字为 0），版式不塌

## H3 路由调整

- [x] `/` 改为首页，工作台挪到 `/notes`
- [x] 侧边栏顶部新增「首页」入口（独立于「浏览」分组）
- [x] Logo 点击回到首页
- [x] 所有 `name: 'workbench'` 引用改为新路径后仍正确
- [x] 测试：`src/__tests__/home-route.test.ts` 5 条

---

# 六期（v6）已完成

> 文档：`docs/v6/`，入口为 `docs/v6/changes.md`。范围与顺序：**C3 → C4 → C1 → C2**（C6 独立，随时可做）。

## C3 搜索 type 参数

- [x] `/api/search` 新增 `type`：`title` / `title_content`（默认）
- [x] 不传 `type` 等同于 `title_content`，搜索页行为不变
- [x] 非法 `type` 返回 422
- [x] 测试：`cmd/haven` 的 `TestSearchType`

## C4 标题索引

- [x] `0010_notes_title_trgm`：`notes.title` 的 GIN trigram 索引
- [x] 与现有 `idx_notes_search_trgm` 并存

## C1 命令面板

- [x] `Cmd/Ctrl+K` toggle 打开与关闭，输入框自动聚焦、内容清空
- [x] 前缀命令：`s`+空格 搜笔记、`n`+空格 带标题新建、`d` 回车跳仪表盘、`w` 回车跳工作台
- [x] 无前缀时按命令名匹配，匹配不到显示「没有匹配的命令」
- [x] 搜索调 `GET /api/search?type=title&limit=20`，只取 `notes`，忽略 `tags`
- [x] 防抖 150ms，带请求序号做竞态保护
- [x] `↑`/`↓` 移动、`Enter` 打开、`Esc` 关闭、点击外部关闭
- [x] 视觉：居中弹窗，宽度 `min(560px, 视口-32px)`，距顶约 15%
- [x] 测试：`src/__tests__/command-palette.test.ts`，6 条前缀解析用例

## C2 快捷键

- [x] `Cmd/Ctrl+S`：取消自动保存计时器并立即保存，**仅编辑页**
- [x] `Cmd/Ctrl+N`：新建笔记，全站
- [x] 全部 `preventDefault()`，劫持浏览器默认行为
- [x] 焦点在 `input` / `textarea` / 可编辑区时，不拦截 `Cmd+S` / `Cmd+N`
- [x] 公开域不启用任何快捷键（快捷键只挂在私有域布局上）
- [x] 测试：编辑页与非编辑页的行为差异、输入框内不拦截
- [x] 修正：编辑器正文（`.ProseMirror`）算 `editor` 而不是 `field`，`Cmd+S` 在写笔记时也能拦截并保存；监听改到**捕获阶段**，抢在编辑器自身处理之前
- [x] 测试：`src/__tests__/shortcuts.test.ts` 6 条（editor / field / other 三类判定）

## C6 任务列表复选框

> 文档：`docs/v6/frontend/frontend.md` 第五节、`docs/v6/conventions.md` 第一节第 6/7 条。

- [x] 引入 `@milkdown/components@7.23.0`（与现有 Milkdown 版本一致），用 `listItemBlockComponent` 渲染列表项
- [x] `listItemBlockConfig.renderLabel` 改为自绘方块，不引入 Crepe 主题与图标
- [x] 编辑态点方块切换 `checked`：`mousedown` 接管、`preventDefault`，光标与滚动不动
- [x] 点在正文、拖选文字跨过方块时都不勾选
- [x] 普通无序 / 有序列表的符号与序号显示不变
- [x] 阅读态（公开笔记、作品集、回收站预览）把 `<input type="checkbox">` 换成只读方块，修复方框原本被 DOMPurify 过滤掉的问题
- [x] 样式：15px 方块、悬停变 accent、勾选实心 + 白对勾、已勾选正文降为 `var(--label-2)`
- [x] 测试：`src/__tests__/task-list.test.ts`（8 条：方块生成、input 替换、属性顺序、编辑态命中判定）+ `markdown.test.ts` 3 条阅读态用例

## C7 代码块复制

> 文档：`docs/v6/frontend/frontend.md` 第六节（复制）、第七节（输入法全角陷阱）。

- [x] 新增 `utils/clipboard.ts`：`copyText`（Clipboard API → `execCommand` 回退 → 静默 false）、`flashCopyState`、`installCodeCopyHandler`
- [x] 编辑态：`codeCopyPlugin` 用 widget decoration 在 `<pre>` 右上角挂按钮，`contenteditable=false`，不进 Markdown
- [x] 阅读态：`renderMarkdown` 的 code renderer 输出 `.code-copy` 按钮；三个阅读视图（公开笔记 / 作品集详情 / 回收站预览）通过 `useCodeCopy` 委托接线
- [x] 复制内容只取 `<pre>` / 代码节点的纯文本，不含语言名
- [x] 失败静默降级：按钮显示「复制失败」，不弹 alert、不写笔记错误区
- [x] 反馈 1.5 秒后复原，连点只重置计时
- [x] 样式：按钮右上角、悬停变 `var(--fill-2)`；语言标签移到左上
- [x] `v6/conventions.md` 第一节第 7 条同步放行「代码块复制按钮」
- [x] 测试：`src/__tests__/code-copy.test.ts` 13 条

## C8 代码高亮语言

> 文档：`docs/v6/frontend/frontend.md` 第八节。

- [x] 修编辑态漏掉 `normalizeLanguage`：此前 ```` ```js ```` / ```` ```sh ```` 在阅读态有颜色、编辑态没有
- [x] 补齐别名表：`jsx` `mjs` `cjs` `tsx` `mts` `zsh` `ksh` `py3` `rs` `cc` `cxx` `cs` `objc` `objective-c` `yml` `conf` `cfg` `properties` `html`/`htm`/`xhtml`/`svg`→`xml` `md` `text`/`txt`
- [x] 全角字母归一并忽略大小写（`ｇｏ` → `go`）
- [x] **未知语言改为纯文本**，删掉 `highlightAuto` 回退——此前 ```` ```dockerfile ```` 会被猜成别的语言，表现为「有的语言能高亮、有的不能」
- [x] 新增 `displayLanguage`：`html` 的标签仍显示 `html`，不显示成 `xml`
- [x] 支持范围写入文档第八节 8.1：主力 / Shell / C 系 / Web / 配置 / 其他，含 YAML、INI（`conf`/`cfg`/`properties`）、TOML
- [x] 额外注册 26 种常见语言（不换 full 构建）：`dockerfile` `nginx` `powershell` `haskell` `elixir` `erlang` `scala` `dart` `protobuf` `latex` `julia` `groovy` `vim` `cmake` `gradle` `clojure` `ocaml` `elm` `lisp` `scheme` `matlab` `fortran` `verilog` `nim` `crystal` `fsharp`，合计 62 种
- [x] 对应别名：`docker` `docker-compose`/`compose` `ps1`/`pwsh` `hs` `ex`/`exs` `erl` `clj`/`cljs` `ml` `fs`/`fsx` `jl` `tex` `proto` `gql` `sv`/`vh`/`svh` `cr`
- [x] 本地实现 Caddyfile 语法（highlight.js 无此语言包）：`utils/languages/caddyfile.ts`，识别注释 / 花括号 / 指令与站点地址 / 多地址行 / `{$ENV}` / `{placeholder}` / 字符串 / 字面量 / 端口
- [x] 测试：`src/__tests__/highlight.test.ts` 扩充为 22 条

---

# 一期（v1，已归档）

> 以下条目为已完成存档，**不再修改**，仅作历史参考。详细说明见 `docs/v1/`。

当前状态（归档时）：前后端功能均已完成（第 0–6 章），`deploy/` 已落地。

## 0. 清理脚手架

- [x] `backend/cmd/haven/main.go` 重写为读环境变量的入口（见 `architecture.md` 第四节、5.2/5.3）：删除硬编码 `:8080`，改用 `HAVEN_LISTEN_ADDR`，接 `log/slog`
- [x] 删除 `frontend/src/components/HelloWorld.vue` 与模板样式（`style.css` 里的 demo 变量、`src/assets/{vue.svg,vite.svg,hero.png}`）
- [x] 删除 `frontend/README.md`（Vite 模板说明）与 `frontend/public/icons.svg` 等模板残留，保留 `favicon.svg` 或替换
- [x] `frontend/index.html`：`lang="zh-CN"`，标题改为 Haven
- [x] 接入 `vue-router`（History 模式）与 `pinia` 到 `main.ts`
- [x] 根目录 `.gitignore`
- [x] 根目录 `AGENTS.md`：写文档驱动规则、Git 规范、TODO 边界、技术栈锁定
- [x] 根目录 `opencode.json`：`instructions` 加载常驻文档（二期已扩为 `docs/README.md`、`docs/v1/conventions.md`、`docs/v1/overview.md`、`docs/v2/changes.md`）

## 1. 配置与数据库基座

- [x] `internal/config`：读取并校验全部 `HAVEN_*` 变量，缺必填项拒绝启动；常量（cookie 名、有效期、bcrypt cost）写死不走配置
- [x] `internal/db`：`database/sql` + `pgx` 连接池，启动时 ping
- [x] `migrations/0001_init.up.sql` / `.down.sql`：按 `data-model.md` 依赖顺序建表，含全部索引与 CHECK
- [x] migration 要求 `CREATE EXTENSION IF NOT EXISTS pg_trgm;`；确认 `gen_random_uuid()` 可用
- [x] 初始化脚本：创建唯一用户（bcrypt cost 12）——**不暴露注册接口**（`backend/cmd/haven-init-user`）
- [x] 后端启动**不**跑 migration（由脚本执行）；执行方式见 `deploy/migrate.sh`

## 2. 鉴权核心（`internal/auth`，按 `auth.md`）

- [x] 凭证生成与哈希工具：32 字节随机 + base64url，落库只存 SHA-256
- [x] 身份识别（auth.md 6.1）：`Authorization: Bearer` 优先于 cookie；`sessions` / `tokens` 两张表；`pending_logins` 不参与
- [x] 授权中间件（auth.md 6.2–6.4）：`anonymous_ok` / `login_required` / `write` / `totp_verified` 四档，并把可见性条件注入 context
- [x] cookie 下发：`haven_session` / `haven_trusted_device`，`HttpOnly`、`SameSite=Lax`、`Domain=HAVEN_COOKIE_DOMAIN`、`Secure` 跟随 `HAVEN_COOKIE_SECURE`
- [x] 登录两步：账密 → （未启用 TOTP / 授信设备有效则直接建会话）→ 否则 `pending_logins` + `temp_token`（5 分钟）
- [x] 每次请求更新 `sessions.last_used_at`，不延长 `expires_at`
- [x] TOTP：setup 不落库、verify 通过才落库并置 `totp_enabled`；disable 同时删除该用户全部授信设备
- [x] 改密码：同事务内删全部 `sessions` + `trusted_devices`，**不删** `tokens`，当前会话也失效
- [x] bcrypt cost 12；密码 ≥12 位且不能与旧密码相同

> 补充实现：会话/授信设备/Token 的 `internal/auth` 业务与 handler、`internal/httpx` 统一错误响应、`cmd/haven` 路由装配。
> 会话「是否通过过 TOTP」用 token 后缀 `:totp` 承载，与 `pending_logins` 的 `trust_device` 后缀手法一致。

## 3. 审计（`internal/audit`，按 `audit.md`）

- [x] `audit_events` 写入器：只追加；`actor_user_id` 可为 NULL，`actor_username` 存快照
- [x] 实现第十三类事件（login_success/login_failure/logout/totp_bound/totp_disabled/password_changed/session_revoked/trusted_device_added|revoked/token_created|revoked/note_published|unpublished）
- [x] 写入时机：业务成功后、响应前；**失败只打错误日志，不影响业务结果**
- [x] 笔记 CRUD 不写审计；不记录笔记内容、密码、Token 明文、TOTP secret

> `note_published` / `note_unpublished` 已在第 4 章接入 `notes.Handler` 的钩子（`audit.UseNoteHooks`）。

### 6.1 追加：Markdown 编辑（用户后续要求，2026-10-28）

- [x] 正文以 Markdown 原文存储（`notes.content` 不变，后端零改动）
- [x] 阅读态渲染：`marked` + `DOMPurify`（`utils/markdown.ts`），过滤脚本与内联事件
- [x] 所见即所得编辑器：Milkdown 7.23（MIT），`components/MarkdownEditor.vue`，路由懒加载
- [x] 新建笔记改为直接进空白编辑页（无弹窗），首次保存才创建
- [x] 保存前 `sync()` 编辑器内容，避免异步回写导致的空正文
- [x] 离开页面有未保存改动时确认

> 注意：`docs/v1/` 里 `content` 字段仍写作「正文 text」，未声明 Markdown。

## 4. 领域接口（按 `api.md` 逐条实现）

- [x] `/api/me`（11.1）：匿名/会话/Token 三种响应
- [x] 认证 `/api/auth`（二）：login、login/totp、logout、totp/setup|verify|disable、password
- [x] 会话 `/api/sessions`（三）：列表带 `is_current`；禁止撤销当前会话（422）；Token 访问 403
- [x] 授信设备 `/api/trusted-devices`（四）：**只读 + 删除，不提供 POST**
- [x] Token `/api/tokens`（五）：创建仅返回一次明文；撤销写 `revoked_at` 不删记录；需 TOTP
- [x] 笔记私有 `/api/notes`（六）：列表 `updated_at DESC` + `content_preview`（rune 截 200 + `…`）；创建不收 `visibility`；`tag_ids` 全量替换
- [x] publish / unpublish：`published_at` 首次写入、撤回保留；重复操作 409
- [x] 笔记公开 `/api/public/notes`（七）：`published_at DESC`，不可见统一 404
- [x] 标签 `/api/tags`（八）：`lower(name)` 唯一 → 409；无重命名接口；级联删除关联
- [x] 搜索（九）：`/api/search` 笔记查 `notes.search_text ILIKE '%q%'`、标签查 `tags.name ILIKE '%q%'`，返回 `{notes, tags}` 两块；`/api/public/search` 只查公开笔记的 `search_text`，不返回标签列表
- [x] 作品集 `/api/public/portfolio` + `/api/portfolio/*`（十）：`url` 由后端拼接（Gogs 用 `HAVEN_GOGS_BASE_URL`，GitHub 固定）；主链接唯一
- [x] `internal/httpx`：统一错误响应（`error`/`message`/可选 `fields`）+ 统一分页（`limit` 默认 20 上限 100）
- [x] 响应字段全 `snake_case`；列表空值返回 `{"items": [], "total": 0}`
- [x] 跨用户访问一律 404；read Token 写操作 403；凭证类操作对任何 Token 一律 403
- [x] 文件夹 `/api/folders`：树状目录、收件箱、图标、拖拽排序

## 5. 静态托管

- [x] `r.Static` 托管 `/assets`（长缓存），`NoRoute` 兜底 `index.html`；`HAVEN_FRONTEND_DIR`
- [x] 确认 `/api/*` 不被 SPA 兜底吞掉

## 6. 前端（按 `frontend.md`）

- [x] `src/api/` 按领域拆文件（auth/notes/tags/search/portfolio/sessions/devices/tokens/me/folders）+ 统一 `ApiError`；路径写相对 `/api/...`
- [x] `auth` store：启动调 `GET /api/me`；401 统一清空并跳 `/login`；403 只提示不跳转
- [x] 按 `window.location.hostname` 选择公开域/私有域路由表（同一份构建）
- [x] router guard：除 `/login` 外全部需登录，支持 `?redirect=`
- [x] 公开域页面：`/`、`/notes/:id`、`/search?q=`、`/portfolio`；**无登录入口、无后台链接**
- [x] 私有域页面：`/login`（含 TOTP 第二步，`temp_token` 只存内存）、`/`、`/notes/:id`、`/notes/new`、`/search`、`/tags`、`/portfolio`、`/settings/*`
- [x] `/settings/tokens` 遇 403 时引导去 `/settings/security` 完成 TOTP，不登出
- [x] 公共组件：`NoteListItem`、`TagBadge`、`TagDropdown`、`SearchBar`、`LoginForm`、`TotpForm`、`MarkdownEditor` 等
- [x] 中文界面；不做深色模式切换、不做 PWA、不做多语言
- [x] 本地开发代理 `/api` 到后端（`vite.config.ts`）

## 7. 验证与部署

- [x] `go vet ./...`、`go test ./...` 全绿；至少覆盖：可见性矩阵、Token scope、跨用户 404、publish 幂等性
- [x] 全量路由鉴权不变量测试（2026-10-30）：`cmd/haven/route_auth_test.go` 遍历全部 `/api` 路由，白名单外匿名一律要求 401，非 GET 私有路由对 read Token 一律要求 403
- [x] `pnpm build`（含 `vue-tsc -b`）通过
- [x] 手工冒烟：匿名 → 公开列表/详情/搜索/作品集；登录 → TOTP → 笔记 CRUD → publish → 退出
- [x] `deploy/`：构建脚本 + systemd unit + migration 执行
- [x] 部署形态待定项（`architecture.md` 第八节）：端口、HTTPS/反代、`pg_dump` 备份定时任务
- [x] 更新根 `README.md` 的「快速开始」占位

## 8. 明确不做（防止误开工）

- ✗ TUI / Neovim 插件（二期确认二至三期都不做）
- ✗ LLM 实现与 SDK 依赖（`internal/llm` 只保留接口，二期不做，留待三期后再议）
- ✗ Docker / K8s、ORM / sqlc、SSR、多用户注册、审计查询界面

---

## 待确认：一期遗留的三条状态

以下三条一期条目**实测已满足**，但尚未勾选，需要人类确认后再改：

| 行 | 条目 | 实测情况 |
|---|---|---|
| 7 章 | `go vet ./...`、`go test ./...` 全绿 | 2026-10-31 实测：`go build`、`go vet` 通过；设置 `HAVEN_TEST_DB_DSN` 后 `go test ./...` 全绿（约 140s） |
| 7 章 | `pnpm build`（含 `vue-tsc -b`）通过 | 2026-10-31 实测通过 |
| 7 章 | 更新根 `README.md` 的「快速开始」占位 | 2026-10-31 已改（含「当前版本」节与路径修正） |

另：7 章「手工冒烟」属于人工验证，无法由 AI 判定。
