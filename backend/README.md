# Haven Backend

Haven 的后端：Spring Boot REST API、PostgreSQL 持久化、Flyway 数据库迁移，以及前端单页应用的静态托管。

- 统一前缀 `/api`，JSON 字段使用 `snake_case`
- 浏览器会话（Sa-Token）与 API Token（`Bearer`）双通道认证
- 支持 TOTP 两步验证、授信设备、会话管理、API Token 管理
- 同一份返回结构：列表 `{ items, total }`，错误 `{ error, message, fields? }`
- 生产环境与前端同源部署，非 API 路径回退到 `index.html`

## 技术栈

| 组件 | 版本 / 说明 |
| --- | --- |
| Java | 21 |
| Spring Boot | 4.1.2（Web MVC、JDBC、Validation、Actuator、Devtools） |
| MyBatis-Plus | 3.5.18 |
| PostgreSQL | 主数据库，搜索依赖 `pg_trgm` |
| Flyway | 启动时自动迁移 `src/main/resources/db/migration` |
| Sa-Token | 1.46.0，会话持久化到 `sa_token` 表 |
| BCrypt | `at.favre.lib:bcrypt`，cost = 12 |
| Lombok | 简化实体与构造器注入 |

## 目录结构

```text
src/main/java/com/haven/backend/
├── BackendApplication.java   # 启动类（统一注册各领域 mapper）
├── auth/                     # 认证与授权
│   ├── config/               # Sa-Token 拦截器注册
│   ├── controller/           # 登录、TOTP、会话、API Token、授信设备
│   ├── dto/                  # 认证相关请求 / 响应对象
│   ├── entity/               # 用户、会话、Token、授信设备、审计事件
│   ├── interceptor/          # Session + API Token 双通道认证
│   ├── mapper/               # 认证相关 Mapper
│   ├── service/ + impl/      # 认证业务
│   └── util/                 # TOTP、Token 哈希等工具
├── note/                     # 笔记领域
│   ├── controller/           # 笔记、版本、文件夹、标签、上传、搜索
│   ├── entity/               # 笔记、版本、文件夹、标签
│   ├── mapper/               # 笔记相关 Mapper
│   └── service/ + impl/      # 笔记业务
├── issue/                    # Issue 领域
│   ├── controller/
│   ├── entity/
│   ├── mapper/
│   └── service/ + impl/
├── ledger/                   # 记账领域
│   ├── controller/
│   ├── dto/
│   ├── entity/
│   ├── mapper/
│   └── service/ + impl/
├── portfolio/                # 作品集领域
│   ├── controller/
│   ├── entity/
│   ├── mapper/
│   └── service/ + impl/
├── stats/                    # 统计概览
│   ├── controller/
│   └── service/ + impl/
├── system/                   # 健康检查、运行时配置
│   └── controller/
├── config/                   # Web / MyBatis-Plus 等全局配置
├── dto/                      # 跨领域通用响应对象
├── exception/                # 业务异常与全局错误处理
└── typehandler/              # PostgreSQL uuid / uuid[] 映射
```

## 快速开始

### 环境要求

- JDK 21+
- PostgreSQL 14+，可创建 `pg_trgm` 扩展

### 1. 准备数据库

默认开发连接见 `src/main/resources/application-dev.yaml`：

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

也可以通过环境变量覆盖数据源：

```bash
SPRING_DATASOURCE_URL=jdbc:postgresql://127.0.0.1:5432/dev_db \
SPRING_DATASOURCE_USERNAME=dev \
SPRING_DATASOURCE_PASSWORD=123456 \
./mvnw spring-boot:run
```

### 2. 启动

```bash
cd backend
./mvnw spring-boot:run
```

默认监听 `8080`。首次启动时 Flyway 会执行 `V1`、`V2` 迁移。

健康检查：

```bash
curl http://127.0.0.1:8080/api/health
# {"status":"ok","version":"0.1.0-java"}
```

### 3. 创建用户

项目不提供注册接口。需要直接写入用户，密码为 BCrypt（cost = 12）哈希。

示例：用户名 `admin`，密码 `changeme`（仅本地开发，登录后请立即修改）。

```sql
INSERT INTO users (username, password_hash)
VALUES ('admin', '$2a$12$6aVoi9rTYyuC043ykOD0gua8bxwGXvZg07UgpVakcVZkSg6xECNAO');
```

## 配置

`application.yaml` 默认激活 `dev` profile：

```yaml
spring:
  profiles:
    active:
      - dev
```

主要配置项：

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| `spring.datasource.*` | 见 `application-dev.yaml` | PostgreSQL 连接与 Hikari 连接池 |
| `spring.servlet.multipart.max-file-size` | `10MB` | 单文件上传上限 |
| `haven.private-hosts` | `note.vorin.icu` | 私有域主机名，逗号分隔；由 `GET /api/app-config` 下发 |
| `haven.totp.issuer` | `Haven` | 动态码发行方名称 |
| `haven.upload-dir` | `uploads` | 上传文件根目录 |
| `sa-token.token-name` | `havenToken` | 会话 Cookie 名 |
| `sa-token.timeout` | `604800` | 会话有效期（秒，7 天） |
| `sa-token.active-timeout` | `86400` | 非滑动续期配置 |
| `management.endpoints.web.exposure.include` | `health,info` | Actuator 暴露范围 |

常用环境变量：

```bash
SPRING_PROFILES_ACTIVE=prod
SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/haven
SPRING_DATASOURCE_USERNAME=haven
SPRING_DATASOURCE_PASSWORD=******
HAVEN_PRIVATE_HOSTS=note.example.com
HAVEN_UPLOAD_DIR=/var/lib/haven/uploads
HAVEN_TOTP_ISSUER=Haven
```

> `application-dev.yaml` 里除了数据源，还包含 Sa-Token、上传大小、Actuator 等配置。切换到 `prod` 前，请把这些配置迁移到 `application.yaml`，或新增 `application-prod.yaml`，否则会回落到框架默认值。

## 认证与安全

### 两种身份通道

`AuthInterceptor` 拦截 `/api/**`：

1. 请求带 `Authorization: Bearer <token>` 时，按 API Token 认证，校验哈希、撤销状态与过期时间，并刷新 `last_used_at`
2. 否则回退到 Sa-Token 会话（Cookie `havenToken`）

认证通过后，用户 ID、scope、认证类型会写入 request attribute，控制器通过 `AuthInterceptor.requireUserId(request)` 读取当前用户。该方法同时适用于会话与 API Token，避免控制器直接依赖 Sa-Token 的 `StpUtil.checkLogin()`。

只读 Token（`scope=read`）只能执行 `GET` / `HEAD` / `OPTIONS`，其他方法会直接返回 403；需要写入时请创建 `read_write` Token。

### 登录流程

1. `POST /api/auth/login` 校验用户名和密码
2. 未启用 TOTP，或当前设备已授信：直接建立会话，返回 `totp_required: false`
3. 启用了 TOTP 且设备未授信：返回 `totp_required: true` 和 `temp_token`
4. 前端用 `POST /api/auth/login/totp` 提交动态码，校验通过后建立会话
5. 勾选「信任这台设备」时，创建 30 天有效的授信设备，并写入 HttpOnly Cookie

安全相关行为：

- 密码使用 BCrypt cost 12；修改密码需要旧密码，启用 TOTP 时还需要动态码
- 修改密码后撤销该用户全部会话与授信设备
- 关闭 TOTP 后撤销全部授信设备
- 会话管理接口只允许浏览器会话访问，当前会话不能通过该接口踢出自己
- API Token 管理接口要求会话已通过 TOTP；Token 明文只在创建时返回一次
- 上传文件按真实 MIME 校验，只接受 png / jpeg / gif / webp，单文件不超过 10 MiB

默认放行（无需登录）的接口：

- `/api/health`
- `/api/auth/login`、`/api/auth/login/totp`
- `/api/me`（匿名时返回 `{ "anonymous": true }`）
- `/api/app-config`
- `/api/public/**`
- `/uploads/**`（公开笔记里的图片需要匿名可访问）

## 数据库

Flyway 脚本：

- `V1__init.sql`：用户、Sa-Token、待验证 TOTP、API Token、审计事件、文件夹、笔记、标签、作品集、历史版本、Issue
- `V2__trusted_devices.sql`：授信设备，以及登录时是否勾选信任设备的标记
- `V3__del_issues_parentId.sql`：移除 Issue 的父子层级字段
- `V4__add_ledger_tables.sql`：记账批次、条目、别名
- `V5__ledger_default_aliases.sql`：为 `kairo` 初始化默认分类别名
- `V6__ledger_income_categories.sql`：新增收入分类（工资 / 奖金 / 报销 / 退款 / 红包 / 其他收入）与收入别名

主要表：

| 表 | 用途 |
| --- | --- |
| `users` | 用户名、BCrypt 密码哈希、TOTP 密钥与开关 |
| `sa_token` | Sa-Token 会话持久化 |
| `pending_totp` | 密码通过、等待动态码校验的临时记录（5 分钟） |
| `tokens` | API Token（只存哈希与前缀） |
| `trusted_devices` | 授信设备（只存哈希，30 天有效） |
| `folders` / `notes` / `tags` / `note_tags` | 笔记、目录与标签 |
| `note_versions` | 笔记历史快照 |
| `portfolio_items` / `portfolio_repos` | 作品集与仓库链接 |
| `issues` / `issue_status_events` | Issue 与状态变更事件 |
| `ledger_batches` / `ledger_entries` | 记账批次与记账条目 |
| `ledger_aliases` | 分类别名，例如“奶茶” -> “餐饮” |
| `audit_events` | 审计事件表（结构已建，供后续业务写入） |

搜索使用 `pg_trgm` 与 GIN 索引，支持标题 / 正文的模糊匹配。

## API 一览

### 认证

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/auth/login` | 用户名密码登录 |
| POST | `/api/auth/login/totp` | 动态码第二步登录 |
| POST | `/api/auth/logout` | 退出当前会话 |
| GET | `/api/me` | 当前身份（匿名可用） |
| POST | `/api/auth/totp/setup` | 生成 TOTP 密钥与 otpauth URI |
| POST | `/api/auth/totp/verify` | 校验并启用 TOTP |
| POST | `/api/auth/totp/disable` | 关闭 TOTP |
| POST | `/api/auth/password` | 修改密码 |

### 会话、授信设备、API Token

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/sessions` | 当前用户的会话列表 |
| DELETE | `/api/sessions/{id}` | 踢出指定会话（仅会话） |
| GET | `/api/trusted-devices` | 授信设备列表（仅会话） |
| DELETE | `/api/trusted-devices/{id}` | 撤销授信设备（仅会话） |
| GET | `/api/tokens` | Token 列表（会话 + TOTP） |
| POST | `/api/tokens` | 创建 Token（明文只返回一次） |
| DELETE | `/api/tokens/{id}` | 撤销 Token |

### 笔记、目录、标签

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/notes` | 笔记列表，支持 `visibility` / `tag_id` / `folder_id` / `include_trash` |
| GET | `/api/notes/trash` | 回收站 |
| GET | `/api/notes/{id}` | 笔记详情 |
| POST | `/api/notes` | 创建笔记 |
| PATCH | `/api/notes/{id}` | 更新标题、正文、标签、文件夹、排序 |
| DELETE | `/api/notes/{id}` | 软删除（移入回收站） |
| DELETE | `/api/notes/trash` | 清空回收站 |
| POST | `/api/notes/{id}/restore` | 从回收站还原 |
| DELETE | `/api/notes/{id}/purge` | 永久删除 |
| POST | `/api/notes/{id}/publish` | 发布到公开域 |
| POST | `/api/notes/{id}/unpublish` | 撤回发布 |
| GET | `/api/notes/{id}/versions` | 历史版本列表 |
| GET | `/api/notes/{id}/versions/{versionId}` | 历史版本详情 |
| POST | `/api/notes/{id}/versions/{versionId}/restore` | 还原历史版本 |
| GET | `/api/folders` | 文件夹列表 |
| POST | `/api/folders` | 新建文件夹 |
| PATCH | `/api/folders/{id}` | 重命名 / 移动 / 修改图标 |
| DELETE | `/api/folders/{id}` | 删除文件夹 |
| GET | `/api/tags` | 标签列表 |
| POST | `/api/tags` | 新建标签 |
| DELETE | `/api/tags/{id}` | 删除标签 |
| GET | `/api/tags/{id}/notes` | 某个标签下的笔记 |

### 搜索、作品集、Issue、统计

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/search?q=` | 私有域搜索，支持 `type` / `limit` / `offset` |
| GET | `/api/portfolio/{id}` | 作品详情 |
| POST | `/api/portfolio` | 新建作品 |
| PATCH | `/api/portfolio/{id}` | 更新作品 |
| DELETE | `/api/portfolio/{id}` | 删除作品 |
| POST | `/api/portfolio/{id}/repos` | 添加作品链接 |
| PATCH | `/api/portfolio/{id}/repos/{repoId}` | 更新作品链接 |
| DELETE | `/api/portfolio/{id}/repos/{repoId}` | 删除作品链接 |
| GET | `/api/issues` | Issue 列表，可按 `status` 过滤 |
| GET | `/api/issues/{id}` | Issue 详情 |
| POST | `/api/issues` | 新建 Issue |
| PATCH | `/api/issues/{id}` | 更新 Issue（含状态流转） |
| DELETE | `/api/issues/{id}` | 删除 Issue |
| GET | `/api/stats` | 仪表盘统计 |

### 记账

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/ledger/quick` | 只解析不落库，返回 `items` 与逐行 `errors` |
| POST | `/api/ledger/entries/quick` | 一步记账：解析并直接写入（快捷指令用），支持 `batch_id` 幂等 |
| POST | `/api/ledger/entries/batch` | 确认写入，`batch_id` 相同只写一次（`/batches` 为兼容别名） |
| GET | `/api/ledger/batches/{batchId}` | 查看批次及条目 |
| GET | `/api/ledger/entries` | 条目列表，支持 `from` / `to` / `category` / `type` / 分页 |
| GET | `/api/ledger/entries/{id}` | 条目详情 |
| PATCH | `/api/ledger/entries/{id}` | 修改分类 / 金额 / 发生时间 |
| DELETE | `/api/ledger/entries/{id}` | 删除条目 |
| GET | `/api/ledger/recent` | 最近录入条目，默认 3 笔（按 `created_at`） |
| GET | `/api/ledger/summary?month=YYYY-MM` | 月度总额 + 支出 / 收入分类排行 + 按天走势 + 最近 3 笔 |
| GET | `/api/ledger/trend?days=7` | 最近 N 天（默认 7，最多 90）的总额、分类排行与按天走势 |
| GET | `/api/ledger/categories` | 支持的分类列表 |
| GET | `/api/ledger/aliases` | 别名列表 |
| POST | `/api/ledger/aliases` | 新增或更新别名 |
| DELETE | `/api/ledger/aliases/{alias}` | 删除别名 |

输入格式为一行一条：`分类 [备注…] 金额`。

```text
午饭12
晚饭 20
网购 零食 100
房租 水电 2200
工资 8000
```

解析规则：

1. 行末抽取金额，支持 `12`、`12.5`、`32元`、`¥32`、`二十五块`
2. 剩余文本按第一个空格切分，第一段查别名表或大类，其余作为备注
3. 分类命中收入大类（工资 / 奖金 / 报销 / 退款 / 红包 / 其他收入），或文本含对应关键词时判为收入，否则为支出
4. 别名命中时取大类并把原词并入备注；都不是则落 `未分类`，原词保留在备注中

支出大类：`餐饮 / 购物 / 交通 / 居家 / 娱乐 / 医疗 / 未分类`；
收入大类：`工资 / 奖金 / 报销 / 退款 / 红包 / 其他收入`。

`quick` 示例：

```json
{
  "text": "午饭12\n网购 零食 100"
}
```

快捷指令一步记账：

```http
POST /api/ledger/entries/quick
Authorization: Bearer <API Token>
Content-Type: application/json

{ "text": "午饭12\n工资 8000" }
```

解析成功返回 `201`，`items` 是本次写入的条目；`batch_id` 不传时由服务端生成，传入相同值可安全重试：

```json
{
  "created": true,
  "batch_id": "0f7c…",
  "raw_text": "午饭12\n工资 8000",
  "items": [ { "id": "…", "type": "expense", "amount_cents": 1200, "category": "餐饮" } ],
  "total": 2,
  "errors": []
}
```

一行都没解析出来时返回 `200`、`created: false`、`total: 0`，原因在 `errors` 里，不会写入空批次。

`summary` 返回：

```json
{
  "month": "2026-11",
  "total_expense_cents": 128600,
  "total_income_cents": 0,
  "total_count": 3,
  "category_ranking": [
    { "category": "餐饮", "amount_cents": 3200, "count": 2 }
  ],
  "income_category_ranking": [
    { "category": "工资", "amount_cents": 800000, "count": 1 }
  ],
  "daily": [
    { "date": "2026-11-01", "expense_cents": 1200, "income_cents": 0, "count": 1 }
  ],
  "recent": [
    { "id": "...", "type": "expense", "amount_cents": 1200, "category": "餐饮", "note": "午饭" }
  ]
}
```

### 公开接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/public/notes` | 已发布笔记列表 |
| GET | `/api/public/notes/{id}` | 已发布笔记详情 |
| GET | `/api/public/search?q=` | 公开站内搜索 |
| GET | `/api/public/portfolio` | 作品列表 |
| GET | `/api/public/portfolio/{id}` | 作品详情 |
| GET | `/api/app-config` | 前端运行时配置（私有域名单） |
| GET | `/api/health` | 健康检查 |

### 上传与静态资源

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/uploads` | 上传图片（multipart `file`，`kind` 为 `note` 或 `icon`） |
| GET | `/api/uploads` | 图标文件列表 |
| GET | `/uploads/**` | 上传文件静态托管（匿名、长缓存） |

## 错误响应

全局异常处理统一输出：

```json
{
  "error": "validation_failed",
  "message": "请求参数校验失败",
  "fields": {
    "title": "标题不能为空"
  }
}
```

常见错误码：

| HTTP | `error` | 场景 |
| --- | --- | --- |
| 400 | `bad_request` / `validation_failed` | 参数错误 |
| 401 | `unauthorized` | 未登录、密码或动态码错误、Token 无效 / 过期 |
| 403 | `forbidden` | 权限不足，或 Token 调用了仅限会话的接口 |
| 404 | `not_found` | 资源不存在 |
| 409 | `conflict` | 状态冲突，如重复启用 TOTP |
| 413 | `payload_too_large` | 文件超过 10 MiB |
| 415 | `unsupported_media_type` | 非 png / jpeg / gif / webp |

## 构建与部署

```bash
cd backend
./mvnw clean package
java -jar target/backend-1.0.2.jar
```

可执行 jar 会：

- 托管 `src/main/resources/static/` 下的前端产物
- 对 `/api/**` 与 `/uploads/**` 以外的未知路径回退到 `index.html`
- 从 `haven.upload-dir`（默认当前目录下的 `uploads/`）读写上传文件

生产建议：

1. 用反向代理（Nginx / Caddy）终止 TLS，并把域名转发到 `8080`
2. 将 `uploads/` 挂载为持久卷
3. 设置 `SPRING_PROFILES_ACTIVE=prod`，使用独立的 `application-prod.yaml` 或环境变量提供数据源
4. 通过 `HAVEN_PRIVATE_HOSTS` 配置私有域；公开域不需要额外配置
5. 生产环境把 Actuator 健康详情改为 `when-authorized`，避免公网暴露组件信息

`prod` profile 下日志会同时写入控制台和 `${logging.file.path}`（默认 `./logs`）：

- `<app>.log`：按天 + 10 MB 滚动，保留 30 天
- `<app>-error.log`：仅 ERROR 级别

## 测试

```bash
./mvnw test
```

当前测试是 Spring Boot 上下文加载测试，需要可连接的 PostgreSQL 与已配置的数据源。
