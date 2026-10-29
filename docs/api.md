# api — HTTP 接口契约

> 本文件回答：每个 HTTP 接口的路径、方法、请求、响应、鉴权要求、错误码。
> 依赖：data-model.md、auth.md

## 一、通用约定

### 1.1 路径规则

- 公开只读接口统一前缀 `/api/public/`，匿名可访问；
- 其余接口一律要求登录，数据按 `user_id = current_user_id` 过滤；
- 路径中不使用版本号。

### 1.2 请求与响应格式

- 请求体与响应体统一为 JSON，`Content-Type: application/json`；
- 时间字段统一用 RFC 3339 字符串，如 `"2026-10-26T12:00:00Z"`；
- id 字段统一为 uuid 字符串；
- 字段命名统一 `snake_case`（前后端 JSON 不转 camelCase）。

### 1.3 成功响应

- 直接返回数据本体，不包 `{code, data}` 外壳；
- 列表接口返回 `{ "items": [...], "total": <int> }`，空列表为 `{"items": [], "total": 0}`，不返回 null；
- 创建成功返回 `201` + 创建后的完整对象；
- 更新成功返回 `200` + 更新后的完整对象；
- 删除成功返回 `204`，无响应体。
- 返回笔记对象的列表接口，item 中一律包含 `content_preview` 字段。正文截断规则见 6.1 备注。


### 1.4 错误响应

统一格式：

```json
{ "error": "unauthorized", "message": "登录已过期" }
```

| HTTP | error | 使用场景 |
|---|---|---|
| 400 | `bad_request` | 请求体格式错误、JSON 解析失败 |
| 401 | `unauthorized` | 未登录、会话过期、Token 无效 |
| 403 | `forbidden` | 已登录但权限不足（如 read Token 做写操作） |
| 404 | `not_found` | 资源不存在，或跨用户访问 |
| 409 | `conflict` | 唯一性冲突（如标签名重复） |
| 422 | `validation_failed` | 字段校验失败，额外带 `fields` |
| 500 | `internal_error` | 服务端错误 |

`422` 响应额外字段：

```json
{ "error": "validation_failed", "message": "字段校验失败", "fields": { "title": "不能为空" } }
```

### 1.5 分页

- 列表接口统一用 `?limit=&offset=`；
- `limit` 默认 20，最大 100；`offset` 默认 0；
- 响应体带 `total` 表示过滤后的总数。

### 1.6 鉴权标注含义

- **匿名**：任何人可访问；
- **登录**：需会话 cookie 或有效 Token（`read` / `read_write` 均可）；
- **登录 + write**：需会话 cookie，或 `scope = read_write` 的 Token；
- **登录 + TOTP**：仅会话 cookie，且会话创建时通过过 TOTP。Token 不可用。

`Authorization: Bearer <token>` 优先于会话 cookie。

### 1.7 更新语义

- `PATCH` 为部分更新：只更新请求体中出现的字段，未出现的字段保持不变；
- 数组类字段（如笔记的 `tag_ids`）如出现，为**全量替换**，不是追加。

---

## 二、认证 `/api/auth`

### 2.1 POST `/api/auth/login`

**鉴权**：匿名

**请求**：

```json
{ "username": "kairo", "password": "xxx", "trust_device": false }
```

- `trust_device`：可选，默认 false。仅在本次登录不需要第二步时立即生效；若返回 `totp_required: true`，此参数暂存于 `pending_logins`，第二步成功后才创建授信设备。

**响应** `200`：

情况一，登录完成（未启用 TOTP 或授信设备有效）：

```json
{ "user": { "id": "...", "username": "kairo" }, "totp_required": false }
```

同时设置会话 cookie（`haven_session`）；若 `trust_device=true`，同时设置授信设备 cookie。

情况二，需要 TOTP：

```json
{ "user": { "id": "...", "username": "kairo" }, "totp_required": true, "temp_token": "..." }
```

不设置会话 cookie。

**错误**：

- `401 unauthorized` — 用户名或密码错误，`message` 统一为“用户名或密码错误”（不区分两者，防枚举）。

**备注**：情况一成功后写 `login_success` 审计事件（`via` 为 `password+totp` 或 `password+trusted_device`）；情况二不算登录成功，不写 `login_success`，第二步成功时才写；密码错误写 `login_failure` 审计事件。

### 2.2 POST `/api/auth/login/totp`

**鉴权**：匿名（凭 `temp_token`）

**请求**：

```json
{ "temp_token": "...", "code": "123456" }
```

**响应** `200`：

```json
{ "user": { "id": "...", "username": "kairo" } }
```

设置会话 cookie；若第一步请求了 `trust_device=true`，同时设置授信设备 cookie。

**错误**：

- `401 unauthorized` — `temp_token` 无效或已过期，`message` 为“登录已超时，请重新登录”；
- `401 unauthorized` — code 错误，`message` 为“动态码错误”。

**备注**：成功后删除 `pending_logins` 记录；写 `login_success` 审计事件（`via` 为 `password+totp`）；失败写 `login_failure` 审计事件（`reason` 为 `bad_totp`）。

### 2.3 POST `/api/auth/logout`

**鉴权**：登录

**请求**：无 body

**响应** `204`

删除当前会话记录，清除会话 cookie；授信设备 cookie 保留。

**备注**：写 `logout` 审计事件。Token 调用此接口无效（Token 无会话可登出），返回 204 但无实际操作。

### 2.4 POST `/api/auth/totp/setup`

**鉴权**：登录

**请求**：无 body

**响应** `200`：

```json
{ "secret": "JBSWY3DPEHPK3PXP", "otpauth_uri": "otpauth://totp/Haven:kairo?secret=...&issuer=Haven" }
```

**错误**：

- `409 conflict` — 用户已启用 TOTP，不能重复 setup。

**备注**：secret 此时**未落库**，仅返回给前端。用户扫码后调 2.5 提交 code 确认，校验通过才落库并置 `totp_enabled=true`。

### 2.5 POST `/api/auth/totp/verify`

**鉴权**：登录

**请求**：

```json
{ "secret": "JBSWY3DPEHPK3PXP", "code": "123456" }
```

- `secret`：2.4 返回的密钥，原样回传；
- `code`：验证器生成的 6 位码。

**响应** `200`：

```json
{ "totp_enabled": true }
```

**错误**：

- `422 validation_failed` — code 格式错误或校验不通过，`fields.code` 说明原因；
- `409 conflict` — 已启用 TOTP。

**备注**：校验通过后 secret 落库到 `users.totp_secret`，`totp_enabled` 置 true；写 `totp_bound` 审计事件。

### 2.6 POST `/api/auth/totp/disable`

**鉴权**：登录 + TOTP

**请求**：

```json
{ "code": "123456" }
```

**响应** `200`：

```json
{ "totp_enabled": false }
```

**错误**：

- `401 unauthorized` — code 校验不通过；
- `422 validation_failed` — 用户尚未启用 TOTP。

**备注**：清空 `users.totp_secret`，`totp_enabled` 置 false，**删除该用户所有授信设备**（否则授信设备失去意义）；写 `totp_disabled` 审计事件。

### 2.7 POST `/api/auth/password`

**鉴权**：登录 + TOTP

**请求**：

```json
{ "old_password": "xxx", "new_password": "yyy", "totp_code": "123456" }
```

**响应** `204`

**错误**：

- `401 unauthorized` — 原密码错误或 TOTP 错误；
- `422 validation_failed` — 新密码不符合要求（≥12 位，且不能与旧密码相同）。

**备注**：成功后在同一事务内删除该用户所有 `sessions` 和 `trusted_devices`，**不删除** `tokens`；写 `password_changed` 审计事件；当前会话也被删除，用户需重新登录。

---

## 三、会话 `/api/sessions`

### 3.1 GET `/api/sessions`

**鉴权**：登录

**响应** `200`：

```json
{
  "items": [
    {
      "id": "...",
      "user_agent": "Mozilla/5.0 ...",
      "created_at": "2026-10-26T12:00:00Z",
      "last_used_at": "2026-10-26T12:30:00Z",
      "is_current": true
    }
  ],
  "total": 1
}
```

- `is_current`：是否当前请求所用的会话，前端据此标注“当前设备”，不可撤销。

**备注**：Token 调用返回 403（Token 无法查看会话）。

### 3.2 DELETE `/api/sessions/:id`

**鉴权**：登录

**响应** `204`

**错误**：

- `404 not_found` — 会话不存在或不属于当前用户；
- `422 validation_failed` — 试图撤销当前会话（请用 `POST /api/auth/logout`）。

**备注**：写 `session_revoked` 审计事件。

---

## 四、授信设备 `/api/trusted-devices`

### 4.1 GET `/api/trusted-devices`

**鉴权**：登录

**响应** `200`：

```json
{
  "items": [
    { "id": "...", "device_name": "家里台式机", "created_at": "...", "last_used_at": "...", "expires_at": "..." }
  ],
  "total": 1
}
```

**备注**：Token 调用返回 403。

### 4.2 DELETE `/api/trusted-devices/:id`

**鉴权**：登录

**响应** `204`

**错误**：

- `404 not_found` — 设备不存在或不属于当前用户。

**备注**：撤销即删除记录；写 `trusted_device_revoked` 审计事件。

**说明**：**不提供 `POST /api/trusted-devices`**。授信设备只能在登录时通过 `trust_device=true` 在那台设备上创建——授信的本质是“这台浏览器可信”，脱离那台浏览器创建设备没有意义。手动添加接口会产生“创建的设备凭证怎么传给目标设备”的难题，本期不做。

---

## 五、API Token `/api/tokens`

### 5.1 GET `/api/tokens`

**鉴权**：登录 + TOTP

**响应** `200`：

```json
{
  "items": [
    {
      "id": "...",
      "name": "TUI @ 家里",
      "token_prefix": "haven_ro_",
      "scope": "read",
      "expires_at": null,
      "last_used_at": "2026-10-26T12:30:00Z",
      "revoked_at": null,
      "created_at": "..."
    }
  ],
  "total": 1
}
```

**备注**：只返回前缀，不返回明文；已撤销的 Token 也列出（`revoked_at` 非 null）。

### 5.2 POST `/api/tokens`

**鉴权**：登录 + TOTP

**请求**：

```json
{ "name": "TUI @ 家里", "scope": "read", "expires_at": null }
```

- `scope`：必填，`read` 或 `read_write`；
- `expires_at`：可选，RFC 3339 时间；null 表示永不过期。

**响应** `201`：

```json
{
  "id": "...",
  "name": "TUI @ 家里",
  "token": "haven_ro_AbCdEfGh...",
  "token_prefix": "haven_ro_",
  "scope": "read",
  "expires_at": null,
  "created_at": "..."
}
```

- `token` 为明文，**仅此次返回，之后无法再获取**。

**错误**：

- `422 validation_failed` — name 为空、scope 非法等。

**备注**：写 `token_created` 审计事件（metadata 含 `name`、`scope`、`token_prefix`，**不含明文**）。

### 5.3 DELETE `/api/tokens/:id`

**鉴权**：登录 + TOTP

**响应** `204`

**错误**：

- `404 not_found` — Token 不存在或不属于当前用户；
- `422 validation_failed` — Token 已撤销。

**备注**：撤销 = 写 `revoked_at`，不删除记录；写 `token_revoked` 审计事件。

---

## 六、笔记（私有侧）`/api/notes`

### 6.1 GET `/api/notes`

**鉴权**：登录

**查询参数**：

- `limit`、`offset`：分页；
- `visibility`：可选，`private` / `public`，按可见性过滤；
- `tag_id`：可选，按标签过滤。

**响应** `200`：

```json
{
  "items": [
    {
      "id": "...",
      "title": "...",
      "content_preview": "笔记正文前 200 字...",
      "visibility": "private",
      "published_at": null,
      "created_at": "...",
      "updated_at": "...",
      "tags": [{ "id": "...", "name": "编程" }]
    }
  ],
  "total": 1
}
```

**备注**：列表不返回 `content`（正文），正文只在详情接口返回。按 `updated_at DESC` 排序。列表返回 `content_preview`：正文按 rune 截断至 200 字符，超出部分以 `…` 结尾；正文为空时返回空串。截断由后端完成，前端直接展示。


### 6.2 GET `/api/notes/:id`

**鉴权**：登录

**响应** `200`：

```json
{
  "id": "...",
  "title": "...",
  "content": "...",
  "visibility": "private",
  "published_at": null,
  "created_at": "...",
  "updated_at": "...",
  "tags": [{ "id": "...", "name": "编程" }]
}
```

**错误**：

- `404 not_found` — 笔记不存在或不属于当前用户。

### 6.3 POST `/api/notes`

**鉴权**：登录 + write

**请求**：

```json
{ "title": "...", "content": "...", "tag_ids": ["...", "..."] }
```

- `title`：必填；
- `content`：可选，默认空串；
- `tag_ids`：可选，标签 id 数组；后端校验每个 tag 属于当前用户。

**响应** `201`：同 6.2 的笔记对象。

**错误**：

- `422 validation_failed` — title 为空、tag_ids 含无效 id。

**备注**：**不接受 `visibility` 参数**，新建一律 private；写操作成功不写审计事件（笔记 CRUD 不审计）。

### 6.4 PATCH `/api/notes/:id`

**鉴权**：登录 + write

**请求**（部分更新）：

```json
{ "title": "...", "content": "...", "tag_ids": ["..."] }
```

- 只更新出现的字段；
- `tag_ids` 如出现，为**全量替换**。

**响应** `200`：同 6.2 的笔记对象。

**错误**：

- `404 not_found` — 笔记不存在或不属于当前用户；
- `422 validation_failed` — 字段校验失败。

**备注**：`updated_at` 由应用层更新。

### 6.5 DELETE `/api/notes/:id`

**鉴权**：登录 + write

**响应** `204`

**错误**：

- `404 not_found` — 笔记不存在或不属于当前用户。

### 6.6 POST `/api/notes/:id/publish`

**鉴权**：登录 + write

**请求**：无 body

**响应** `200`：同 6.2 的笔记对象，`visibility` 为 `public`，`published_at` 非空。

**错误**：

- `404 not_found` — 笔记不存在或不属于当前用户；
- `409 conflict` — 笔记已是 public。

**备注**：若 `published_at` 为 NULL，写入当前时间；否则保留首次发布时间；写 `note_published` 审计事件。

### 6.7 POST `/api/notes/:id/unpublish`

**鉴权**：登录 + write

**请求**：无 body

**响应** `200`：同 6.2 的笔记对象，`visibility` 为 `private`，`published_at` 保留不变。

**错误**：

- `404 not_found` — 笔记不存在或不属于当前用户；
- `409 conflict` — 笔记已是 private。

**备注**：写 `note_unpublished` 审计事件。

## 六点五、文件夹管理 `/api/folders`

### 6.5.1 GET `/api/folders`
**鉴权**：登录
**说明**：获取当前用户的**所有**文件夹（平铺数组，由前端组合成树）。
**响应** `200`：
{
  "items": [
    { "id": "uuid", "parent_id": null, "name": "技术", "sort_order": 0 }
  ],
  "total": 1
}

### 6.5.2 POST `/api/folders`
**鉴权**：登录 + write
**请求**：
{ "name": "新文件夹", "parent_id": "父uuid或null" }
**响应** `201`：返回创建的文件夹对象。

### 6.5.3 PATCH `/api/folders/:id`
**鉴权**：登录 + write
**请求**：
{ "name": "新名字", "parent_id": "新父uuid", "sort_order": 1 }
**备注**：支持改名和移动目录。

### 6.5.4 DELETE `/api/folders/:id`
**鉴权**：登录 + write
**响应** `204`
**备注**：删除该文件夹及其所有子文件夹，里面的笔记全部移动到未分类（`folder_id = null`）。

**2. 找到 `### 6.1 GET /api/notes` 的查询参数，增加一条：**

- `folder_id`：可选，按文件夹过滤。传具体 uuid 查该文件夹下笔记；传空字符串（`folder_id=`）查未分类（NULL）笔记；不传则查全部。

**3. 找到 `### 6.3 POST /api/notes` 和 `### 6.4 PATCH /api/notes/:id` 的请求体，在里面加上一行：**

`"folder_id": null,  // 可选，所属文件夹 id，不传或 null 表示未分类`

---

## 七、笔记（公开侧）`/api/public/notes`

### 7.1 GET `/api/public/notes`

**鉴权**：匿名

**查询参数**：`limit`、`offset`

**响应** `200`：

```json
{
  "items": [
    {
      "id": "...",
      "title": "...",
      "content_preview": "...",
      "published_at": "...",
      "updated_at": "...",
      "tags": [{ "id": "...", "name": "编程" }]
    }
  ],
  "total": 1
}
```

**备注**：只返回 `visibility = public AND published_at IS NOT NULL` 的笔记，跨用户。按 `published_at DESC` 排序。列表不返回正文。

### 7.2 GET `/api/public/notes/:id`

**鉴权**：匿名

**响应** `200`：

```json
{
  "id": "...",
  "title": "...",
  "content": "...",
  "published_at": "...",
  "updated_at": "...",
  "tags": [{ "id": "...", "name": "编程" }]
}
```

**错误**：

- `404 not_found` — 笔记不存在、非 public、或 `published_at` 为空。

---

## 八、标签 `/api/tags`

### 8.1 GET `/api/tags`

**鉴权**：登录

**响应** `200`：

```json
{
  "items": [
    { "id": "...", "name": "编程", "note_count": 5, "created_at": "..." }
  ],
  "total": 1
}
```

- `note_count`：该标签关联的笔记数（含私有）。

### 8.2 POST `/api/tags`

**鉴权**：登录 + write

**请求**：

```json
{ "name": "编程" }
```

**响应** `201`：

```json
{ "id": "...", "name": "编程", "note_count": 0, "created_at": "..." }
```

**错误**：

- `409 conflict` — 当前用户下已有同名标签（`lower(name)` 相同）；
- `422 validation_failed` — name 为空或过长。

### 8.3 DELETE `/api/tags/:id`

**鉴权**：登录 + write

**响应** `204`

**错误**：

- `404 not_found` — 标签不存在或不属于当前用户。

**备注**：关联由外键 `ON DELETE CASCADE` 自动清理。

### 8.4 GET `/api/tags/:id/notes`

**鉴权**：登录

**查询参数**：`limit`、`offset`

**响应** `200`：结构同 6.1，含 `content_preview`。


**错误**：

- `404 not_found` — 标签不存在或不属于当前用户。

---

## 九、搜索 `/api/search`

### 9.1 GET `/api/search`

**鉴权**：登录

**查询参数**：

- `q`：必填，关键词；
- `limit`、`offset`：分页，只作用于笔记结果。

**响应** `200`：

```json
{
  "notes": {
    "items": [
      {
        "id": "...",
        "title": "...",
        "content_preview": "...",
        "visibility": "private",
        "published_at": null,
        "updated_at": "...",
        "tags": [{ "id": "...", "name": "编程" }]
      }
    ],
    "total": 1
  },
  "tags": {
    "items": [{ "id": "...", "name": "编程", "note_count": 3 }],
    "total": 1
  }
}
```

**备注**：

- 笔记按 `search_text ILIKE '%q%'` 匹配，范围限当前用户；
- 标签按 `name ILIKE '%q%'` 匹配，范围限当前用户；
- 不返回正文，只返回标题与元信息。

### 9.2 GET `/api/public/search`

**鉴权**：匿名

**查询参数**：`q`、`limit`、`offset`

**响应** `200`：

```json
{
  "items": [
    {
      "id": "...",
      "title": "...",
      "content_preview": "...",
      "published_at": "...",
      "updated_at": "...",
      "tags": [{ "id": "...", "name": "编程" }]
    }
  ],
  "total": 1
}
```

**备注**：只搜 `visibility = public AND published_at IS NOT NULL` 的笔记，跨用户。**不返回标签列表**——公开页的标签只作为笔记属性出现，点标签跳转到本接口用标签名搜索。本期不提供 `/api/public/tags`。

---

## 十、作品集 `/api/portfolio`

### 10.1 GET `/api/public/portfolio`

**鉴权**：匿名

**响应** `200`：

```json
{
  "items": [
    {
      "id": "...",
      "title": "Haven",
      "description": "...",
      "sort_order": 0,
      "repos": [
        {
          "id": "...",
          "platform": "gogs",
          "repo_path": "kairo/haven",
          "url": "https://gogs.example.com/kairo/haven",
          "is_primary": true
        },
        {
          "id": "...",
          "platform": "github",
          "repo_path": "kairo/haven",
          "url": "https://github.com/kairo/haven",
          "is_primary": false
        }
      ]
    }
  ],
  "total": 1
}
```

- `url` 由后端按 `platform` + 配置的 base URL 拼接，前端直接用；
- 按 `sort_order` 升序排序。

### 10.2 POST `/api/portfolio`

**鉴权**：登录 + write

**请求**：

```json
{ "title": "Haven", "description": "...", "sort_order": 0 }
```

**响应** `201`：

```json
{ "id": "...", "title": "Haven", "description": "...", "sort_order": 0, "repos": [] }
```

**错误**：

- `422 validation_failed` — title 为空。

### 10.3 PATCH `/api/portfolio/:id`

**鉴权**：登录 + write

**请求**（部分更新）：

```json
{ "title": "...", "description": "...", "sort_order": 1 }
```

**响应** `200`：同 10.2，含当前 `repos`。

**错误**：

- `404 not_found` — 作品不存在或不属于当前用户。

### 10.4 DELETE `/api/portfolio/:id`

**鉴权**：登录 + write

**响应** `204`

**错误**：

- `404 not_found` — 作品不存在或不属于当前用户。

**备注**：关联仓库由外键 `ON DELETE CASCADE` 自动清理。

### 10.5 POST `/api/portfolio/:id/repos`

**鉴权**：登录 + write

**请求**：

```json
{ "platform": "gogs", "repo_path": "kairo/haven", "is_primary": true }
```

**响应** `201`：

```json
{ "id": "...", "platform": "gogs", "repo_path": "kairo/haven", "url": "https://gogs.example.com/kairo/haven", "is_primary": true }
```

**错误**：

- `404 not_found` — 作品不存在或不属于当前用户；
- `409 conflict` — 该作品下已有相同 `platform + repo_path`；
- `409 conflict` — 该作品已有主链接且本次 `is_primary=true`；
- `422 validation_failed` — platform 非法、repo_path 为空。

### 10.6 PATCH `/api/portfolio/:id/repos/:repoId`

**鉴权**：登录 + write

**请求**（部分更新）：

```json
{ "repo_path": "...", "is_primary": true }
```

**响应** `200`：同 10.5 的仓库对象。

**错误**：

- `404 not_found` — 作品或仓库不存在、不属于当前用户；
- `409 conflict` — 唯一性或主链接冲突。

### 10.7 DELETE `/api/portfolio/:id/repos/:repoId`

**鉴权**：登录 + write

**响应** `204`

**错误**：

- `404 not_found` — 作品或仓库不存在、不属于当前用户。

---

## 十一、其他 `/api/me`

### 11.1 GET `/api/me`

**鉴权**：匿名

**响应** `200`：

未登录：

```json
{ "anonymous": true }
```

登录：

```json
{
  "anonymous": false,
  "auth_type": "session",
  "user": { "id": "...", "username": "kairo", "totp_enabled": true }
}
```

Token 调用：

```json
{
  "anonymous": false,
  "auth_type": "token",
  "scope": "read",
  "user": { "id": "...", "username": "kairo", "totp_enabled": true }
}
```

**备注**：供前端判断登录态与权限范围，不做其他事。
