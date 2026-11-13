# Haven

Haven 是一个**个人笔记与作品集**应用：私有域写笔记、管理标签与目录、维护作品集；公开域只展示已发布的笔记和作品。

同一份前端构建产物可以同时部署在公开域和私有域，由后端下发的运行时配置决定当前域名加载哪一套路由。

## 功能

- **笔记**：文件夹树、标签、富文本编辑、自动保存、历史版本、回收站、发布 / 撤回
- **公开站点**：首页、全部笔记、笔记详情、作品集、站内搜索（只读，无登录入口）
- **作品集**：作品条目、多个仓库 / 链接、主仓库标记
- **记账**：手机端一行一笔、解析预览、批量幂等写入、月度汇总与走势图表、事后改分类 / 金额 / 时间
- **Issue**：Bug / Feature 记录、优先级、状态流转、父子层级
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

更细的说明见 [backend/README.md](backend/README.md) 和 [frontend/README.md](frontend/README.md)。

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
# {"status":"ok","version":"0.1.0-java"}
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

### 前端

```bash
cd frontend
pnpm dev        # 开发服务器（http://127.0.0.1:5173）
pnpm build      # 类型检查 + 生产构建，输出 dist/
pnpm preview    # 预览构建产物
pnpm test       # Vitest 单次运行
pnpm test:watch # Vitest 监听模式
```

### 后端

```bash
cd backend
./mvnw spring-boot:run          # 本地启动
./mvnw test                     # 测试（需要可连接的数据库）
./mvnw clean package            # 打包，产物在 target/
java -jar target/backend-1.0.2.jar
```

## 生产部署

1. 构建前端：

   ```bash
   cd frontend
   pnpm build
   ```

2. 把 `dist/` 复制到后端静态资源目录：

   ```bash
   rm -rf ../backend/src/main/resources/static
   cp -r dist ../backend/src/main/resources/static
   ```

3. 打包并运行后端：

   ```bash
   cd ../backend
   ./mvnw clean package
   java -jar target/backend-1.0.2.jar
   ```

后端会从 `classpath:/static/` 托管前端，并对非 `/api`、非 `/uploads` 的路径回退到 `index.html`，因此前后端同源，不需要额外的跨域配置。

生产环境至少需要覆盖：

| 环境变量 | 说明 |
| --- | --- |
| `SPRING_PROFILES_ACTIVE` | 设为 `prod` 或自定义 profile |
| `SPRING_DATASOURCE_URL` / `..._USERNAME` / `..._PASSWORD` | 生产数据库连接 |
| `HAVEN_PRIVATE_HOSTS` | 私有域域名，逗号分隔 |
| `HAVEN_UPLOAD_DIR` | 上传文件目录，建议挂载持久化卷 |
| `HAVEN_TOTP_ISSUER` | 动态码发行方名称，默认 `Haven` |

> `application.yaml` 默认激活 `dev` profile，而数据库、Sa-Token、上传、Actuator 等配置集中在 `application-dev.yaml`。切到其他 profile 前，请把需要的配置迁到 `application.yaml` 或新增对应的 `application-prod.yaml`。

## API 约定

- 所有接口以 `/api` 开头；匿名可访问的公开接口在 `/api/public/**` 下
- JSON 字段使用 `snake_case`
- 列表响应统一为 `{ "items": [...], "total": 0 }`
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

输入格式是一行一条 `分类 [备注…] 金额`：

```text
午饭12
网购 零食 100
工资 8000
```

金额支持 `12`、`12.5`、`32元`、`¥32`、`二十五块`；工资、奖金、报销、退款、红包等会自动判为收入。解析失败的行走 `errors` 返回，不会写入空批次。

生产环境请用 HTTPS 域名；iOS 对明文 HTTP 限制较多。想避免网络抖动导致重复记账时，可以在请求体里加一个 `batch_id`（用快捷指令的「UUID」动作生成），服务端会按相同 `batch_id` 幂等处理。

## 相关文档

- [backend/README.md](backend/README.md)：数据库、配置、接口、部署
- [frontend/README.md](frontend/README.md)：路由、状态管理、编辑器、开发约定
