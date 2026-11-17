# Haven

Haven 是一个**单用户、自托管**的个人知识中台：私有域写笔记、记账、维护作品集与 Issue；公开域只展示已发布的笔记和作品。

同一份前端构建产物可以同时部署在公开域和私有域，由后端下发的运行时配置决定当前域名加载哪一套路由。

## 功能

- **笔记**：文件夹树、标签、富文本编辑、自动保存、历史版本、回收站、发布 / 撤回
- **公开站点**：首页、全部笔记、笔记详情、作品集、站内搜索（只读，无登录入口）
- **作品集**：作品条目、多个仓库 / 链接、主仓库标记
- **记账**：手机端一行一笔、解析预览、批量幂等写入、月度汇总与走势图表、事后改分类 / 金额 / 时间
- **Issue**：Bug / Feature 记录、优先级、状态流转（父子层级已在 V3 迁移中移除）
- **仪表盘**：笔记总量、字数、公开数量、写作热力图、最近编辑、文件夹与 Issue 概览
- **搜索**：基于 PostgreSQL `pg_trgm` 的模糊匹配
- **图片上传**：编辑器粘贴 / 拖拽上传，按年 / 月归档
- **账号安全**：Sa-Token 会话、TOTP 两步验证、授信设备、API Token、会话管理
- **界面**：三栏布局、可折叠侧边栏、命令面板、快捷键、多套主题

## 技术栈

| 部分 | 技术 |
| --- | --- |
| 后端 | Java 21、Spring Boot 4.1、Spring MVC、MyBatis-Plus 3.5、Flyway、Sa-Token、BCrypt |
| 数据库 | PostgreSQL（`pg_trgm` 扩展） |
| 前端 | Vue 3.5、TypeScript、Vite 8、Pinia、Vue Router、TipTap 3 |
| 测试 | JUnit 5（后端）、Vitest + jsdom（前端） |

## 目录结构

```text
Haven/
├── backend/                 # Spring Boot API + 静态站点托管
│   ├── src/main/java/       # controller / service / mapper / entity ...
│   ├── src/main/resources/
│   │   ├── db/migration/    # Flyway 迁移脚本
│   │   └── static/          # 前端构建产物（本地产物不入库）
│   └── pom.xml
├── frontend/                # Vue 3 单页应用
│   ├── src/
│   │   ├── api/             # 后端接口封装
│   │   ├── components/      # 布局、编辑器、弹窗等组件
│   │   ├── router/          # 公开 / 私有路由与域名判定
│   │   ├── stores/          # Pinia：登录态、界面状态、主题
│   │   ├── utils/           # 纯函数工具
│   │   └── views/           # private / public 页面
│   └── package.json
└── README.md
```

更细的说明见 [backend/README.md](backend/README.md) 和 [frontend/README.md](frontend/README.md)；
**设计文档**（分层、契约、认证、数据模型、记账、测试、约定）在 [docs/](docs/README.md)。

## 快速开始

### 环境要求

- JDK 21+
- Node.js 20.19+ 或 22.12+
- pnpm（仓库使用 `pnpm-lock.yaml`）
- PostgreSQL 14+，可安装 `pg_trgm` 扩展

### 1. 准备数据库

默认开发配置见 `backend/src/main/resources/application-dev.yaml`：

```text
数据库：dev_db
用户：dev
密码：123456
地址：127.0.0.1:5432
```

可以用下面的命令创建（按本机 PostgreSQL 的实际情况调整）：

```bash
psql -U postgres -c "CREATE USER dev WITH PASSWORD '123456';"
psql -U postgres -c "CREATE DATABASE dev_db OWNER dev;"
psql -U postgres -d dev_db -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
```

建表、索引和扩展也会在应用启动时由 Flyway（`db/migration`）自动执行。

### 2. 启动后端

```bash
cd backend
./mvnw spring-boot:run
```

默认监听 `http://127.0.0.1:8080`。首次启动会自动执行数据库迁移。

健康检查：

```bash
curl http://127.0.0.1:8080/api/health
# {"status":"ok","version":"2.1.0"}
```

### 3. 启动前端

```bash
cd frontend
pnpm install
pnpm dev
```

打开 `http://127.0.0.1:5173`。开发服务器固定 5173 端口，并把 `/api` 代理到 `http://127.0.0.1:8080`。

### 4. 创建第一个用户

项目**没有注册接口**，需要直接写入一条用户记录。密码使用 BCrypt（cost = 12）哈希。

下面示例的用户名是 `admin`，密码是 `changeme`，仅供本地开发，登录后请立即修改：

```sql
INSERT INTO users (username, password_hash)
VALUES ('admin', '$2a$12$6aVoi9rTYyuC043ykOD0gua8bxwGXvZg07UgpVakcVZkSg6xECNAO');
```

也可以用任意 BCrypt 工具生成自己的 `$2a$` / `$2b$` / `$2y$` 哈希，再替换上面的值。

## 公开域与私有域

同一份前端产物会部署到两个域名：

- **公开域**：只读页面（笔记、作品集、搜索），不显示登录入口和后台链接
- **私有域**：工作台、仪表盘、设置，除 `/login` 外都需要登录

域名判定顺序：

1. 启动时请求 `GET /api/app-config`，读取后端配置的 `private_hosts`
2. 请求失败时退回前端构建期变量 `VITE_PRIVATE_HOST`
3. 两者都没有时，`localhost` / IP 地址视为私有域，其余视为公开域

后端通过 `HAVEN_PRIVATE_HOSTS` 配置私有域名单，换域名不需要重新打包前端：

```bash
HAVEN_PRIVATE_HOSTS=note.example.com,www.example.com ./mvnw spring-boot:run
```

## 常用命令

### 脚本（推荐）

仓库根目录的 `scripts/` 提供三个脚本，覆盖日常开发：

```bash
./scripts/run.sh                 # 本地启动（只需跑后端）
./scripts/run.sh --clean         # 先 clean 再启动

./scripts/build.sh all           # 清空 static → 构建前端并复制 → 打包 jar
./scripts/build.sh frontend      # 只构建前端并复制到 static
./scripts/build.sh backend       # 只打包 jar（保留现有 static）

./scripts/test.sh all            # 前后端都测
./scripts/test.sh backend        # spotless + checkstyle + 后端测试
./scripts/test.sh frontend       # vue-tsc + vitest

./scripts/version.sh             # 查看版本号（唯一来源：根目录 VERSION）
./scripts/version.sh set 2.2.0   # 改版本并同步到 pom.xml / package.json
```

> **本地开发只需要跑后端。** 构建时前端产物会被复制进 `backend/src/main/resources/static/`，
> 后端同时提供 API 与静态资源，前后端同源，不需要单独起 Vite 开发服务器。
> 如果 `static/` 是空的，`run.sh` 会提示先执行 `./scripts/build.sh frontend`。

### 手动执行

```bash
# 前端
cd frontend
pnpm dev        # 仅调试前端热更新时需要
pnpm build      # 类型检查 + 生产构建，输出 dist/
pnpm test       # Vitest 单次运行

# 后端
cd backend
./mvnw spring-boot:run          # 本地启动
./mvnw test                     # 测试（自动准备隔离的测试 schema，见下）
./mvnw clean package            # 打包，产物 target/haven-2.1.0.jar
```

### 脚本与手动命令的对应关系

| 脚本 | 等价操作 |
| --- | --- |
| `run.sh` | `cd backend && ./mvnw spring-boot:run` |
| `build.sh frontend` | `cd frontend && pnpm build`，再清空并把 `dist/` 复制到 `static/` |
| `build.sh backend` | `cd backend && ./mvnw clean package -DskipTests` |
| `build.sh all` | 上面两步按顺序执行 |
| `test.sh backend` | `spotless:check` + `checkstyle:check` + `mvnw test` |
| `test.sh frontend` | `pnpm exec vue-tsc -b` + `pnpm test` |
| `version.sh set X` | 写 `VERSION`，并同步 `pom.xml` 的 `<revision>` 与 `package.json` 的 `version` |

### 测试数据库

`./mvnw test` **不会**读写 `dev_db` 的业务表，也不会清空开发数据。策略见 `src/test/java/com/haven/backend/support/TestDatabaseSupport.java`：

| 模式 | 触发方式 | 说明 |
| --- | --- | --- |
| 临时 schema（默认） | 无需配置 | 在本地 PostgreSQL 上建 `haven_test_<随机>` schema，`search_path` 指向它；JVM 退出时自动 `DROP`，上次异常退出的残留 schema 会在下次启动时清理 |
| Testcontainers | `-Dhaven.test.mode=container`（或 `HAVEN_TEST_MODE=container ./scripts/test.sh backend`） | 需要可用的容器运行时；找不到时自动回退到临时 schema |

可覆盖的变量：`TEST_DB_URL` / `TEST_DB_USERNAME` / `TEST_DB_PASSWORD`（默认 `jdbc:postgresql://127.0.0.1:5432/dev_db`，账号 `dev`）。

> 两个都不可用时会**直接报错并给出修复指引**，不会静默回落到开发库。

## 生产部署

```bash
./scripts/build.sh all                                  # 前端 → static → 打包 jar
java -jar backend/target/haven-2.1.0.jar
```

`all` 会先清空 `static/`（避免旧哈希文件残留），再构建前端、复制产物、打包 jar。
jar 里已包含前端静态资源，部署时只需分发一个文件。

后端会从 `classpath:/static/` 托管前端，并对非 `/api`、非 `/uploads` 的路径回退到 `index.html`，因此前后端同源，不需要额外的跨域配置。

生产环境至少需要覆盖：

| 环境变量 | 说明 |
| --- | --- |
| `SPRING_PROFILES_ACTIVE` | 设为 `prod` 或自定义 profile |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | 生产数据库连接（`application-prod.yaml` 无默认值，缺失即启动失败） |
| `HAVEN_PRIVATE_HOSTS` | 私有域域名，逗号分隔 |
| `HAVEN_UPLOAD_DIR` | 上传文件目录，建议挂载持久化卷 |
| `HAVEN_TOTP_ISSUER` | 动态码发行方名称，默认 `Haven` |
| `HAVEN_TIME_ZONE` | 业务时区（如 `Asia/Shanghai`），默认取 JVM 时区；影响热力图日界与月度汇总 |
| `HAVEN_AUTH_LOGIN_MAX_ATTEMPTS` | 登录密码失败次数上限（默认 5） |
| `HAVEN_AUTH_LOGIN_WINDOW_MINUTES` | 登录失败计数窗口分钟数（默认 15） |
| `HAVEN_AUTH_TOTP_MAX_ATTEMPTS` | 同一 TOTP 待验证会话的失败次数上限（默认 5） |

> 已提供 `application-prod.yaml` 模板：数据库、上传目录、动态码发行方、登录限流阈值全部通过环境变量注入，Actuator 只暴露 `health` 且不返回详情。请通过反向代理或网关限制 `/actuator/**`（应用内拦截器只覆盖 `/api/**`）。
>
> `application.yaml` 通过 `${SPRING_PROFILES_ACTIVE:dev}` 默认激活 `dev` profile：本地开箱即用，生产只要设置 `SPRING_PROFILES_ACTIVE=prod` 即可覆盖。会话（Sa-Token）配置放在 `application.yaml` 中，切换 profile 不会丢失；数据库、上传、Actuator 等开发配置仍集中在 `application-dev.yaml`，生产需提供对应的 `application-prod.yaml` 或环境变量。
>
> `application-dev.yaml` 里的数据库口令仅是本地默认值，可用 `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` 覆盖。

## API 约定

- 所有接口以 `/api` 开头；匿名可访问的公开接口在 `/api/public/**` 下
- JSON 字段使用 `snake_case`
- 列表响应统一为 `{ "items": [...], "total": 0 }`
- 请求/响应体字段对外统一 `snake_case`；后端用 record DTO 定义契约，响应由全局 `SNAKE_CASE` 序列化策略输出，请求体由前端 `toCamelCaseKeys` 转换后提交
- 错误响应统一为：

  ```json
  {
    "error": "validation_failed",
    "message": "请求参数校验失败",
    "fields": { "title": "标题不能为空" }
  }
  ```

认证支持两种方式：

- 浏览器会话：Sa-Token Cookie（`havenToken`）
- 程序调用：`Authorization: Bearer <API Token>`

完整接口分组见 [backend/README.md](backend/README.md#api-一览)。

## iOS 快捷指令记账

记账的主力入口是 iOS 快捷指令：说一句「午饭 12」，一次请求直接落库。

1. 在私有域打开 `/settings/tokens`，创建一个 `read_write` Token（明文只显示一次）。
2. 在快捷指令 App 新建快捷指令：
   - **听写文本**（语言选中文）
   - **获取 URL 内容**
     - URL：`https://<私有域>/api/ledger/entries/quick`
     - 方法：`POST`
     - 请求头：
       - `Authorization`：`Bearer <Token>`
       - `Content-Type`：`application/json`
     - 请求体：`JSON`，字段 `text` 选「听写文本」
   - **获取词典值**：键 `total`、`errors`
   - **显示通知**：例如「已记 1 笔」，有错误时展示 `errors`
3. 把这个快捷指令加进 Siri，说「嘿 Siri，记一笔」即可。

输入格式是一行一条 `[日期] 分类 [备注…] 金额`：

```text
午饭12
11月16 午餐 16
昨天 打车 25
工资 8000
```

日期可写 `2026-11-16`、`11月16`、`16号`、`昨天`，不写就是今天；金额支持 `12`、`12.5`、`32元`、`¥32`、`二十五块`；工资、奖金、报销、退款、红包等会自动判为收入。解析失败的行走 `errors` 返回，不会写入空批次。

生产环境请用 HTTPS 域名；iOS 对明文 HTTP 限制较多。想避免网络抖动导致重复记账时，可以在请求体里加一个 `batch_id`（用快捷指令的「UUID」动作生成），服务端会按相同 `batch_id` 幂等处理。

## 版本号

采用 `MAJOR.MINOR.PATCH`，但**升级门槛与标准 SemVer 不同**：

| 位 | +1 的条件 | 例子 |
| --- | --- | --- |
| MAJOR | 新增**全新的功能领域**——需三要素齐备：**独立顶级导航入口 + 自己的数据表 + 自己的 CRUD 流程** | v1 → v2：加入记账 |
| MINOR | 不加大领域，但有大动作 / 多个小功能点 / 大修复 | 代码风格重构、API 契约改造 |
| PATCH | 纯修复，无新增能力 | 修小 bug、改文案 |

> 完整规则与理由见 [docs/versioning.md](docs/versioning.md)。**当前版本 `2.1.0`。**

版本号**只有一个来源**：根目录的 [`VERSION`](VERSION) 文件。改版本只改这里：

```bash
./scripts/version.sh set 2.2.0    # 同步到 pom.xml 与 package.json
./scripts/version.sh              # 查看三处是否一致
```

`build.sh` / `test.sh` 会自动校验，不一致直接失败。

## 相关文档

**设计文档（[docs/](docs/README.md)）**——讲为什么这么设计、边界在哪：

| 文档 | 内容 |
| --- | --- |
| [versioning.md](docs/versioning.md) | 版本号规则（与标准 SemVer 不同） |
| [architecture.md](docs/architecture.md) | 分层、请求生命周期、关键决策、已知限制 |
| [api-conventions.md](docs/api-conventions.md) | 契约、命名、分页、错误码、权限声明 |
| [auth.md](docs/auth.md) | 双通道认证、TOTP、授权级别、审计、安全清单 |
| [data-model.md](docs/data-model.md) | 表结构、约束、索引、迁移规则、金额与时间 |
| [ledger.md](docs/ledger.md) | 快捷输入解析、分类体系、幂等、统计 |
| [testing.md](docs/testing.md) | 测试隔离、写测试的套路、常见坑 |
| [conventions.md](docs/conventions.md) | 代码风格、提交前检查、禁止事项 |

**子项目 README**——讲怎么跑起来：

- [backend/README.md](backend/README.md)：数据库、配置、接口、部署
- [frontend/README.md](frontend/README.md)：路由、状态管理、编辑器、开发约定
