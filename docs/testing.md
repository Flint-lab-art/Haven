# 测试

## 1. 现状

| 类型 | 数量 | 说明 |
| --- | ---: | --- |
| 后端测试 | 121（23 个测试类） | JUnit 5 + Mockito + Spring Boot Test |
| 前端测试 | 167（22 个文件） | Vitest + jsdom |

### 后端测试分布

| 类型 | 测试类 |
| --- | --- |
| 纯单元（无 Spring） | `LedgerTextParserTest`、`LedgerClassifierTest`、`LedgerStatsCalculatorTest`、`LedgerRepaymentCategoryTest`、`TotpUtilTest`、`LoginAttemptLimiterTest`、`ClockConfigTest`、`AuthServiceImplTest`、`AuditRecorderTest`、`NotesServiceImplTest`、`FoldersServiceImplTest`、`UploadsServiceImplTest`、`PortfolioServiceImplTest`、`StatsServiceImplTest`、`GlobalExceptionHandlerTest`、`WebConfigTest`、`UploadsStaticControllerTest` |
| Web 层契约 | `NotesControllerWebTest`、`AuthInterceptorTest` |
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
| 2 | **临时 schema（默认）** | 无需配置 |
| 3 | 报错退出 | 前两者都不可用 |

> **不会静默回落到开发库**。两者都失败时抛异常并给出修复指引。

### 临时 schema 怎么工作

```
1. 连接本地 PostgreSQL（默认 jdbc:postgresql://127.0.0.1:5432/dev_db，账号 dev）
2. CREATE SCHEMA haven_test_<随机12位>
3. 确保 pg_trgm 扩展在 public
4. 数据源 URL: ?options=-c search_path=<schema>,public   ← 关键
5. Flyway 在空 schema 上完整迁移
6. JVM 退出时 DROP SCHEMA CASCADE
7. 下次启动先清理上次异常退出遗留的 haven_test_*
```

可通过 `TEST_DB_URL` / `TEST_DB_USERNAME` / `TEST_DB_PASSWORD` 覆盖连接信息。

### pg_trgm 的坑

两个必须同时满足，否则迁移会报 `operator class "gin_trgm_ops" does not exist`：

1. **扩展装在 `public`**：迁移里的 `CREATE EXTENSION IF NOT EXISTS` 只有在扩展已存在于 `public` 时才是空操作
2. **`search_path` 必须包含 `public`**：`gin_trgm_ops` 是扩展提供的 operator class，只在扩展所在 schema 可见

另外，**绝对不要用 `currentSchema` 参数**：pgjdbc 会把它写进 `options`，从而覆盖掉 `search_path`。

```java
// 正确
url + "?options=-c%20search_path%3D" + schema + "%2Cpublic"

// 错误：会丢掉 public
url + "?currentSchema=" + schema + "&options=..."
```

这两个约束由 `TestDatabaseSupportTest` 断言守着。

### 需要数据库的测试

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

## 5. 测试清单（新增功能时）

- [ ] 新端点：状态码 + 错误响应体（Web 层测试）
- [ ] 新业务规则：正常路径 + 边界 + 非法输入
- [ ] 涉及归属校验：用他人 ID 访问返回 404
- [ ] 涉及时间：用固定 `Clock`
- [ ] 涉及金额：断言分，不断言元
- [ ] 涉及分类/枚举：与常量表一致性测试
- [ ] 新增迁移：能在空库跑通（测试会自动验证）

## 6. 已知缺口

| 缺口 | 影响 |
| --- | --- |
| 没有端到端（E2E）测试 | 前后端契约靠类型与手工验证 |
| 部分 Controller 没有 Web 层测试 | 主要覆盖了 Notes / Tags |
| 没有并发测试 | 幂等、乐观锁靠代码审查 |
| 上传的真实文件大小限制只测了边界 | 大文件流式读取只做了单元级验证 |
