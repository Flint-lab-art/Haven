# 开发约定

## 1. 提交前必须通过

```bash
./scripts/test.sh all     # 后端 spotless + checkstyle + 测试；前端 vue-tsc + vitest
```

只改了某一端时：

```bash
./scripts/test.sh backend
./scripts/test.sh frontend
```

格式化不通过时：

```bash
cd backend && ./mvnw spotless:apply
```

> 当前基线：后端 121 个测试、前端 167 个测试，全部通过才算"改完"。

## 2. 后端约定

### 2.1 分层

| 层 | 做什么 | 不做什么 |
| --- | --- | --- |
| Controller | 绑定、`@Valid`、调 service、返回 DTO | 业务判断、SQL、事务 |
| Service | 业务、事务、归属校验、DTO 转换 | 返回 entity、吞异常 |
| Mapper | 数据访问、参数化聚合 | 拼接用户输入 |
| Entity | 与表对应 | 越过 service 边界 |

### 2.2 返回类型

**禁止 `Map<String, Object>` 作为出入参。**

```java
// 禁止
public Map<String, Object> list(...)

// 必须
public NotePage list(...)          // record
public PageResponse<NoteSummary> list(...)   // 通用分页
```

DTO 放在各领域的 `dto` 包，用 `record`。允许的 Map 用法只剩内部工具方法。

### 2.3 校验

校验注解写在 DTO 上：

```java
public record CreateTagRequest(
        @NotBlank(message = "标签名不能为空")
        @Size(max = 64, message = "标签名不能超过 64 个字符")
        String name) {}
```

service 不再重复写"参数不能为空"——除非是跨字段或依赖数据库状态的规则。

### 2.4 事务

```java
@Transactional                       // 写：新增/修改/删除
@Transactional(readOnly = true)      // 读：查询
```

- 事务只在 service 层
- 多表写入必须同事务
- **事务内不做外部副作用**（Sa-Token、文件 IO、HTTP 调用）

### 2.5 时间

```java
// 禁止
OffsetDateTime.now()

// 必须
private final Clock clock;
OffsetDateTime.now(clock)
```

`Clock` 由 `config/ClockConfig` 提供。业务时区用 `haven.time-zone` 配置。

### 2.6 金额

- 存储与传输都是**整数分**（`long` / `bigint`）
- 字段名统一 `amountCents` / `amount_cents`
- 转换必须用 `setScale(0, RoundingMode.UNNECESSARY).longValueExact()`，禁止静默截断
- 格式化（`¥12.34`）在前端做

### 2.7 异常

```java
throw BizException.notFound("笔记不存在");       // 404
throw BizException.validation("标题不能为空");   // 422
throw BizException.forbidden("只读 Token 无写权限"); // 403
```

- 业务失败抛 `BizException`，不要返回 `null` 或空对象表达失败
- 包装异常时保留 `cause`
- 日志里不要拼接完整异常消息当作唯一信息

### 2.8 权限

```java
// 取当前用户（未登录 → 401）
String userId = AuthInterceptor.requireUserId(request);

// 按 ID 访问资源时必须校验归属
private Note getOwnedNote(UUID userId, UUID noteId) {
    Notes note = notesMapper.selectById(noteId);
    if (note == null || !note.getUserId().equals(userId)) {
        throw BizException.notFound("笔记不存在");   // 不存在与无权限统一 404
    }
    return note;
}
```

新增端点时确认是否需要 `@RequireAccess`（见 [auth.md](auth.md#3-授权级别)）。

### 2.8.1 把字段更新为 null 必须用 UpdateWrapper

MyBatis-Plus 的 `updateById` 默认**跳过 null 字段**（`FieldStrategy.NOT_NULL`）：

```java
// 错误：不会生成任何清空语句，但接口返回 200
note.setDeletedAt(null);
note.setUpdatedAt(now);
notesMapper.updateById(note);

// 正确：显式 set null
notesMapper.update(
        new Notes(),
        new LambdaUpdateWrapper<Notes>()
                .eq(Notes::getId, noteId)
                .eq(Notes::getUserId, uid)
                .set(Notes::getDeletedAt, null)
                .set(Notes::getUpdatedAt, now));
```

这个坑非常隐蔽：**`updated_at` 会变，目标字段纹丝不动**，界面上看起来「点了没反应、也不报错」。
项目里踩过的四处：回收站还原（`deleted_at`）、笔记移到根目录（`folder_id`）、
文件夹移到根目录（`parent_id`）、关闭 TOTP（`totp_secret`）。

由 `note/NullFieldUpdateTest` 守着；新增"清空某个字段"的写操作时，照着它补一个用例。

### 2.8.2 `readOnly = true` 只能给纯查询

`@Transactional(readOnly = true)` 会让 PostgreSQL 把整个事务设为只读，
里面任何 UPDATE 都会抛 `cannot execute UPDATE in a read-only transaction`（SQL state 25006），
最终表现为 **500**。

踩过的坑：`AuthServiceImpl.loginPrecheck` 看着是「校验逻辑」就标了只读，
但它内部会写两类数据，只有特定分支才触发：

| 内部写入 | 触发条件 | 是否抛异常 |
| --- | --- | --- |
| `AuditRecorder.record`（登录失败直接写 `login_logs`，`REQUIRES_NEW`） | 密码错误 | 否——审计是"尽力而为"，内部 `catch (RuntimeException)` 吞掉，**静默失败** |
| `TrustedDeviceService.isTrusted`（刷新 last_used_at） | 设备已授信 | **是**——直接 500 |

判断标准：**方法体（含它调用到的所有 service）只要可能写库，就不能标 readOnly**。
不确定时用 `@Transactional`，读写事务没有副作用，只是少了只读优化。

由 `contract/ReadOnlyTransactionTest` 守着。注意它的写法：

```java
// 必须挂起测试事务，否则外层读写事务会把内层 readOnly 当提示忽略，测不出问题
@Transactional(propagation = Propagation.NOT_SUPPORTED)
```

而且要挑**会真正抛异常的写入路径**；审计这类有 catch 兜底的写入在只读事务下只是静默失败。

### 2.9 常量

```java
// 禁止：裸字符串散落各处
if ("done".equals(issue.getStatus())) { ... }

// 必须：领域常量
if (IssueEnums.Status.DONE.equals(issue.getStatus())) { ... }
```

现有常量类：`IssueEnums`、`LedgerTypes`、`LedgerCategories`、`LoginLogEventType`、
`AuditEventType`、`AuditTargetType`。

### 2.10 日志

```java
log.warn("刷新 API Token last_used_at 失败, tokenId={}", token.getId(), e);
```

- 用占位符，不拼字符串
- 带异常对象，而不是 `e.getMessage()`
- **不打印**密码、Token、正文、TOTP secret

### 2.11 禁止清单

| 禁止 | 原因 |
| --- | --- |
| `printStackTrace()` / `System.out` | 绕过日志框架 |
| `catch (Exception e) {}` 静默吞 | 排查无据 |
| 字段注入（`@Autowired` 字段） | 构造器注入才能保证不可变、可测 |
| `@Data` 用在 DTO | 生成的 `toString` 可能带出密码 |
| 裸 `now()` | 测试不可控 |
| `Map<String,Object>` 出入参 | 契约不可校验 |
| 注释掉的代码块 | 历史交给 git |
| `wrapper.last("LIMIT " + userInput)` | 注入风险（当前只拼了 int） |
| 修改已执行的迁移文件 | Flyway 校验会失败 |

## 3. 前端约定

### 3.1 API 层

`src/api/*.ts` 只做请求与类型，不含状态与业务判断：

```ts
export function listNotes(query: ListNotesQuery = {}): Promise<ListResult<NoteSummary>> {
  return request('/api/notes', { query: { ...query } })
}
```

请求体照常写 `snake_case`，`client.ts` 会转成 camelCase。

### 3.2 类型

- 后端新增/改字段时，同步改 `api/*.ts` 的类型
- 联合类型（如 `LedgerCategory`）必须与后端常量一致，有测试守着

### 3.3 状态

- Pinia store 只管**全局状态**（登录态、主题、布局）
- 页面内部状态用 `ref` / `reactive`，不下沉到 store

### 3.4 渲染

- Markdown 输出必须经过 `utils/markdown.ts` 的清洗（DOMPurify）
- 用户提供的 URL 只能 `http/https`（后端也校验）
- `v-html` 只用于已清洗的内容

### 3.5 组件

- 纯函数逻辑抽到 `utils/`，组件只管渲染与事件
- 可测试的逻辑优先放 utils，组件测试最后考虑

## 4. 发布与版本号

**版本号规则与标准 SemVer 不同**，务必先读 [versioning.md](versioning.md)：

| 位 | +1 的条件 |
| --- | --- |
| MAJOR | 三要素齐备：独立顶级导航入口 + 自己的数据表 + 自己的 CRUD 流程 |
| MINOR | 不加大领域，但有大动作、多个小功能点、或大修复 |
| PATCH | 纯修复，无新增能力 |

版本号**只有一个来源**：根目录 `VERSION` 文件。**不要手工改 `pom.xml` 或 `package.json` 的版本号。**

```bash
./scripts/version.sh set 2.2.0    # 改版本（写 VERSION 并同步到两处）
./scripts/version.sh sync         # 修正漂移
./scripts/version.sh check        # 校验
```

发布前检查：

```bash
./scripts/test.sh all                       # 内含版本号校验
./scripts/build.sh all
ls backend/target/*.jar                     # haven-<version>.jar
curl -s http://127.0.0.1:8080/api/health    # version 与上面一致
```

- 前后端**同版本**，不允许各自演进
- 回滚已发布的版本时**不要复用版本号**，发新的 PATCH
- 文档里的 jar 名示例要跟着改

## 5. 文档约定

- `docs/` 是**权威设计文档**，`README` 只讲怎么跑起来
- 改了架构 / 契约 / 数据模型时同步更新对应文档
- 文档与代码冲突时以代码为准，并修正文档

## 6. 代码审查关注点

按优先级：

| 优先级 | 检查项 |
| --- | --- |
| P0 | 越权、数据丢失、凭据处理、SQL 注入 |
| P1 | 事务边界、契约（DTO）、校验、归属 |
| P2 | N+1、时间来源、魔法值、重复代码 |
| P3 | 命名、注释、格式 |

格式问题交给工具，不要在 review 里讨论缩进。
