# API 契约

## 1. 基本约定

| 项 | 约定 |
| --- | --- |
| 前缀 | 所有接口以 `/api` 开头；匿名可访问的都在 `/api/public/**` |
| 字段命名 | 对外统一 `snake_case` |
| Content-Type | `application/json`（上传除外） |
| 认证 | Cookie 会话 或 `Authorization: Bearer haven_ro_…` / `haven_rw_…` |
| 时间 | ISO-8601 带时区偏移，如 `2026-11-17T10:30:00+08:00` |
| ID | UUID 字符串 |

### 请求体是 camelCase，响应是 snake_case

后端 DTO 用 record（组件名 camelCase），Jackson 把**响应**序列化成 `snake_case`；**请求体**由前端 `api/client.ts` 的 `toCamelCaseKeys` 递归转换后发送。

```ts
// 前端照常写 snake_case
updateNote(id, { tag_ids: [], clear_folder: true })
// 实际发送
{ "tagIds": [], "clearFolder": true }
```

外部调用方（如 iOS 快捷指令）需要**直接发送 camelCase**：

```bash
curl -X POST http://127.0.0.1:8080/api/ledger/entries/quick \
  -H 'Content-Type: application/json' \
  -d '{"text":"午饭 12"}'
```

## 2. 响应结构

### 列表

所有列表统一为：

```json
{ "items": [...], "total": 123 }
```

- `total` 是**满足条件的总数**，不是当前页条数；
- 例外：`/api/ledger/recent`、`/api/tags`、`/api/sessions` 等不分页的接口，`total` 等于 `items.length`。

通用实现在 `dto/PageResponse<T>`；各领域也可用具名 record（如 `NotePage`），结构完全兼容。

### 详情

直接返回对象，不包信封：

```json
{ "id": "...", "title": "...", "tags": [{ "id": "...", "name": "工作" }] }
```

### 错误

```json
{ "error": "validation_failed", "message": "请求参数校验失败", "fields": { "title": "标题不能为空" } }
```

- `fields` 只在字段级校验失败时出现，其他情况不序列化；
- `message` 是给用户看的中文文案，不要再嵌套机器码。

### 错误码表

| `error` | HTTP | 触发场景 |
| --- | --- | --- |
| `bad_request` | 400 | 参数格式错误、非法 UUID、缺参数、坏 JSON |
| `unauthorized` | 401 | 未登录、凭证无效、账号密码错误 |
| `forbidden` | 403 | 只读 Token 写数据、Token 访问会话接口、未过 TOTP |
| `not_found` | 404 | 资源不存在**或不属于当前用户** |
| `conflict` | 409 | 唯一约束冲突、（可选）状态冲突 |
| `payload_too_large` | 413 | 上传超过 10 MiB |
| `unsupported_media_type` | 415 | 上传非图片 |
| `validation_failed` | 422 | `BizException.validation` |
| `too_many_requests` | 429 | 登录 / 动态码失败次数超限 |
| `internal_error` | 500 | 未捕获异常（详情只在服务端日志） |

> **404 不区分"不存在"和"没权限"**。这是刻意的：否则攻击者可以枚举出哪些 ID 真实存在。

## 3. 分页

| 参数 | 默认 | 上限 |
| --- | ---: | ---: |
| `limit` | 20（记账 recent 是 3） | 100 |
| `offset` | 0 | — |

服务层统一收敛：

```java
int lim = Math.clamp(limit, 1, 100);
int off = Math.max(offset, 0);
```

即使传 `limit=-5&offset=-3` 也不会 500（有测试覆盖）。

## 4. 端点总览

### 认证 `/api/auth`

| 方法 | 路径 | 权限 |
| --- | --- | --- |
| POST | `/auth/login` | 匿名 |
| POST | `/auth/login/totp` | 匿名 |
| POST | `/auth/logout` | 登录 |
| GET | `/me` | 匿名可用（可选认证） |
| POST | `/auth/totp/setup` | 会话 |
| POST | `/auth/totp/verify` | 会话 |
| POST | `/auth/totp/disable` | 会话 |
| POST | `/auth/password` | 会话 + TOTP |

### 身份管理

| 方法 | 路径 | 权限 |
| --- | --- | --- |
| GET / DELETE | `/sessions`, `/sessions/{id}` | 会话 |
| GET / DELETE | `/trusted-devices`, `/trusted-devices/{id}` | 会话 |
| GET / POST / DELETE | `/tokens`, `/tokens/{id}` | 会话 + TOTP |

### 笔记 `/api/notes`

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/notes` | 列表，`visibility` / `tagId` / `folderId` / `includeTrash` |
| GET | `/notes/trash` | 回收站 |
| GET / POST / PATCH / DELETE | `/notes/{id}` | 详情 / 新建 / 更新 / 软删除 |
| DELETE | `/notes/trash` | 清空回收站 |
| POST | `/notes/{id}/restore` | 还原 |
| DELETE | `/notes/{id}/purge` | 永久删除 |
| POST | `/notes/{id}/publish`、`/unpublish` | 发布 / 撤回 |
| GET | `/notes/{id}/versions` | 版本列表 |
| GET | `/notes/{id}/versions/{versionId}` | 版本详情 |
| POST | `/notes/{id}/versions/{versionId}/restore` | 还原版本 |

### 文件夹 / 标签

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET / POST | `/folders` | 列表 / 新建 |
| PATCH / DELETE | `/folders/{id}` | 更新 / 删除 |
| GET / POST | `/tags` | 列表 / 新建（**GET 不删任何数据**） |
| DELETE | `/tags/{id}` | 删除 |
| GET | `/tags/{id}/notes` | 标签下的笔记 |

### 搜索

| 方法 | 路径 | 范围 |
| --- | --- | --- |
| GET | `/search?q=` | 私有：笔记 + 标签 |
| GET | `/public/search?q=` | 公开：只搜已发布笔记 |

### 记账 `/api/ledger`

见 [ledger.md](ledger.md)。

### 其他

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/portfolio/{id}`、`/public/portfolio/{id}` | 作品详情 |
| POST / PATCH / DELETE | `/portfolio`、`/portfolio/{id}` | 作品 CRUD |
| POST / PATCH / DELETE | `/portfolio/{id}/repos[/{repoId}]` | 作品链接 |
| GET / POST / PATCH / DELETE | `/issues[/{id}]` | Issue |
| GET | `/stats` | 仪表盘快照 |
| GET | `/health` | 健康检查（匿名） |
| GET | `/app-config` | 运行时前端配置（匿名） |
| POST / GET | `/uploads` | 上传 / 图标列表 |
| GET | `/uploads/**` | 静态文件（匿名） |

## 5. 校验

校验注解写在 DTO 上，service 不再重复写"参数不能为空"：

```java
public record CreateNoteRequest(
        @Size(max = 200, message = "标题不能超过 200 个字符") String title,
        String content,
        List<UUID> tagIds,
        UUID folderId) {}
```

Controller 用 `@Valid @RequestBody` 触发，失败由 `GlobalExceptionHandler` 转成 422 + `fields`。

### 允许"不修改"的更新语义

PATCH 接口里 `null` 表示**不修改**。需要"清空"时用显式布尔字段，而不是靠"字段是否出现在 JSON 里"：

```json
{ "clearFolder": true }     // 移到根目录
{ "clearParent": true }     // 文件夹移到根目录
```

原因：`containsKey` 判空依赖 Jackson 的字段存在性，JSON 里写 `"folderId": null` 与不写无法区分，容易误判。

## 6. 权限声明

端点用注解声明所需权限，拦截器统一校验：

```java
@RequireAccess(RequiredAccess.WRITE)   // GET 但会写数据
@GetMapping("/something")
public ... { }
```

不写注解时按方法兜底：`GET/HEAD/OPTIONS` → `READ`，其余 → `WRITE`。

详见 [auth.md](auth.md#4-授权级别)。
