# 认证与授权

## 1. 两条身份通道

```
Authorization: Bearer haven_ro_xxx   → API Token（脚本 / iOS 快捷指令）
Cookie: havenToken=xxx               → Sa-Token 会话（浏览器）
```

两者最终都写进同一个 request attribute（`auth_userId` / `auth_scope` / `auth_type`），所以 Controller 只看到"当前用户是谁"，不关心凭证来源。

### Token 格式

```
haven_ro_<64 位十六进制>   # 只读
haven_rw_<64 位十六进制>   # 读写
```

库里**只存 SHA-256 哈希**与展示前缀（`token_prefix`），明文只在创建时返回一次。

### 会话 Cookie

```yaml
sa-token:
  cookie:
    http-only: true      # JS 读不到
    secure: true         # 生产要求 HTTPS；dev profile 覆盖为 false
    same-site: Lax
    path: /
```

**之前这里是空的**，意味着 Cookie 可以被 XSS 直接读走。这个配置必须保留。

## 2. 登录流程

```
POST /api/auth/login { username, password, trustDevice? }
  │
  ├─ 失败 → 记录 login_failure 审计 + 失败计数 +1
  │          超限 → 429
  │
  ├─ 未启用 TOTP，或当前设备已授信 → 直接建会话
  │
  └─ 启用 TOTP 且设备未授信
       ├─ 写 pending_totp（只存 token 哈希，5 分钟有效）
       └─ 返回 { user, totpRequired: true, tempToken }

POST /api/auth/login/totp { tempToken, code }
  │
  ├─ 校验失败 → 计数 +1；达到上限则作废临时令牌
  ├─ 校验通过 → 删除临时记录 → 建会话
  └─ trustDevice=true → 写授信设备 Cookie（30 天）
```

### 登录入口为什么要分两层

`AuthServiceImpl.loginPrecheck` 只做**数据库内的校验**（`@Transactional(readOnly=true)`），
`AuthSessionOpener.login` 负责**事务外的副作用**（`StpUtil.login`）。

如果混在一个 `@Transactional` 方法里，事务回滚时用户已经被"登录"了，
或者反过来——数据提交了但会话没建成。

### 失败限流

| 项 | 默认 | 配置 |
| --- | ---: | --- |
| 密码失败次数 | 5 次 / 15 分钟 | `haven.auth.login-max-attempts` / `login-window-minutes` |
| 动态码失败次数 | 5 次 / 同一临时令牌 | `haven.auth.totp-max-attempts` |

计数按账号隔离（`login:user:<username>` / `login-totp:<userId>`），成功后清零。

> **当前是单实例内存计数**。多实例部署时有效上限会变成「实例数 × 上限」，
> 需要换成 Redis 等共享存储。

## 3. 授权级别

```java
public enum RequiredAccess {
    READ,          // 有身份即可
    WRITE,         // 需要 read_write Token 或会话
    SESSION,       // 仅浏览器会话（API Token 403）
    SESSION_TOTP;  // 会话 + 已过动态码
}
```

### 为什么不用"看 HTTP 方法"

老规则：只有 `GET/HEAD/OPTIONS` 之外的方法才对只读 Token 报 403。

漏洞：如果某个 GET 接口会写数据（同步、清理、导出），只读 Token 就能越权。
代码里曾经真的出现过——`GET /api/tags` 会物理删除没有引用的标签。

现在规则变成：**注解优先，方法兜底**。

```java
@RequireAccess(RequiredAccess.WRITE)   // 显式声明，即使方法是 GET
@GetMapping("/reindex")
```

### 各端点的级别

| 端点 | 级别 |
| --- | --- |
| `/api/me` | READ（路径在可选认证列表里，无凭证按匿名返回） |
| `/api/sessions/**` | SESSION |
| `/api/trusted-devices/**` | SESSION |
| `/api/tokens/**` | SESSION_TOTP |
| `/api/auth/totp/setup`、`verify`、`disable` | SESSION |
| `/api/auth/password` | SESSION_TOTP |
| 其余 `/api/**` | 按方法：GET→READ，其他→WRITE |

## 4. TOTP

- 算法：RFC 6238，30 秒步长，6 位数字，允许 ±1 步（共 90 秒窗口）
- 密钥：Base32，服务端生成
- 校验：常量时间比较（`MessageDigest.isEqual`），非法 Base32 返回 `false` 而不是抛异常

### 绑定流程的安全约束

`setup` 生成 secret 但**不落库**，`verify` 时才绑定。`verify` 只接受动态码，
secret 由服务端在 setup 时生成并返回给用户——不接受客户端随便传一个 secret，
否则会话被劫持的人可以绑定自己已知的密钥。

三个 TOTP 端点都要求浏览器会话（`SESSION`），API Token 一律 403。

## 5. 改密

```
POST /api/auth/password { oldPassword, newPassword, totpCode? }
```

要求 `SESSION_TOTP`，且 OLD 密码必须正确（启用 TOTP 时还要当前动态码）。

成功后**一次性失效**：

| 凭据 | 处理 |
| --- | --- |
| 授信设备 | `revokeAll` |
| API Token | `revokeAllForUser`（写 `revoked_at`） |
| Sa-Token 会话 | `logout` + `kickout`（在事务提交后） |

最后一步放在 `AuthSessionOpener.changePassword` 里，先提交数据库再踢会话。

## 6. 审计

`audit_events` 表先前存在但从未写入。现在由 `audit/AuditRecorder` 统一记录：

| 事件 | 位置 |
| --- | --- |
| `login_failure` | `AuthServiceImpl.loginPrecheck` |
| `login_success` | `AuthSessionOpener.login` / `loginTotp` |
| `totp_bound` / `totp_disabled` | `AuthServiceImpl` |
| `password_changed` | `AuthServiceImpl.changePassword` |
| `token_created` / `token_revoked` | `ApiTokenServiceImpl` |
| `trusted_device_added` / `_revoked` | `TrustedDeviceServiceImpl` |
| `session_revoked` | `SessionServiceImpl` |
| `note_published` / `note_unpublished` | `NotesServiceImpl` |

### 写入策略

**尽力而为**：审计失败只打 `warn` 日志，不阻断业务。

```java
try {
    auditEventsMapper.insert(event);
} catch (RuntimeException e) {
    log.warn("写入审计事件失败, type={}, actor={}", type.value(), actorUserId, e);
}
```

### 绝对不能写进去的东西

密码、密码哈希、Token 明文、TOTP secret、完整请求体。

## 7. 安全清单（改动时逐项确认）

- [ ] 新增端点是否声明了正确的 `@RequireAccess`
- [ ] 按 ID 访问资源的接口是否校验了 `user_id` 归属（不存在与无权限都返回 404）
- [ ] 新增写操作是否加了 `@Transactional`
- [ ] 查询是否加了 `@Transactional(readOnly = true)`
- [ ] 敏感操作（改密、Token、TOTP）是否要求 `SESSION` 或 `SESSION_TOTP`
- [ ] 凭据相关逻辑是否有对应的审计事件
- [ ] 日志里是否可能带出密码 / Token / 正文
- [ ] 新增公开接口是否考虑限流

## 8. 常见误判

| 看起来像问题 | 实际结论 |
| --- | --- |
| `sa_token` 表存在但没被使用 | 确实是"死资产"，当前用内存存储；接入 `sa-token-jdbc` 或删除表 |
| Token 的 `scope` 只有 `read` / `read_write` | 够用；细粒度权限等真有需求再加 |
| `/api/public/**` 完全匿名 | 是设计；匿名用户看公开笔记/作品集 |
| 上传文件匿名可读 | 靠随机文件名保密；需要严格私密时改成鉴权代理 |
