# auth — 鉴权与权限模型

> 本文件回答：谁能访问什么、鉴权分几层、会话 / 授信设备 / API Token 各自的规则、授权中间件做什么。
> 依赖：data-model.md

## 一、模型概述

Haven 的鉴权分三个独立维度，共同决定一次请求能否通过：

1. **身份**：你是谁。三种可能——未登录、登录用户（通过会话）、API Token 用户。
2. **凭证层级**：登录用户额外区分是否通过 TOTP、是否来自授信设备。
3. **资源可见性**：你能看什么。由笔记的 `visibility` 和 `user_id` 共同决定。

三个维度正交，授权中间件依次判断，任一环节失败即拒绝。

## 二、登录流程

登录分两步。第一步校验账密，第二步校验 TOTP。只有两步都通过（或该用户未启用 TOTP、或授信设备有效）才下发正式会话。

### 2.1 第一步：账密校验

1. 用户提交 `username + password`；
2. 服务端校验密码哈希，失败返回 401；
3. 若用户未启用 TOTP，直接创建正式会话，下发会话 cookie，登录完成；
4. 若用户启用了 TOTP：
    - 若请求携带的授信设备 cookie 有效（未过期、哈希匹配、属于该用户），跳过 TOTP，直接创建正式会话；
    - 否则，不创建会话，创建一条 `pending_logins` 记录，返回临时 token，要求进入第二步。

### 2.2 第二步：TOTP 校验

1. 用户提交 `temp_token + code`；
2. 服务端按 `token_hash` 查 `pending_logins`，校验未过期、属于该用户；
3. 校验 code 对 `users.totp_secret` 是否正确；
4. 校验通过：删除 `pending_logins` 记录，创建正式会话，下发会话 cookie；若第一步请求了 `trust_device`，同时创建授信设备；
5. 校验失败：返回 401，`pending_logins` 记录保留至过期（5 分钟），期间可重试。

### 2.3 TOTP 未启用

`users.totp_enabled = false` 时，登录只走第一步，不要求 TOTP。首次登录即此状态，用户在设置页绑定 TOTP 后才启用。

**关键点**：
- 正式会话只在第一步（未启用 TOTP 或授信设备有效）或第二步（TOTP 通过）成功后创建；
- `pending_logins` 记录不是会话，授权中间件不认，只能用于第二步；
- 授信设备**不免除密码**，只免除 TOTP。


## 三、会话（sessions）

**用途**：维护“已登录”状态，是最短命的凭证。

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | uuid | PK | |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | |
| `token_hash` | text | NOT NULL, UNIQUE | 会话 token 的 SHA-256 哈希，明文只存在于 cookie |
| `expires_at` | timestamptz | NOT NULL | 过期时间，默认创建后 7 天 |
| `last_used_at` | timestamptz | NOT NULL | 最后使用时间，每次请求更新 |
| `user_agent` | text | NOT NULL DEFAULT '' | 创建会话时的 UA，仅用于设置页展示 |
| `created_at` | timestamptz | NOT NULL | |

**规则**：

1. **会话 token 为随机 32 字节**，base64url 编码后下发到 cookie。数据库只存哈希，明文不落库。
2. **cookie 属性**：`HttpOnly`、`Secure`（HTTPS 下）、`SameSite=Lax`、`Domain=app.example.com`。生产环境若为 HTTP（自用局域网），`Secure` 可配为 false，但要在 `architecture.md` 里注明风险。
3. **cookie `Domain` 固定为私有域**（`app.example.com`），不设 `.example.com`。公开域（`example.com`）收不到任何 cookie，公开域的请求天然无凭证，减少 CSRF 面。详见 `frontend.md` 第二节。
4. **有效期 7 天**，不做滑动续期（避免会话无限延长）。过期后需重新登录。
5. **每次请求更新 `last_used_at`**，但不延长 `expires_at`。
6. **用户可在设置页列出自己的所有会话并单独撤销**——这是网吧环境离开后的兜底手段。
7. **撤销会话 = 删除记录**，硬删除。
8. **本表只存正式会话**。待验证的登录请求不在本表，见 3.1 节 `pending_logins`。授权中间件查询会话时，本表所有记录均视为有效会话（仍要校验 `expires_at`）。

### 3.1 pending_logins — 待验证登录

**用途**：暂存“账密已通过、TOTP 待验证”的登录请求。生命周期极短，验证完成或过期即删除。

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | uuid | PK | |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | |
| `token_hash` | text | NOT NULL, UNIQUE | 临时 token 的 SHA-256 哈希 |
| `expires_at` | timestamptz | NOT NULL | 创建后 5 分钟 |
| `created_at` | timestamptz | NOT NULL | |

**规则**：

1. 临时 token 为随机 32 字节，base64url 编码后返回给前端，数据库只存哈希。trust_device 请求位拼接在明文末尾（如 <随机串>:1），不单独落库；校验时先剥离后缀再哈希。
2. 有效期固定 5 分钟，不续期。
3. 验证成功即删除记录；过期后由定时清理任务或下次登录时顺手删除。
4. **授权中间件不认 `pending_logins`**。它只能用于 `POST /api/auth/login/totp`。
5. 不做失败计数。5 分钟内 code 错几次都允许重试，5 分钟后记录过期，需重新登录。

## 四、授信设备（trusted_devices）

**用途**：标记“这台浏览器可信”，用于跳过 TOTP。不代表登录态，不代表免密。

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | uuid | PK | |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | |
| `token_hash` | text | NOT NULL, UNIQUE | 设备 token 的 SHA-256 哈希 |
| `device_name` | text | NOT NULL DEFAULT '' | 用户可命名，如“家里台式机” |
| `expires_at` | timestamptz | NOT NULL | 默认 30 天 |
| `last_used_at` | timestamptz | NOT NULL | |
| `created_at` | timestamptz | NOT NULL | |

**规则**：

1. **授信设备 token 为随机 32 字节**，存哈希，明文只在 cookie 里。
2. **cookie 独立于会话 cookie**，名如 `haven_trusted_device`，`Domain` 与会话 cookie 一致（`app.example.com`）。
3. **有效期 30 天**，到期不自动续期。
4. **不做设备指纹**：不用 UA + IP 做绑定校验，避免网吧环境不稳定导致误判。安全性靠“token 随机 + HttpOnly + 可撤销”，不靠指纹。
5. **用户可在设置页列出所有授信设备并单独撤销**，撤销即删除记录。
6. **密码修改时，所有授信设备与所有会话一并撤销**（强制重新登录 + 重新授信）。这是安全底线：密码变了的含义是“我怀疑旧凭证泄露”。
7. **公共机器不建议授信**。授信设备有效期 30 天，登出不清除。在网吧、酒店等公共机器上登录时，不应勾选 `trust_device`；若误勾选，应通过设置页或另一台已登录设备手动撤销该授信设备。

## 五、API Token（tokens）

**用途**：供 TUI / Neovim / 脚本长期使用的凭证，与登录会话完全解耦。

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | uuid | PK | |
| `user_id` | uuid | NOT NULL, FK → users(id) ON DELETE CASCADE | |
| `name` | text | NOT NULL | 用户命名，如“TUI @ 家里”“Neovim @ 公司” |
| `token_hash` | text | NOT NULL, UNIQUE | Token 的 SHA-256 哈希 |
| `token_prefix` | text | NOT NULL | 明文前 8 位，用于设置页展示与识别，不用于鉴权 |
| `scope` | text | NOT NULL, CHECK IN ('read','read_write') | 权限档位 |
| `expires_at` | timestamptz | NULL | NULL 表示永不过期 |
| `last_used_at` | timestamptz | NULL | 从未使用时为 NULL |
| `revoked_at` | timestamptz | NULL | 非 NULL 表示已撤销 |
| `created_at` | timestamptz | NOT NULL | |

**规则**：

1. **Token 明文只在创建时返回一次**，之后无法再查看，只能看到 `token_prefix`。这是行业惯例，防止数据库泄露后 Token 被直接使用。
2. **Token 格式**：`haven_<scope>_<32字节随机串base64url>`，例如 `haven_ro_AbCd...`。前缀便于用户和日志识别，但鉴权时不解析前缀，只查哈希。
3. **Token 存 SHA-256 哈希**，不存明文。
4. **scope 两档**：
   - `read`：只能读，不能写；
   - `read_write`：读写都可以。
   没有更细的权限，也不区分“只能读某类资源”。
5. **永不过期是默认值**，但支持设置过期时间。自用场景建议 TUI / Neovim 用永不过期 + 手动撤销。
6. **撤销 = 写 `revoked_at`**，不是删除记录。保留记录便于审计追溯。已撤销的 Token 鉴权时直接拒绝。
7. **用户可在设置页列出所有 Token**，显示 `name`、`token_prefix`、`scope`、`last_used_at`、`created_at`，并提供撤销按钮。
8. **密码修改不撤销 Token**。理由：Token 是独立凭证，可能挂在自动化脚本里，强制撤销会打断工作流。用户需手动撤销。这一条与“密码修改撤销会话 / 授信设备”不同，是刻意为之。

## 六、授权中间件

所有 API 请求（除了公开接口白名单）必须经过授权中间件。中间件按以下顺序执行：

### 6.1 身份识别

身份识别只认 `sessions` 表与 `tokens` 表。`pending_logins` 记录不参与身份识别。

1. 若请求携带 `Authorization: Bearer <token>`：
   - 查 `tokens` 表，按 `token_hash` 匹配；
   - 校验未撤销（`revoked_at IS NULL`）、未过期（`expires_at IS NULL OR expires_at > now()`）；
   - 匹配成功 → 身份为 `TokenUser{user_id, scope}`；
   - 匹配失败 → 返回 401。
2. 否则若请求携带会话 cookie：
   - 查 `sessions` 表，按 `token_hash` 匹配；
   - 校验未过期；
   - 匹配成功 → 身份为 `SessionUser{user_id}`，更新 `last_used_at`；
   - 匹配失败 → 视为未登录，继续往下走。
3. 否则 → 身份为 `Anonymous`。

**优先级**：`Authorization` header 优先于 cookie。两者同时存在时以 header 为准，便于脚本调用时不受浏览器 cookie 干扰。

### 6.2 身份与权限判定

根据接口要求，中间件拒绝或放行：

- 接口要求 `anonymous_ok`：任何人可访问，但仍需计算可见性过滤（见 6.3）；
- 接口要求 `login_required`：必须是 `SessionUser` 或 `TokenUser`，`Anonymous` 返回 401；
- 接口要求 `write`：必须是 `SessionUser`，或 `scope = read_write` 的 `TokenUser`。`scope = read` 的 `TokenUser` 返回 403。
- 接口要求 `totp_verified`：仅 `SessionUser` 且会话创建时通过过 TOTP 才满足。本期除“关闭 TOTP”“修改密码”“创建 Token”这几个高危操作外，不强制要求。

### 6.3 可见性过滤条件

中间件计算出当前请求的**数据可见性条件**，注入 context，供 handler 使用：

- `Anonymous`：`WHERE visibility = 'public' AND published_at IS NOT NULL`；
- `SessionUser` / `TokenUser`：`WHERE (user_id = current_user_id) OR (visibility = 'public' AND published_at IS NOT NULL)`。

**所有读接口必须使用这个条件，不得自己拼 visibility 判断。** 这是 `conventions.md` 第四节那条禁令的具体落点。

### 6.4 归属过滤

在 6.3 基础上，所有写操作与私有读操作必须额外加 `user_id = current_user_id`。跨用户访问返回 404，不返回 403（不泄露资源存在性）。

## 七、权限矩阵

| 操作 | Anonymous | Token (read) | Token (read_write) | SessionUser |
|---|---|---|---|---|
| 浏览公开笔记列表 | ✅ | ✅ | ✅ | ✅ |
| 读公开笔记详情 | ✅ | ✅ | ✅ | ✅ |
| 读私有笔记 | ❌ 401 | ✅（自己的） | ✅（自己的） | ✅（自己的） |
| 创建 / 编辑 / 删除笔记 | ❌ | ❌ 403 | ✅ | ✅ |
| publish / 撤回笔记 | ❌ | ❌ 403 | ✅ | ✅ |
| 搜索笔记与标签 | ✅（仅公开结果） | ✅（自己 + 公开） | ✅（自己 + 公开） | ✅（自己 + 公开） |
| 创建 / 删除标签 | ❌ | ❌ 403 | ✅ | ✅ |
| 查看作品集 | ✅ | ✅ | ✅ | ✅ |
| 管理作品集 | ❌ | ❌ 403 | ✅ | ✅ |
| 创建 / 撤销 Token | ❌ | ❌ 403 | ❌ 403 | ✅（需 TOTP） |
| 查看 / 撤销授信设备 | ❌ | ❌ 403 | ❌ 403 | ✅ |
| 查看 / 撤销会话 | ❌ | ❌ 403 | ❌ 403 | ✅ |
| 绑定 TOTP（setup / verify） | ❌ | ❌ 403 | ❌ 403 | ✅ |
| 关闭 TOTP（disable） | ❌ | ❌ 403 | ❌ 403 | ✅（需当前 TOTP） |
| 修改密码 | ❌ | ❌ 403 | ❌ 403 | ✅（需原密码 + TOTP） |

**说明**：Token（包括 read_write）**不能管理凭证类资源**（Token / 授信设备 / 会话 / TOTP / 密码）。理由：Token 本身是凭证，如果它又能创建新 Token，泄露一次就等于永久后门。凭证管理只允许通过 Web 会话操作。

## 八、密码与 TOTP 存储

### 8.1 密码

- 哈希算法：**bcrypt**，cost = 12。理由：Go 标准库生态成熟、实现简单、抗暴力破解足够；自用场景不需要 argon2id 的极致参数调优。
- 字段：`users.password_hash text NOT NULL`。
- 不存明文、不存可逆加密。

### 8.2 TOTP secret

- `users.totp_secret text NULL`（未绑定时为 NULL）。
- 本期**明文存储**，依赖数据库本身的访问控制。理由：自用、单机部署，数据库访问只有本机；加密存储需要额外的密钥管理，收益低于成本。
- **风险标注**：如果将来 Haven 部署到多租户或托管环境，必须改为加密存储（用 KMS 或应用层密钥）。这一条写在这里，防止以后忘记。

### 8.3 密码修改后的级联

修改密码成功后，在同一个事务内：

1. 删除该用户所有 `sessions` 记录；
2. 删除该用户所有 `trusted_devices` 记录；
3. **不删除** `tokens` 记录（见第五节规则 8）；
4. 写一条审计事件（见 `audit.md`）。

## 九、users 表字段（补充 data-model.md）

`users` 表的完整字段如下，`data-model.md` 第九节待补部分以此为准：

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | uuid | PRIMARY KEY | `gen_random_uuid()` | |
| `username` | text | NOT NULL（唯一性见规则 3） | — | 登录名，本期只有一条记录 |
| `password_hash` | text | NOT NULL | — | bcrypt 哈希 |
| `totp_secret` | text | NULL | NULL | TOTP 密钥，未绑定为 NULL |
| `totp_enabled` | boolean | NOT NULL | `false` | 是否已启用 TOTP |
| `created_at` | timestamptz | NOT NULL | `now()` | |
| `updated_at` | timestamptz | NOT NULL | `now()` | |

**规则**：

1. 本期只有一条 `users` 记录，由部署时的初始化脚本创建（见 `architecture.md`）。
2. **不提供注册接口**。第二个账号如需创建，只能通过命令行脚本或直接操作数据库，不在 API 层暴露。
3. username 不区分大小写唯一（用 lower(username) 唯一索引），避免 Admin / admin 混淆。
