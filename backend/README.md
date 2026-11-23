# Haven Backend

Haven 的后端：Spring Boot REST API、PostgreSQL 持久化、Flyway 迁移，以及前端单页应用的静态托管。

**设计文档在 [`../docs/`](../docs/README.md)**——本文件只讲怎么跑、怎么配、有哪些接口。

- 统一前缀 `/api`，JSON 字段 `snake_case`
- 浏览器会话（Sa-Token）与 API Token（`Bearer`）双通道认证
- 列表 `{ items, total }`，错误 `{ error, message, fields? }`
- 生产环境与前端同源部署，非 API 路径回退 `index.html`

> **版本号规则与标准 SemVer 不同**：只有新增"全新功能领域"才升 MAJOR。
> 见 [`../docs/versioning.md`](../docs/versioning.md)。版本号以根目录 `VERSION` 文件为准。

## 技术栈

| 组件 | 版本 | 说明 |
| --- | --- | --- |
| Java | 21 | record、模式匹配、`Math.clamp` |
| Spring Boot | 4.1.2 | Web MVC、JDBC、Validation、Actuator |
| MyBatis-Plus | 3.5.18 | 单表 CRUD + 自定义聚合 SQL |
| PostgreSQL | 14+ | 搜索依赖 `pg_trgm` |
| Flyway | 随 Boot | 迁移脚本 `src/main/resources/db/migration` |
| Sa-Token | 1.46.0 | **会话存内存**（见下方"已知限制"） |
| BCrypt | `at.favre.lib` | cost = 12 |
| Testcontainers | 1.21.4 | 可选，仅在 `-Dhaven.test.mode=container` 时使用 |

## 目录结构

```text
src/main/java/com/haven/backend/
├── BackendApplication.java       # 启动类，@MapperScan 注册各领域 mapper
├── audit/                        # 审计事件（AuditRecorder + 事件枚举）
├── auth/
│   ├── LoginLogEventType.java    # 登录日志事件枚举
│   ├── config/                   # AuthInterceptor 注册 + 匿名路径放行
│   ├── controller/               # 登录、TOTP、会话、授信设备、API Token、登录日志
│   ├── dto/                      # AuthDtos / LoginLogDtos + 各请求 record
│   ├── entity/                   # Users、Tokens、SaToken、PendingTotp、TrustedDevices、AuditEvents、LoginLogs
│   ├── interceptor/              # AuthInterceptor + RequiredAccess + @RequireAccess
│   ├── mapper/
│   ├── service/ + impl/          # AuthService、AuthSessionOpener、LoginAttemptLimiter、LoginLogRecorder 等
│   └── util/                     # ApiTokenUtil、TotpUtil
├── config/                       # ClockConfig、WebConfig、MybatisPlusConfig
├── dto/                          # ApiError、PageResponse
├── exception/                    # BizException、GlobalExceptionHandler
├── issue/                        # controller / dto / entity / mapper / service
├── ledger/
│   ├── controller/
│   ├── dto/                      # LedgerDtos（含全部响应 record）
│   ├── entity/                   # LedgerEntries、LedgerTypes、LedgerCategories
│   ├── mapper/
│   └── service/                  # LedgerTextParser、LedgerClassifier、LedgerStatsCalculator
├── note/
│   ├── controller/               # 笔记、版本、文件夹、标签、搜索、上传
│   ├── dto/                      # NoteDtos、FolderDtos、各请求 record
│   ├── entity/                   # Notes、NoteVersions、Folders、Tags、NoteTags
│   ├── mapper/
│   └── service/ + impl/
├── stats/                        # controller / dto / service（只读聚合）
├── system/                       # 健康检查、运行时前端配置（只返回版本号）
└── typehandler/                  # UuidTypeHandler、UuidListTypeHandler
```

## 快速开始

### 环境要求

- JDK 21+
- PostgreSQL 14+，账号需有 `CREATE EXTENSION pg_trgm` 权限

### 1. 准备数据库

`application-dev.yaml` 的默认值：

```text
jdbc:postgresql://127.0.0.1:5432/dev_db
用户名：dev
密码：123456
```

```bash
psql -U postgres -c "CREATE USER dev WITH PASSWORD '123456';"
psql -U postgres -c "CREATE DATABASE dev_db OWNER dev;"
psql -U postgres -d dev_db -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
```

这些默认值只是**本地开发**用，可被 `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` 覆盖：

```bash
DB_URL=jdbc:postgresql://127.0.0.1:5432/dev_db \
DB_USERNAME=dev DB_PASSWORD=123456 \
./mvnw spring-boot:run
```

### 2. 启动

推荐用仓库根目录的脚本（会检查静态资源是否就绪）：

```bash
./scripts/run.sh
```

或手动：

```bash
cd backend
./mvnw spring-boot:run
```

默认监听 `8080`，首次启动 Flyway 会执行 V1–V15 全部迁移。

```bash
curl http://127.0.0.1:8080/api/health
# {"status":"ok","version":"<版本>"}
```

### 3. 创建用户

不提供注册接口，直接写库。密码是 BCrypt（cost 12）哈希，可以用 `at.favre.lib.crypto.bcrypt.BCrypt` 生成。

```sql
INSERT INTO users (username, password_hash)
VALUES ('admin', '$2a$12$...');
```

## 配置

### profile 与文件

| 文件 | 内容 |
| --- | --- |
| `application.yaml` | 公共配置（含 Sa-Token 与 Cookie 安全属性），profile 由 `SPRING_PROFILES_ACTIVE` 决定，默认 `dev` |
| `application-dev.yaml` | 数据源默认值、上传、Actuator 详情、登录限流阈值 |
| `application-prod.yaml` | 生产模板，全部走环境变量 |

### 主要配置项

| 配置 | 默认 | 说明 |
| --- | --- | --- |
| `spring.datasource.url/username/password` | `${DB_URL:...}` / `${DB_USERNAME:dev}` / `${DB_PASSWORD:123456}` | dev 有默认值，prod 无默认值（缺失即启动失败） |
| `spring.servlet.multipart.max-file-size` | `10MB` | 单文件上限 |
| `haven.totp.issuer` | `Haven` | 动态码发行方 |
| `haven.upload-dir` | `uploads` | 上传根目录 |
| `haven.time-zone` | 空（取 JVM 时区） | 业务时区，影响热力图日界与月度汇总 |
| `haven.auth.login-max-attempts` | `5` | 密码失败上限 |
| `haven.auth.login-window-minutes` | `15` | 失败计数窗口 |
| `haven.auth.totp-max-attempts` | `5` | 动态码失败上限 |
| `sa-token.token-name` | `havenToken` | 会话 Cookie 名 |
| `sa-token.timeout` | `604800` | 会话有效期（秒） |
| `sa-token.active-timeout` | `86400` | 无操作超时（秒） |
| `sa-token.cookie.http-only` | `true` | 禁止 JS 读取 |
| `sa-token.cookie.secure` | `true`（dev 覆盖为 `false`） | 仅 HTTPS 传输 |
| `sa-token.cookie.same-site` | `Lax` | CSRF 缓解 |
| `management.endpoint.health.show-details` | dev `always` / prod `never` | Actuator 详情 |

### 环境变量

| 变量 | 说明 |
| --- | --- |
| `SPRING_PROFILES_ACTIVE` | `dev` / `prod` |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | 数据源 |
| `HAVEN_UPLOAD_DIR` | 上传目录 |
| `HAVEN_TOTP_ISSUER` | 动态码发行方 |
| `HAVEN_TIME_ZONE` | 业务时区（如 `Asia/Shanghai`） |
| `HAVEN_AUTH_LOGIN_MAX_ATTEMPTS` / `..._WINDOW_MINUTES` / `HAVEN_AUTH_TOTP_MAX_ATTEMPTS` | 限流阈值 |
| `LOG_PATH` | prod 日志目录 |

> Sa-Token 配置放在 `application.yaml`（不在 dev 里），切换 profile 不会丢。

> 没有域名相关配置：一张路由表、一份构建产物，部署在什么域名由反向代理决定。

## 认证与安全

### 双通道

`AuthInterceptor` 拦截 `/api/**`：

1. `Authorization: Bearer haven_ro_xxx` / `haven_rw_xxx` → 校验哈希、撤销状态、过期时间，节流刷新 `last_used_at`
2. 否则回退 Sa-Token 会话（Cookie `havenToken`）

认证后把 `auth_userId` / `auth_scope` / `auth_type` / `auth_totpVerified` 写进 request attribute，
Controller 用 `AuthInterceptor.requireUserId(request)` 读取。

### 授权级别（端点声明）

```java
@RequireAccess(RequiredAccess.WRITE)
```

| 级别 | 含义 |
| --- | --- |
| `READ` | 有身份即可（GET 默认） |
| `WRITE` | 需要 `read_write` Token 或会话（非 GET 默认） |
| `SESSION` | 仅浏览器会话，API Token 403 |
| `SESSION_TOTP` | 会话且已过动态码 |

注解优先，没有注解时按 HTTP 方法兜底。**不要**靠"GET 就安全"来设计——会写数据的 GET 必须显式标 `WRITE`。

### 登录流程

1. `POST /api/auth/login` 校验账密；失败计数 +1，超限 429
2. 未启用 TOTP 或设备已授信 → 直接建会话，`totpRequired: false`
3. 启用 TOTP 且设备未授信 → 写 `pending_totp`（5 分钟），返回 `totpRequired: true` + `tempToken`
4. `POST /api/auth/login/totp` 校验动态码，通过后建会话
5. 勾选信任设备 → 写 30 天 HttpOnly Cookie
6. `POST /api/auth/logout` 写登出日志后注销会话

登录成功 / 失败 / 动态码失败 / 登出都写 `login_logs`（`LoginLogRecorder` 用 `REQUIRES_NEW`，登录失败抛 401 也不会把日志一起回滚）；这些不进 `audit_events`，后者只留非登录安全事件。

### 改密的影响面

`POST /api/auth/password`（要求 `SESSION_TOTP`）成功后：

- 撤销全部授信设备
- 撤销全部 API Token（写 `revoked_at`）
- 踢掉全部 Sa-Token 会话（事务提交后执行）

### 匿名可访问的路径

```
/api/health
/api/auth/login
/api/auth/login/totp
/api/app-config
/api/me          ← 在拦截器里按"可选认证"处理，无凭证返回 anonymous
/uploads/**      ← 不在 /api 前缀下，由 UploadsStaticController 直接托管
```

放行列表见 `auth/config/SaTokenConfigure.java`；新增匿名端点必须加进去，否则会被 `AuthInterceptor` 拦成 401。

## 数据库

### 迁移

| 版本 | 内容 |
| --- | --- |
| V1 | 全部基础表 |
| V2 | 授信设备 |
| V3 | 删除 `issues.parent_id` |
| V4 | 记账三表 |
| V5 | 支出默认别名（仅开发账号） |
| V6 | 收入分类白名单 |
| V7 | `folders.parent_id` 级联改 `SET NULL` |
| V8 | 版本表加 `updated_at` / `window_started_at` |
| V9 | `portfolio_items.is_public`（默认 false） |
| V10 | 支出新增「还款」分类 |
| V11 | 记账三表补指向 `users` 的外键 |
| V12 | 支出新增「Token」分类 |
| V13 | 支出新增「订阅」分类 |
| V14 | **删除公开站点与作品集**：`DROP TABLE portfolio_repos / portfolio_items`，`notes` 删 `visibility` / `published_at`，删 `idx_notes_public` |
| V15 | `login_logs`（登录审计） |

已执行的迁移**不再修改**，修正一律新增版本。

### 表

| 表 | 用途 |
| --- | --- |
| `users` | 用户名（小写唯一索引）、BCrypt 哈希、TOTP 密钥与开关 |
| `pending_totp` | 等待动态码的临时记录（只存 token 哈希，5 分钟） |
| `tokens` | API Token（只存 SHA-256 + 展示前缀） |
| `trusted_devices` | 授信设备（只存哈希，30 天） |
| `sa_token` | Sa-Token 的表结构；**当前未启用 JDBC 存储，实际会话在内存** |
| `audit_events` | 安全审计（已接入 8 类事件：TOTP、改密、会话、授信设备、Token） |
| `login_logs` | 登录审计：成功 / 失败 / 动态码失败 / 登出，含用户名快照、IP、UA、失败原因 |
| `folders` / `notes` / `tags` / `note_tags` | 笔记、目录、标签 |
| `note_versions` | 版本快照（含合并窗口锚点） |
| `issues` / `issue_status_events` | Issue 与状态事件 |
| `ledger_batches` / `ledger_entries` / `ledger_aliases` | 记账 |

搜索用 `pg_trgm` + GIN 索引（标题、正文、标签名）。金额统一 `amount_cents bigint`（单位：分）。

## API 一览

完整契约见 [`../docs/api-conventions.md`](../docs/api-conventions.md)。

### 认证 `/api/auth`

| 方法 | 路径 | 权限 |
| --- | --- | --- |
| POST | `/api/auth/login` | 匿名 |
| POST | `/api/auth/login/totp` | 匿名 |
| POST | `/api/auth/logout` | 登录（同时写 `logout` 登录日志） |
| GET | `/api/me` | 匿名可用 |
| GET | `/api/auth/login-logs` | SESSION，`limit`（默认 20）/ `offset` |
| POST | `/api/auth/totp/setup` | SESSION |
| POST | `/api/auth/totp/verify` | SESSION |
| POST | `/api/auth/totp/disable` | SESSION |
| POST | `/api/auth/password` | SESSION_TOTP |

### 会话 / 授信设备 / Token

| 方法 | 路径 | 权限 |
| --- | --- | --- |
| GET | `/api/sessions` | SESSION |
| DELETE | `/api/sessions/{id}` | SESSION |
| GET | `/api/trusted-devices` | SESSION |
| DELETE | `/api/trusted-devices/{id}` | SESSION |
| GET | `/api/tokens` | SESSION_TOTP |
| POST | `/api/tokens` | SESSION_TOTP |
| DELETE | `/api/tokens/{id}` | SESSION_TOTP |

### 笔记 `/api/notes`

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/notes` | 列表，`tagId` / `folderId` / `includeTrash` / `limit` / `offset` |
| GET | `/api/notes/trash` | 回收站 |
| GET | `/api/notes/{id}` | 详情 |
| POST | `/api/notes` | 新建 |
| PATCH | `/api/notes/{id}` | 更新；`clearFolder: true` 表示移到根目录 |
| DELETE | `/api/notes/{id}` | 软删除 |
| DELETE | `/api/notes/trash` | 清空回收站 |
| POST | `/api/notes/{id}/restore` | 还原 |
| DELETE | `/api/notes/{id}/purge` | 永久删除 |
| GET | `/api/notes/{id}/versions` | 版本列表 |
| GET | `/api/notes/{id}/versions/{versionId}` | 版本详情 |
| POST | `/api/notes/{id}/versions/{versionId}/restore` | 还原版本 |

### 文件夹 / 标签

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/folders` | 列表 |
| POST | `/api/folders` | 新建 |
| PATCH | `/api/folders/{id}` | 改名 / 移动（`clearParent: true` 移到根）/ 图标 / 排序 |
| DELETE | `/api/folders/{id}` | 删除（笔记迁到收件箱） |
| GET | `/api/tags` | 标签列表（**只读，不删任何数据**） |
| POST | `/api/tags` | 新建 |
| DELETE | `/api/tags/{id}` | 删除 |
| GET | `/api/tags/{id}/notes` | 标签下的笔记 |

### 搜索 / Issue / 统计

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/search` | 搜索，`q` / `type` / 分页 |
| GET | `/api/issues` | Issue 列表，可按 `status` |
| GET | `/api/issues/{id}` | 详情（`{ issue, status_events }`） |
| POST | `/api/issues` | 新建 |
| PATCH | `/api/issues/{id}` | 更新（含状态流转） |
| DELETE | `/api/issues/{id}` | 删除 |
| GET | `/api/stats` | 仪表盘快照 |

### 记账 `/api/ledger`

细节见 [`../docs/ledger.md`](../docs/ledger.md)。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/ledger/quick` | 只解析不落库 |
| POST | `/api/ledger/entries/quick` | 解析并写入（快捷指令用） |
| POST | `/api/ledger/entries/batch` | 确认写入（`/batches` 为别名） |
| GET | `/api/ledger/batches/{batchId}` | 批次及条目 |
| GET | `/api/ledger/entries` | 列表，`from` / `to` / `category` / `type` / 分页 |
| GET | `/api/ledger/entries/{id}` | 详情 |
| PATCH | `/api/ledger/entries/{id}` | 改分类 / 金额 / 时间 |
| DELETE | `/api/ledger/entries/{id}` | 删除 |
| GET | `/api/ledger/recent` | 最近录入（默认 3 条） |
| GET | `/api/ledger/summary` | 月度汇总，`month=YYYY-MM` |
| GET | `/api/ledger/trend` | 最近 N 天（默认 7，上限 90） |
| GET | `/api/ledger/categories` | 分类清单 |
| GET | `/api/ledger/aliases` | 别名列表 |
| POST | `/api/ledger/aliases` | 新增 / 更新别名 |
| DELETE | `/api/ledger/aliases/{alias}` | 删除别名 |

输入格式：`[日期] 分类 [备注…] 金额`。

```text
午饭12
11月16 午餐 16
昨天 打车 25
工资 8000
```

支出分类：`餐饮 / 购物 / 交通 / 居家 / 娱乐 / 医疗 / 还款 / 未分类`；
收入分类：`工资 / 奖金 / 报销 / 退款 / 红包 / 其他收入`。

#### 响应示例

```json
{
  "created": true,
  "batch_id": "0f7c…",
  "raw_text": "午饭12\n工资 8000",
  "created_at": "2026-11-17T10:30:00+08:00",
  "items": [
    { "id": "…", "type": "expense", "amount_cents": 1200, "category": "餐饮", "note": "午饭" }
  ],
  "total": 2
}
```

`quickCommit` 在外层再包一层：`{ "batch": {…}, "errors": [] }`。

一行都没解析出来时返回 `200`、`created: false`、`total: 0`，原因在 `errors` 里，不写空批次。

### 运维 / 元信息

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/health` | 健康检查（匿名） |
| GET | `/api/app-config` | 匿名，只返回 `{ version }`（占位，用于探活与排查前端产物版本） |

### 上传

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/uploads` | 图片上传（multipart `file`，`kind=note\|icon`） |
| GET | `/api/uploads` | 图标列表 |
| GET | `/uploads/**` | 静态托管（匿名，长缓存，规范化后校验在上传根目录内） |

## 错误响应

```json
{ "error": "validation_failed", "message": "请求参数校验失败", "fields": { "title": "标题不能为空" } }
```

| HTTP | `error` | 场景 |
| --- | --- | --- |
| 400 | `bad_request` | 参数格式错误、非法 UUID、缺参数、坏 JSON |
| 401 | `unauthorized` | 未登录、账密错误、Token 无效 / 过期 |
| 403 | `forbidden` | 只读 Token 写数据、Token 调会话接口、未过 TOTP |
| 404 | `not_found` | 资源不存在**或不属于当前用户** |
| 409 | `conflict` | 唯一约束冲突、重复启用 TOTP |
| 413 | `payload_too_large` | 文件超过 10 MiB |
| 415 | `unsupported_media_type` | 非 png / jpeg / gif / webp |
| 422 | `validation_failed` | `BizException.validation` |
| 429 | `too_many_requests` | 登录 / 动态码失败超限 |
| 500 | `internal_error` | 未捕获异常（详情只在服务端日志） |

## 构建与部署

```bash
./scripts/build.sh all           # 前端 → static → 打包 jar
java -jar backend/target/haven-2.4.0.jar
```

也可以单独执行：

```bash
./scripts/build.sh frontend      # 只更新 static/ 里的前端产物
./scripts/build.sh backend       # 只打包 jar（保留现有 static）
```

手动等价命令：

```bash
cd backend
./mvnw clean package -DskipTests
```

jar 会：

- 托管 `src/main/resources/static/` 下的前端产物
- 对 `/api/**`、`/uploads/**` 之外的未知路径回退 `index.html`
- 从 `haven.upload-dir` 读写上传文件

生产建议：

1. 反向代理（Nginx / Caddy）终止 TLS，转发到 `8080`
2. `uploads/` 挂持久卷
3. `SPRING_PROFILES_ACTIVE=prod` + 环境变量提供数据源
4. **用网关限制 `/actuator/**`**——应用内拦截器只覆盖 `/api/**`
5. 多实例部署前先解决"会话在内存"与"登录计数在内存"两个问题

prod 下日志同时写控制台和 `${LOG_PATH}`（默认 `./logs`）：`<app>.log` 按天 + 10 MB 滚动保留 30 天，`<app>-error.log` 只记 ERROR。

## 测试

```bash
./scripts/test.sh backend        # spotless + checkstyle + 测试
./scripts/test.sh all            # 连前端一起测
```

或手动：

```bash
./mvnw test
```

**不读写开发库的业务表**。默认在同一 PostgreSQL 实例重建独立测试库（`haven_test_db`，账号需 `CREATEDB`），
JVM 退出时自动 `DROP`；也可用 `-Dhaven.test.mode=container` 走 Testcontainers。

可用 `TEST_DB_URL` / `TEST_DB_USERNAME` / `TEST_DB_PASSWORD` 指定实例。详见
[`../docs/testing.md`](../docs/testing.md)。

```bash
./mvnw spotless:check     # 格式
./mvnw checkstyle:check   # 静态检查
```

## 已知限制

| 限制 | 影响 |
| --- | --- |
| Sa-Token 会话在内存 | 重启掉线，多实例不共享（`sa_token` 表是死资产） |
| 登录失败计数在内存 | 多实例下有效上限 = 实例数 × 配置值 |
| 单用户设计 | 无注册接口，账号靠 SQL 创建 |
| 部分写路径缺乐观锁 | 并发更新可能丢更新（标签、排序、条目） |
| `/actuator/**` 不在拦截器范围 | 生产必须靠网关保护 |
| 上传文件匿名可读 | 靠随机文件名保密 |
