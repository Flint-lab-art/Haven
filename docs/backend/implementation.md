# 后端实现细节

本文件补充 [docs/](../README.md) 中架构与契约层面没展开的实现细节。整体设计见
[architecture.md](../architecture.md)、[api-conventions.md](../api-conventions.md)、[auth.md](../auth.md)。

## 1. 启动与装配

`BackendApplication` 做三件事：

1. `@MapperScan` 扫描各领域的 Mapper 包（含 `audit`）
2. Spring Boot 自动装配 Web / JDBC / Flyway / Actuator
3. 启动后打印精简的 Sa-Token 配置（**不打印整个 config**，避免未来扩展带入敏感项）

`@MapperScan` 的包列表需要手工维护，新增领域时别漏。

## 2. 基础设施组件

| 组件 | 位置 | 作用 |
| --- | --- | --- |
| `ClockConfig` | `config/` | 提供 `Clock` bean，业务时区可配 |
| `WebConfig` | `config/` | SPA 路由回退，保留 Spring 的路径校验 |
| `MybatisPlusConfig` | `config/` | 分页插件、`uuid` TypeHandler 注册 |
| `SaTokenConfigure` | `auth/config/` | 注册 `AuthInterceptor`，排除公开路径 |
| `AuthInterceptor` | `auth/interceptor/` | 双通道认证 + 权限校验 |
| `GlobalExceptionHandler` | `exception/` | 统一错误契约 |
| `AuditRecorder` | `audit/` | 审计事件写入（尽力而为） |

### WebConfig 的 SPA 回退

```java
Resource found = super.getResource(resourcePath, location);   // 先走 Spring 的安全校验
if (found != null) return found;
return indexHtml();                                          // 再回退 SPA 入口
```

**必须调用 `super`**：自定义实现如果直接 `createRelative`，会绕过
`isResourceUnderLocation` 等防护。

`api/` 与 `uploads/` 前缀不回退，保持 404 语义。

## 3. 上传

### 写入

```java
public UploadResult upload(MultipartFile file, String kind) {
    if (file.getSize() > MAX_UPLOAD_BYTES) throw new BizException(413, "...");  // 先按声明大小拒绝
    byte[] data = in.readNBytes((int) MAX_UPLOAD_BYTES + 1);                    // 再流式读 + 二次校验
    ...
}
```

不要用 `file.getBytes()`——会把超大文件整个读进堆内存。

- 上限 10 MiB，`MaxUploadSizeExceededException` 由全局处理器转 413
- MIME 用**文件头魔数**检测，不信任 `Content-Type`
- 文件名随机 32 位十六进制，落盘前写 `.part` 再 rename（避免半文件）

### 托管

`UploadsStaticController` 的安全约束：

```java
Path root = Path.of(uploadRoot).toAbsolutePath().normalize();
Path filePath = root.resolve(relativePath).normalize();
if (!filePath.startsWith(root)) return 404;     // 规范化后再判包含关系
if (!Files.isRegularFile(filePath)) return 404;
```

只检查 `contains("..")` 不够——`a/../../etc/passwd` 会被规范化绕过。

## 4. 查询约定

### 聚合下推

统计类接口一律在 SQL 里聚合，不要把全表数据拉进内存：

```java
// NotesMapper
@Select("SELECT COALESCE(SUM(char_length(regexp_replace(...))), 0)::bigint FROM notes WHERE ...")
long sumContentLength(@Param("userId") UUID userId);

@Select("SELECT (updated_at AT TIME ZONE #{zone})::date AS day, COUNT(*) AS cnt ... GROUP BY 1")
List<DailyCount> countByUpdatedDay(...);
```

`StatsServiceImpl` 单请求的 SQL 数量从约 160 条降到约 9 条。

### 批量关联

列表页禁止逐条查关联：

```java
// NoteTagsMapper
@Select("<script>SELECT nt.note_id, t.id, t.name FROM note_tags nt JOIN tags t ON t.id = nt.tag_id
        WHERE t.user_id = #{userId} AND nt.note_id IN
        <foreach collection="noteIds" item="id" open="(" separator="," close=")">#{id}</foreach>
        </script>")
List<NoteTag> selectTagsForNotes(...);
```

取回后按 `noteId` 分组，100 条笔记从 200+ SQL 降到 2 SQL。

### 分页

```java
// 现状：wrapper.last("LIMIT " + lim + " OFFSET " + off)
// lim/off 已收敛为 int，无注入风险；但 MyBatis-Plus 的 Page 更干净
int lim = Math.clamp(limit, 1, 100);
int off = Math.max(offset, 0);
```

新增代码优先用 `Page<T>` 或 Mapper 参数化分页。

## 5. 并发与幂等

| 场景 | 现状 | 备注 |
| --- | --- | --- |
| 记账批次 | `insertIfAbsent` + `(user_id, batch_id)` 主键 | 可靠 |
| 标签创建 | 先查后插 | 并发下可能撞唯一约束 → 500，建议捕获转 409 |
| 文件夹同名 | 先查后插 | 表上无唯一索引兜底 |
| 笔记 `sort_order` | `max + 1` | 并发会重复 |
| 条目 / Issue 更新 | `updateById` 全字段覆盖 | 无乐观锁，并发丢更新 |

这些都是已知缺口，改动相关代码时优先补乐观锁或条件更新。

## 6. TypeHandler

PostgreSQL 的 `uuid` 与 `uuid[]` 需要显式映射：

```java
@TableField(value = "user_id", typeHandler = UuidTypeHandler.class)
private UUID userId;
```

- `UuidTypeHandler`：`uuid` ↔ `UUID`
- `UuidListTypeHandler`：`uuid[]` ↔ `List<UUID>`，只在 `@TableField` 上显式注册

**不要**给 `UuidListTypeHandler` 加包级扫描——`@MappedTypes(List.class)` 会劫持所有 `List` 字段。

## 7. 配置分层

| 文件 | 内容 |
| --- | --- |
| `application.yaml` | 公共配置（含 Sa-Token），profile 由 `SPRING_PROFILES_ACTIVE` 决定，默认 `dev` |
| `application-dev.yaml` | 本地开发：数据源默认值、上传、Actuator 详情、登录限流阈值 |
| `application-prod.yaml` | 生产模板：全部走环境变量，Actuator 只留 health |
| `application-test.yaml`（test 资源） | 测试：数据源由 `TestDatabaseInitializer` 注入 |

### 环境变量

| 变量 | 说明 |
| --- | --- |
| `SPRING_PROFILES_ACTIVE` | `dev` / `prod` |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | 数据源 |
| `HAVEN_PRIVATE_HOSTS` | 私有域域名，逗号分隔 |
| `HAVEN_UPLOAD_DIR` | 上传目录 |
| `HAVEN_TOTP_ISSUER` | 动态码发行方 |
| `HAVEN_TIME_ZONE` | 业务时区 |
| `HAVEN_AUTH_LOGIN_MAX_ATTEMPTS` 等 | 登录限流阈值 |

## 8. 新增一个领域要改哪些地方

以"新增 `bookmark` 领域"为例：

1. `bookmark/` 下建 `controller / dto / entity / mapper / service / service/impl`
2. `BackendApplication` 的 `@MapperScan` 加 `com.haven.backend.bookmark.mapper`
3. 迁移脚本 `V<n>__bookmark.sql`
4. 前端 `api/bookmark.ts` + 路由 + 页面
5. 需要的话在 `SaTokenConfigure` 的排除列表加公开路径
6. 文档：`docs/` 补一节，`backend/README.md` 的 API 表补行
