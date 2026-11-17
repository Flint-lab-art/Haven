# 架构

## 1. 仓库结构

```text
Haven/
├── backend/        # Spring Boot 4 + MyBatis-Plus + PostgreSQL
├── frontend/       # Vue 3 + TypeScript + Vite
├── docs/           # 本目录：设计文档
└── README.md       # 快速开始
```

构建产物是**一个 jar**：前端 `dist/` 被复制进 `backend/src/main/resources/static/`，后端同时提供 API 与静态资源。

```text
frontend/dist/  ──build.sh frontend──▶  backend/src/main/resources/static/
                                              │
                                              ▼
                                    backend/target/haven-2.1.0.jar
```

因此**本地开发只需要跑后端**（`./scripts/run.sh`）；只有需要前端热更新时才起 Vite。
`static/` 已被 `backend/.gitignore` 忽略，产物不进版本库。

## 2. 后端分层

```text
controller/   协议适配：绑定参数、校验、调 service、返回 DTO
   ↓
service/      业务逻辑、事务边界、权限归属校验
   ↓
mapper/       MyBatis-Plus，只做数据访问
   ↓
entity/       POJO，与表一一对应
```

### 各层的硬性规则

| 层 | 允许 | 禁止 |
| --- | --- | --- |
| controller | 参数绑定、`@Valid`、调 service、组装 DTO | 写业务判断、写 SQL、开事务、密码学 |
| service | 业务规则、事务、归属校验、DTO 转换 | 返回 entity、吞异常、直接写 HTTP 状态 |
| mapper | 单表 CRUD、参数化聚合 SQL | 拼接用户输入 |

**entity 不越过 service 边界**：controller 永远不返回 entity。早期 `FoldersController` 直接返回 `Folders`，现在统一映射成 `FolderResponse`。

### 按领域分包

每个业务域一个顶层包，内部再分 `controller / dto / entity / mapper / service`：

| 包 | 职责 |
| --- | --- |
| `auth` | 登录、会话、TOTP、授信设备、API Token |
| `audit` | 审计事件记录（横切） |
| `note` | 笔记、文件夹、标签、搜索、上传 |
| `ledger` | 记账 |
| `issue` | 需求 / Bug |
| `portfolio` | 作品集 |
| `stats` | 首页统计（只读聚合，跨领域） |
| `system` | 健康检查、运行时前端配置 |
| `exception` | 全局异常处理 |
| `config` | Web、MyBatis、Clock 等基础设施配置 |
| `dto` | 跨领域通用 DTO（`PageResponse`、`ApiError`） |
| `typehandler` | PostgreSQL `uuid` / `uuid[]` 映射 |

`stats` 是唯一直接读多个领域 Mapper 的包——它只做聚合查询，不写库，因此没有引入跨领域耦合风险。

## 3. 请求生命周期

```text
HTTP 请求
  │
  ├─ Servlet Filter
  │
  ├─ AuthInterceptor.preHandle           ← /api/** 注册，排除公开路径
  │    ├─ 通道 1：Authorization: Bearer <API Token>
  │    └─ 通道 2：Sa-Token 会话（Cookie）
  │    └─ RequiredAccess.require(...)    ← 按 @RequireAccess 或 HTTP 方法兜底
  │
  ├─ Controller                          ← 参数绑定 + @Valid
  │    └─ AuthInterceptor.requireUserId(request)  ← 取当前用户
  │
  ├─ Service（@Transactional）            ← 业务 + 事务
  │
  ├─ Mapper → PostgreSQL
  │
  └─ 返回 DTO → Jackson（SNAKE_CASE）→ JSON
       └─ 异常 → GlobalExceptionHandler → { error, message, fields? }
```

### 身份怎么传到 Controller

拦截器把身份写进 request attribute，Controller 通过静态方法读取，不依赖 Sa-Token 的具体 API：

```java
String userId = AuthInterceptor.requireUserId(request);  // 未登录 → 401
boolean session = AuthInterceptor.isSession(request);    // 浏览器会话 or Token
```

这样 Controller 对"凭证怎么来的"无感知，Token 与 Session 走同一条业务路径。

## 4. 前端结构

```text
src/
├── api/          # 每个后端领域一个文件，只做请求 + 类型
├── stores/       # Pinia：auth（登录态）、theme、ui（布局状态）
├── composables/  # 可复用逻辑（快捷键、代码复制）
├── router/       # 公开域 / 私有域两套路由表
├── utils/        # 纯函数：格式化、Markdown、Diff、记账展示
├── views/        # private/ 与 public/ 两组页面
└── components/   # 跨页面组件
```

### 公开域与私有域

同一份构建产物服务两种站点，**启动时按域名决定用哪套路由**：

```text
GET /api/app-config → { version, private_hosts: ["note.example.com"] }
  ├─ 当前域名在列表里 → 私有域（登录、编辑、记账）
  └─ 否则            → 公开域（只读笔记、作品集）
```

这样不用打两份包，也不用维护两套部署。

### 请求体命名转换

后端 DTO 是 record（camelCase），对外 JSON 是 `snake_case`。响应由 Jackson 的 `SNAKE_CASE` 策略生成；**请求体由前端统一转换**：

```ts
// api/client.ts
JSON.stringify(toCamelCaseKeys(body))   // { tag_ids: [] } → { tagIds: [] }
```

所以前端各 `api/*.ts` 里仍然按 `snake_case` 写，读起来与后端文档一致。

## 5. 关键设计决策

### 5.1 为什么用 DTO 而不是 Map

早期全站用 `Map<String,Object>` 作为出入参（269 处）。后果：

- 字段拼错只在运行时 500
- 无法 `@Valid`，校验只能手写在 service
- 前端只能靠猜字段名

现在每个领域一个 DTO 容器（如 `NoteDtos`、`LedgerDtos`）或独立 record 文件，**契约在编译期可校验**。

### 5.2 为什么金额用整数分

见 [data-model.md](data-model.md#金额)。简单说：浮点会丢精度，`numeric` 运算慢且需要额外依赖，整数分是支付行业的标准做法。

### 5.3 为什么统一注入 `Clock`

业务里散落 `OffsetDateTime.now()` 的后果：

- 测试无法固定时间，只能用 `Thread.sleep` 或放宽断言
- 跨时区部署时，"今天"到底是哪天取决于服务器
- 热力图日界、月度汇总各算各的

现在所有时间都来自 `Clock` bean（`config/ClockConfig`），业务时区可用 `haven.time-zone` 指定。

### 5.4 为什么事务与外部副作用分开

Sa-Token 的 `login` / `logout` 不是数据库操作。如果在 `@Transactional` 方法里调用：

- 会话已建立，事务却回滚了 → 用户"登录成功"但没有数据
- 事务已提交，踢会话失败 → 用户改完密码但旧会话还活着

所以登录与改密由 `AuthSessionOpener` 编排：**先提交数据库，再动会话**。

### 5.5 为什么记账解析器独立成类

`LedgerServiceImpl` 曾是 848 行的巨型类，混着文本解析、CRUD、统计、别名。现在：

| 类 | 职责 | 依赖 |
| --- | --- | --- |
| `LedgerTextParser` | 金额 / 日期语法 | 只有 `Clock` |
| `LedgerClassifier` | 分类 / 方向判定 | 无 |
| `LedgerStatsCalculator` | 汇总计算 | 无 |
| `LedgerServiceImpl` | 编排 + 事务 | Mapper |

解析与统计因此可以**纯单元测试**，不用起 Spring 上下文。详见 [ledger.md](ledger.md)。

### 5.6 为什么用 `@RequireAccess` 而不是看 HTTP 方法

「只读 Token 只能 GET」这个规则有个洞：如果有 GET 接口会写数据（同步、清理、导出），只读 Token 就能越权。

现在端点可以显式声明权限级别（`READ / WRITE / SESSION / SESSION_TOTP`），注解优先、方法兜底。详见 [auth.md](auth.md)。

## 6. 已知限制

| 限制 | 影响 | 解除方式 |
| --- | --- | --- |
| Sa-Token 会话在内存 | 重启掉线、多实例不共享 | 接入 `sa-token-jdbc` 或 Redis |
| 登录失败计数在内存 | 多实例下上限被放大为「实例数 × 上限」 | 换成 Redis 计数器 |
| 单用户设计 | 没有注册页，账号靠 SQL 创建 | 需要的话补注册流程 |
| 无多币种 | 记账只有人民币 | 加 `currency` 字段（当前不需要） |
| Actuator 不在拦截器范围 | `/actuator/**` 需网关保护 | 生产用反向代理限制 |
| 上传文件匿名可读 | 靠随机文件名保密 | 需要严格私密时改成鉴权代理 |
