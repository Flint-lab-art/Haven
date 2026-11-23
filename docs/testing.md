# 测试

## 1. 现状

| 类型 | 数量 | 说明 |
| --- | ---: | --- |
| 后端测试 | 163 个用例（28 个测试类） | JUnit 5 + Mockito + Spring Boot Test |
| 前端测试 | 232（31 个文件） | Vitest + jsdom |
| 端到端测试 | 76 个用例（8 个 spec） | Playwright + Chromium，跑打包后的真实产物 |

### 为什么还要 E2E

这轮重构中出现了 4 个「类型检查与单元测试全绿、功能却不可用」的 bug：

| # | bug | 为什么单测测不到 |
| --- | --- | --- |
| 1 | Jackson 3 命名策略 | 字段静默丢失，接口返回 200 |
| 2 | `updateById` 跳过 null | 字段没改，接口返回 200 |
| 3 | 漏 `import IconPicker` | 组件渲染为空，无报错 |
| 4 | 图标面板挂错 DOM 层级 | 状态正确但被 `overflow` 裁掉不可见 |

jsdom **不做布局计算**，所以第 3、4 类只有真实浏览器能发现。
E2E 就是补这一层：它测的是「用户点下去会看到什么」，而不是「函数返回什么」。

### 后端测试分布

| 类型 | 测试类 |
| --- | --- |
| 纯单元（无 Spring） | `LedgerTextParserTest`、`LedgerClassifierTest`、`LedgerStatsCalculatorTest`、`LedgerRepaymentCategoryTest`、`LedgerTokenCategoryTest`、`LedgerSubscriptionCategoryTest`、`TotpUtilTest`、`LoginAttemptLimiterTest`、`ClockConfigTest`、`AuthServiceImplTest`、`AuditRecorderTest`、`NotesServiceImplTest`、`FoldersServiceImplTest`、`UploadsServiceImplTest`、`StatsServiceImplTest`、`GlobalExceptionHandlerTest`、`WebConfigTest`、`UploadsStaticControllerTest`、`NoteVersionSnapshotTest` |
| Web 层契约 | `NotesControllerWebTest`、`AuthInterceptorTest` |
| 事务传播 / 契约 | `LoginLogsTest`（`REQUIRES_NEW` 日志在外层回滚后仍保留）、`ReadOnlyTransactionTest`、`RequestBodyContractTest`、`NullFieldUpdateTest` |
| 需要数据库 | `LedgerSmokeTest`、`LedgerConstraintTest`、`NotesMapperAggregationTest`、`TestDatabaseSupportTest`、`BackendApplicationTests` |

```bash
./scripts/test.sh all        # 前后端都跑
./scripts/test.sh backend    # spotless + checkstyle + 测试
./scripts/test.sh frontend   # vue-tsc + vitest
```

## 2. 测试数据库（后端）

### 为什么不能直连开发库

早期的 `@SpringBootTest` 直接读 `dev_db`：

- 测试之间互相污染
- 误执行 `flyway:clean` 会清掉本地开发数据
- 本机没装数据库或版本不对就跑不了

### 现在的三级策略

`backend/src/test/java/com/haven/backend/support/TestDatabaseSupport.java`

| 优先级 | 模式 | 触发 |
| --- | --- | --- |
| 1 | Testcontainers PostgreSQL | `-Dhaven.test.mode=container` |
| 2 | **独立测试库（默认）** | 无需配置 |
| 3 | 报错退出 | 前两者都不可用 |

> **不会静默回落到开发库**。两者都失败时抛异常并给出修复指引。

### 独立测试库怎么工作

```
1. 连维护库（默认 postgres，回退 dev_db），账号 dev
2. 断开该库上的残留连接 → DROP DATABASE IF EXISTS haven_test_db → CREATE DATABASE
3. 在测试库里 CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public
4. Flyway 在空库上完整迁移（含 V16 的 note / issue / ledger schema）
5. 数据源 URL 直接指向 haven_test_db，不带 search_path
```

可通过 `TEST_DB_NAME` 改库名，`TEST_DB_HOST` / `TEST_DB_PORT` 改实例，`TEST_DB_URL` 整体覆盖 URL，`TEST_DB_USERNAME` / `TEST_DB_PASSWORD` 改账号。

**测试账号需要 `CREATEDB` 权限**：`ALTER ROLE dev CREATEDB`（管理员执行一次）。

### 为什么不再用临时 schema

V16 起业务表按模块分在 `note` / `issue` / `ledger`，而 **PostgreSQL 的 schema 不能嵌套**：
临时 schema 里建不出 module schema，迁移里的 `CREATE SCHEMA note` 会直接落到库顶层，污染开发库。
所以改用独立数据库，迁移路径与生产完全一致。

### pg_trgm 的坑

迁移里有 `gin_trgm_ops` 索引，扩展必须装在**测试库自己的 `public`** 里，
否则会报 `operator class "gin_trgm_ops" does not exist`。
独立测试库方案下 `search_path` 保持默认（`"$user", public`），不再需要手工拼 `options`。

也不要改回 `currentSchema` / `search_path` 方案——见上一节的原因。

## 需要数据库的测试

加 `@ActiveProfiles("test")`：

```java
@SpringBootTest
@ActiveProfiles("test")
class LedgerSmokeTest { ... }
```

## 3. 后端测试的套路

### 3.1 纯单元测试（首选）

依赖少的类直接 new，不用 Spring：

```java
class LedgerTextParserTest {
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-01-02T08:00:00Z"), ZoneOffset.UTC);
    private LedgerTextParser parser;

    @BeforeEach
    void setUp() {
        parser = new LedgerTextParser(CLOCK, new LedgerClassifier());
    }
}
```

**时间永远用固定 Clock**，不要用 `Thread.sleep` 或放宽断言。

### 3.2 Mockito 单测

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)   // 仅在确实有共用 stub 时使用
class AuthServiceImplTest { ... }
```

注意 `UnnecessaryStubbingException`：Mockito 默认是 strict，多余的 `when()` 会让测试失败。
公共 stub 抽到 `@BeforeEach` 并加 `LENIENT`，或用 `lenient()`。

### 3.3 Web 层契约测试

`@WebMvcTest` 切片在本项目会连带装配 `AuthInterceptor`（依赖 Mapper → 需要 `SqlSessionFactory`），
因此 **用 `MockMvcBuilders.standaloneSetup`** 只装配目标 Controller 与 `GlobalExceptionHandler`：

```java
mockMvc = MockMvcBuilders
        .standaloneSetup(new NotesController(notesService), new TagsController(tagsService))
        .setControllerAdvice(new GlobalExceptionHandler())
        .build();

mockMvc.perform(get("/api/notes").with(user()))
        .andExpect(status().isOk());
```

身份用 `RequestPostProcessor` 写进请求属性，与真实拦截器的注入方式一致：

```java
private static RequestPostProcessor user() {
    return request -> {
        ((MockHttpServletRequest) request).setAttribute(AuthInterceptor.ATTR_USER_ID, USER_ID);
        return request;
    };
}
```

### 3.4 数据库约束测试

PostgreSQL 有个关键行为：**事务内触发约束错误后，整个事务进入 aborted 状态**（`25P02`），
后续语句全部失败。所以：

```java
// 错误：三次 assertThrows 在同一事务里，第二次就会因为事务已 abort 而报错
assertThrows(...); assertThrows(...); assertThrows(...);

// 正确：每个用例包进 REQUIRES_NEW 子事务，单独回滚
private <T> T inRolledBackTransaction(Supplier<T> action) {
    TransactionTemplate template = new TransactionTemplate(transactionManager);
    template.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    return template.execute(status -> {
        try { return action.get(); }
        finally { status.setRollbackOnly(); }
    });
}
```

「应当成功」的用例也要在子事务内**写入 + 读回**，再回滚（否则回滚后查不到数据）。

### 3.5 测试命名

```java
@Test
@DisplayName("非法 UUID 路径参数返回 400 而不是 500")
void invalidUuidReturns400() { ... }
```

方法名用 `方法_条件_期望` 或短句，`@DisplayName` 写中文说明。

## 4. 前端测试

```bash
pnpm test           # 单次
pnpm test:watch     # 监听
```

- 纯函数（`utils/*`）优先测，不测组件内部实现
- `__tests__/*.test.ts` 按模块组织
- 组件测试用 `@vue/test-utils`，避免断言具体 DOM 结构

## 4.1 请求体契约测试（重要）

项目用 **Jackson 3**（`tools.jackson`），`spring.jackson.property-naming-strategy=SNAKE_CASE`
在**反序列化时同样生效**：DTO 只认 `snake_case`，收到 `camelCase` 会被**静默忽略**。

后果分两档：

| 字段类型 | 表现 |
| --- | --- |
| 必填（`@NotBlank`） | 400「不能为空」——容易发现 |
| 可空（`Boolean` / `Integer`） | **静默变成 `null`**——功能失效但界面正常 |

这类问题类型检查、单元测试、手点主流程都可能漏掉。曾经真的发生过：
前端加了 `snake_case → camelCase` 转换，196 个前端测试 + 121 个后端测试全绿，
但登录、改密、Token 创建全部失效，登录页「信任这台设备」静默不生效。

### 两侧各有一道闸

| 位置 | 文件 | 作用 |
| --- | --- | --- |
| 后端 | `contract/RequestBodyContractTest` | 用**容器里的** `ObjectMapper` 把"前端实际会发的 JSON"反序列化成 DTO，断言字段绑上了值 |
| 前端 | `__tests__/request-body-contract.test.ts` | 拦截 `fetch`，断言 `client.ts` 发出的 body 键名保持 `snake_case` |

两处都做过反证：故意让 DTO 字段名不一致、或在前端加回键名转换，测试都会立刻失败。

### 新增 `@RequestBody` DTO 时

1. 在 `RequestBodyContractTest` 加一个用例，**固定前端会发的 JSON**
2. 断言所有**可空字段**也被绑定（`assertNotNull` / `assertEquals(Boolean.TRUE, ...)`）
3. 不要自己 `new ObjectMapper()`——必须注入容器里的那个，否则测不到命名策略

## 5. 端到端测试（Playwright）

```bash
pnpm --dir frontend exec playwright install chromium   # 首次：下载浏览器（走 npmmirror 镜像）
./scripts/test.sh e2e        # 构建产物 + 跑全部 E2E
./scripts/test.sh frontend   # 类型检查 + vitest + E2E
pnpm --dir frontend e2e:ui   # 可视化调试
```

### 跑的是什么

E2E **不连开发库，也不连 Vite dev server**：

| 项 | 做法 | 原因 |
| --- | --- | --- |
| 被测应用 | `java -jar` 起打包后的后端（自带前端静态资源） | 测真实部署形态：同源、无代理、静态托管一致 |
| 数据隔离 | 独立数据库 `haven_e2e_db`，每次运行 DROP + CREATE 重建 | V16 后模块 schema 不能嵌套，只能靠独立库隔离 |
| 数据库 | 默认 `127.0.0.1:5432` / `dev` / `123456` | 用 `E2E_DB_*` 覆盖 |
| 端口 | `18099` | 用 `E2E_PORT` 覆盖 |
| 浏览器来源 | `.npmrc` 里 `PLAYWRIGHT_DOWNLOAD_HOST` 指向 npmmirror | 官方 CDN 在国内经常超时 |

`e2e/start-server.mjs` 负责重建数据库并拉起后端，由 Playwright 的 `webServer` 自动管理生命周期。
`e2e/fixtures.ts` 在每个用例前清空业务表并重建测试账号（`e2e-user` / `e2e-password-123`，BCrypt cost 4）。
清理清单直接写在 `fixtures.ts` 的 `resetDatabase()` 里——**新增表要记得加进去**，否则上个用例的数据会漏到下一个用例。

两条容易踩的坑：

- **不能清 `ledger.ledger_categories`**：分类是 V18/V19 迁移预置的种子数据，清掉后依赖「餐饮 · 午餐」这类固定分类的用例会全线失败。只清用例产生的账户、预算与流水。
- **表被迁移删掉后要同步删清理语句**：V20 删了 `ledger_batches` / `ledger_aliases`，清理 SQL 若还留着会整轮夹具崩溃（每个用例都从这一步开始，所以是全红而不是个别失败）。

所有用例都访问 `http://localhost:18099`：只有一张路由表，不存在"换 hostname 换站点"的分支。

### 用例组织

| 文件 | 覆盖 |
| --- | --- |
| `auth.spec.ts` | 登录、错误提示、redirect 回跳、登出、`/api/me` |
| `auth-sensitive.spec.ts` | 改密 / TOTP / Token / 授信设备等敏感操作的权限与失效链路 |
| `notes.spec.ts` | 新建、自动保存落库、正文可搜索、删除/还原/永久删除、历史版本、移动文件夹 |
| `note-versions.spec.ts` | 版本快照语义（存「修改前」）、还原、无变化不产生版本 |
| `folders-tags.spec.ts` | 文件夹增删改、嵌套层级、**图标面板可见性**、删除文件夹时笔记回收件箱、标签 |
| `ledger.spec.ts` | 记一笔、**转账不计收支且两侧余额正确**、小数精度、二级归一级、切月份、编辑、删除、无账户引导 |
| `mobile.spec.ts` | `/m/` 三个 tab、记账抽屉（分类网格 + 数字键盘）、统计四粒度与图表形态、我的、账户、Issue 列表/新建/改状态 |
| `issues.spec.ts` | 新建、状态流转、按状态过滤、时间线、编辑、删除 |
| `settings.spec.ts` | 概览、主题持久化、账号安全、**登录日志页记录本次登录**、会话、授信设备、Token（含只读 Token 不能写） |

### 写用例的两条约定

1. **造数据走 API，验证行为走界面**。`e2e/api.ts` 提供 `createApi(request)`；
   每一步都点界面会让用例长到没人愿意读，失败时也分不清是造数据错了还是被测行为错了。
2. **断言用户能看到的结果，不重复断言接口**。涉及「接口返回 200 但数据没改」的场景，
   要么重新加载页面再断言，要么另写一条纯 API 契约用例（如 `note-versions.spec.ts`）。

### 常见坑

| 现象 | 原因 |
| --- | --- |
| 找不到笔记树里的笔记 | `POST /api/notes` 不传 `folder_id` 时笔记不属于任何文件夹，界面不展示 |
| `getByRole('dialog')` 匹配不到确认框 | `ConfirmDialog` 用的是 `alertdialog` |
| 严格模式报「resolved to 2 elements」 | 页面上有同名按钮（如列表栏「添加」与表单提交「添加」），需收窄到容器 |
| 单跑通过、整套跑失败 | 用了不会自动等待的取值方法，见下 |

### 不会自动等待的取值方法（重要）

`expect(locator)` 系列会自动等待，但下面这些**立即返回**：

```ts
await locator.count()        // 元素还没渲染 → 0
await locator.inputValue()   // 输入框还没填值 → ''
await locator.boundingBox()  // 元素还没布局 → null
await locator.evaluate(...)  // 同上
```

在它们之前必须先插入一个会等待的断言：

```ts
// ✗ 页面还在挂载，count() 直接返回 0
const n = await page.getByRole('radio').count()
expect(n).toBeGreaterThan(1)

// ✓ 先等元素出现
const radios = page.getByRole('radio')
await expect(radios.first()).toBeVisible()
expect(await radios.count()).toBeGreaterThan(1)
```

这类问题**只跑单个 spec 往往发现不了**：套件里的首个 spec 加载最慢，最容易踩到。验证时用：

```bash
pnpm --dir frontend exec playwright test --repeat-each=2
```

## 6. 测试清单（新增功能时）

- [ ] 新端点：状态码 + 错误响应体（Web 层测试）
- [ ] 新业务规则：正常路径 + 边界 + 非法输入
- [ ] 涉及归属校验：用他人 ID 访问返回 404
- [ ] 涉及时间：用固定 `Clock`
- [ ] 涉及金额：断言分，不断言元
- [ ] 涉及分类/枚举：与常量表一致性测试
- [ ] 新增迁移：能在空库跑通（测试会自动验证）
- [ ] 新增表：把表名加进 `frontend/e2e/fixtures.ts` 的 `resetDatabase()` 清理 SQL
- [ ] 删除表：同步删掉 `resetDatabase()` 里对应语句，否则夹具整轮失败
- [ ] 新增/修改 `@RequestBody` DTO：在 `RequestBodyContractTest` 固定一份实际请求 JSON
- [ ] 新页面或新交互：在 `frontend/e2e/` 加一条对应用例（造数据走 `e2e/api.ts`，断言走界面）

## 7. 已知缺口

| 缺口 | 影响 |
| --- | --- |
| TOTP 绑定 / 关闭的完整流程没有 E2E | 需要真实动态码，靠手工验收；目前只覆盖了「未绑定时可用 Token」 |
| 部分 Controller 没有 Web 层测试 | 主要覆盖了 Notes / Tags |
| 没有并发测试 | 幂等、乐观锁靠代码审查 |
| 上传的真实文件大小限制只测了边界 | 大文件流式读取只做了单元级验证 |
