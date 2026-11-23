# AGENTS.md

Haven 是单用户、自托管的个人知识中台：Spring Boot 4 + MyBatis-Plus + PostgreSQL 后端，Vue 3 + TypeScript + Vite 前端。前端构建产物会复制进后端，最终只发布一个 jar。

## 先读什么

- `docs/README.md` 是权威设计文档索引；根目录与子项目 `README.md` 只讲怎么跑。
- 改后端前加载 `.opencode/skills/spring-boot-java/SKILL.md`；改前端前加载 `.opencode/skills/vue3-frontend/SKILL.md`。两者是目标规范，不是现状描述。
- 细化规则看 `docs/conventions.md`（风格）、`docs/testing.md`（测试）、`docs/data-model.md`（表结构）、`docs/auth.md`（认证）、`docs/versioning.md`（版本）。
- 文档与代码/脚本冲突时，以代码/脚本为准，并顺手修文档。

## 常用命令

> **AI 代理不要跑全量门禁和打包。** `./scripts/test.sh all|backend|frontend`、`./scripts/test.sh e2e`、
> `./scripts/build.sh all|frontend|backend` 一律由人工执行；代理只写代码和文档，把「要跑什么」告诉用户。
> 需要自检时最多做**针对性**单测：`pnpm exec vue-tsc -b`、单个 `vitest run <file>`、单个 `playwright test <spec>`。

| 目的 | 命令 |
| --- | --- |
| 全量门禁 | `./scripts/test.sh all`（含 E2E，会先构建 jar） |
| 只跑后端门禁 | `./scripts/test.sh backend`（spotless:check + checkstyle + tests） |
| 只跑前端门禁 | `./scripts/test.sh frontend`（**vue-tsc + Vitest + Playwright E2E**） |
| 只跑 E2E | `./scripts/test.sh e2e`（会先构建 jar） |
| 构建可部署 jar | `./scripts/build.sh all` |
| 只构建前端并复制到 static | `./scripts/build.sh frontend` |
| 只打后端 jar | `./scripts/build.sh backend` |
| 本地启动 | `./scripts/run.sh`（后端同源托管已构建的前端） |
| 版本号 | `./scripts/version.sh check` / `sync` / `set X` |

单测：

```bash
cd backend && ./mvnw test -Dtest=NotesServiceImplTest
cd backend && ./mvnw test -Dtest=NotesServiceImplTest#methodName
cd frontend && pnpm exec vue-tsc -b                          # 只做类型检查
cd frontend && pnpm exec vitest run src/__tests__/frontend.test.ts
cd frontend && pnpm exec playwright test e2e/auth.spec.ts     # 需人工已构建 jar；代理不要自己跑 build.sh
```

注意：

- `./mvnw test` 会跑 Checkstyle（validate 阶段），但**不会**跑 Spotless（verify 阶段）；完整门禁用 `./mvnw verify` 或 `test.sh backend`。
- `./scripts/test.sh frontend` 实际包含 E2E，比 README 写的多；只跑 Vitest 用 `cd frontend && pnpm test`。
- 没有 CI workflow；`scripts/test.sh` 就是唯一门禁（人工执行）。前端没有 ESLint/Prettier；后端格式由 Spotless + palantir-java-format 强制。
- 格式化：`cd backend && ./mvnw spotless:apply`（代理可以跑，属于改写文件而非验证）。

## 环境与前置条件

- JDK 21、Node 20.19+/22.12+、pnpm、PostgreSQL 14+。
- 后端测试和 E2E 都要求 `pg_trgm` 扩展已装在 `public` schema。
- 默认开发库：`dev_db` / `dev` / `123456`；用 `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` 覆盖。
- E2E 额外需要 PATH 里有 `psql`，并且已有构建好的 jar；它跑打包后的 jar（不是 Vite），端口 `18099`，schema `haven_e2e`。
- 首次 E2E：`pnpm --dir frontend exec playwright install chromium`（镜像已在 `frontend/.npmrc` 配好）。
- `backend/src/main/resources/static/` 被 gitignore；为空时 `run.sh` 会警告，页面 404。
- 项目没有注册接口；本地账号直接写 `users` 表，BCrypt cost 12。
- prod profile 的 Sa-Token Cookie 是 `Secure`；本地 http 调试用 dev profile（默认）。
- Vite 固定 5173，`/api` 默认代理到 8080；`HAVEN_API_TARGET` 改后端地址，`HAVEN_DEV_PROXY=1` 用于 HTTPS 反代/HMR。

## 结构与边界

- 后端按领域分包：`controller → service → mapper → entity`，对外 DTO 用 record。`BackendApplication.@MapperScan` 是手工清单，新增领域别忘了加。
- **表按模块分 schema**（V16 起）：`note` / `issue` / `ledger` 各管自己的表，`public` 只留 `users` / `tokens` / `sa_token` / `pending_totp` / `trusted_devices` / `audit_events` / `login_logs`。entity 的 `@TableName` 和 Mapper 手写 SQL 都必须带 schema 前缀。
- 前端所有 HTTP 只走 `src/api/client.ts`；资源模块在 `src/api/*`。页面在 `views/private/`（PC）与 `views/mobile/`（`/m/`）。
- **`/m/` 是同一份产物里的另一套路由树**（`router/mobile.ts`），路径决定入口、不做 UA 嗅探；与 PC 共用 `api/*` 和 `composables/*`，布局与页面独立。
- 构建链：`frontend/dist` → `backend/src/main/resources/static/` → `haven-<version>.jar`。`build.sh all` 会先清空 `static/`，避免旧 hash 文件残留。
- 后端对非 `/api`、非 `/uploads` 路径回退 `index.html`；API 错误 `{error,message,fields?}`，列表 `{items,total}`，JSON 字段 `snake_case`。
- 新增匿名端点要在 `SaTokenConfigure.excludePathPatterns` 放行，否则 `AuthInterceptor` 会拦成 401；目前只有 `/api/app-config`（占位，只返回版本号）是匿名的。
- **不再有域名感知**：一张路由表、一份构建产物，部署在什么域名由反向代理决定。没有 `private_hosts` / `VITE_PRIVATE_HOST` / `HAVEN_PRIVATE_HOSTS`，别再加回来。

## 容易踩的规则

- **Jackson 3 的 SNAKE_CASE 双向生效**：请求体也必须 `snake_case`，不要在 `client.ts` 加 camelCase 转换。`RequestBodyContractTest` 和 `frontend/src/__tests__/request-body-contract.test.ts` 守着这条；新增 `@RequestBody` DTO 必须补契约用例。
- **MyBatis-Plus `updateById` 跳过 null 字段**：清空字段要用 `LambdaUpdateWrapper.set(field, null)`。`NullFieldUpdateTest` 守着。
- **`@Transactional(readOnly = true)` 只能给纯查询**：内部任何写库（审计、授信设备 `last_used_at`）都会 500 或静默失败。`ReadOnlyTransactionTest` 守着。
- **时间**：注入 `Clock`，禁止 `OffsetDateTime.now()`；业务时区是 `haven.time-zone`。
- **金额**：整数分（`amountCents` / `amount_cents`），精确转换，前端负责格式化。
- **鉴权**：双通道——Sa-Token Cookie `havenToken` 和 `Authorization: Bearer <token>`。身份用 `AuthInterceptor.requireUserId(request)` 取，禁止信任 body/query 里的 `userId`；按 ID 访问资源必须校验归属，越权统一 404。端点权限用 `@RequireAccess`（`READ/WRITE/SESSION/SESSION_TOTP`）。
- **单实例假设**：Sa-Token 会话与登录失败计数都在内存；不要假设多实例安全。
- **Flyway**：已执行迁移不可改；新增 `V<n>__snake_case.sql`，不写 `BEGIN/COMMIT`，必须能在空库跑通。
- **前端**：只用 `<script setup lang="ts">`，禁止 `any`；API 调用只在 `src/api`；`v-html` 只能渲染 DOMPurify 清洗过的内容；`pnpm build` 会跑 `vue-tsc`。
- **`/m/` 下所有 `fixed` 浮层必须 `<Teleport to="body">`**：`.m-main` 的 `overflow-y: auto` 会创建层叠上下文，内部浮层的 `z-index` 出不去，会被底部 tab 压住（踩过三次）。
- **别用函数式 `:ref` 绑原生事件**：每次重渲染会先传 `null` 再传新节点，配了 `attach` 里 `detach()` 的自定义手势会被摘掉。用模板 `ref` + `onMounted`（常驻）或 `watch(可见性)` + `nextTick`（条件渲染）。
- **区间比较用 `isEqual` 不用 `equals`**：`OffsetDateTime.equals` 会比较偏移量，前端传 UTC、后端构造 +08:00 时同一瞬间也不相等（曾导致一周变 8 天、一季度变 4 个月）。
- **版本号不是标准 SemVer**：只有新增“独立顶级导航 + 自己的表 + 自己的 CRUD”的全新领域才升 MAJOR。`VERSION` 是唯一来源，`version.sh` 同步 `pom.xml` `<revision>` 与 `package.json`，不要手改。

## 测试隔离

- 后端测试不碰 `dev_db`：每轮 `DROP + CREATE` 独立库 `haven_test_db`（账号需 `CREATEDB`），Flyway 从空库完整迁移；`-Dhaven.test.mode=container` 或 `HAVEN_TEST_MODE=container` 走 Testcontainers；连接与库名可用 `TEST_DB_*` 覆盖。
- **别再改回「临时 schema + search_path」**：V16 起模块 schema 是 `note`/`issue`/`ledger`，而 PostgreSQL schema 不能嵌套，`CREATE SCHEMA note` 会落到库顶层污染开发库。
- E2E 串行（`workers: 1`），每次重建 `haven_e2e`，账号 `e2e-user` / `e2e-password-123`。造数据走 `e2e/api.ts`，断言走界面。
- Playwright 的 `count()`、`inputValue()`、`boundingBox()`、`evaluate()` 不会自动等待；先断言可见再取值。

## 登录日志

- 登录成功 / 失败 / 动态码失败 / 登出写 `login_logs`，**不写** `audit_events`（后者只留非登录安全事件）。
- 失败日志必须走 `LoginLogRecorder`（`REQUIRES_NEW`）：登录失败随后抛 401，共用事务会把日志一起回滚。`LoginLogsTest` 用 `Propagation.NOT_SUPPORTED` 守着这条。
- 查询接口 `GET /api/auth/login-logs` 只给会话（`@RequireAccess(SESSION)`），永远不返回 `session_hash`。

## 文档漂移

- `docs/testing.md` 和 README 把 `test.sh frontend` 写成 vue-tsc + Vitest，但脚本还会跑 E2E；以脚本为准。
