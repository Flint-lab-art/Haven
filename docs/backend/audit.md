# audit — 审计日志

> 本文件回答：审计记录哪些事件、表结构、写入时机、写入失败时怎么处理。
> 依赖：data-model.md、auth.md

## 一、定位与范围

审计日志的用途是**事后追溯**：谁、什么时候、对什么做了什么。它不是业务日志，不记录请求细节、不记录笔记内容、不用于排查性能问题。

本期范围限定为**安全与状态事件**。笔记 CRUD 等高频业务事件**不记录**——理由见 `conventions.md` 第四节。

## 二、audit_events 表

**用途**：存储审计事件，只追加，不修改，不删除。

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | uuid | PRIMARY KEY, DEFAULT `gen_random_uuid()` | |
| `actor_user_id` | uuid | NULL, FK → users(id) ON DELETE SET NULL | 事件发起者；未登录事件（如登录失败但用户名不存在）为 NULL |
| `actor_username` | text | NOT NULL DEFAULT '' | 事件发起者用户名快照；用户被删除后仍保留 |
| `event_type` | text | NOT NULL, CHECK (见第三节清单) | 事件类型 |
| `target_type` | text | NULL, CHECK (见第三节清单) | 被操作对象类型，无对象时为 NULL |
| `target_id` | uuid | NULL | 被操作对象 id，无对象时为 NULL |
| `metadata` | jsonb | NOT NULL DEFAULT `'{}'` | 事件附加信息，结构由 event_type 决定 |
| `ip` | text | NOT NULL DEFAULT '' | 请求来源 IP，未取到时为空串 |
| `user_agent` | text | NOT NULL DEFAULT '' | 请求 UA |
| `created_at` | timestamptz | NOT NULL DEFAULT `now()` | |

**索引**：

```sql
CREATE INDEX idx_audit_events_created_at ON audit_events (created_at DESC);
CREATE INDEX idx_audit_events_event_type ON audit_events (event_type, created_at DESC);
CREATE INDEX idx_audit_events_actor ON audit_events (actor_user_id, created_at DESC)
  WHERE actor_user_id IS NOT NULL;
```

**规则**：

1. **只追加**：不提供 UPDATE / DELETE 接口，不在应用层修改记录。
2. **`actor_user_id` 可为 NULL**：登录失败但用户名不存在时，不知道是谁，记为 NULL；`actor_username` 存用户提交的用户名原文，便于排查暴力破解。
3. **`actor_user_id` 与 `actor_username` 并存**：前者是外键（用户被删后置 NULL），后者是快照（永不为 NULL）。这样用户被删除后，历史审计记录仍能显示“谁”做的。
4. **`metadata` 是 jsonb**：不同 event_type 有不同的附加字段，不固定 schema。每个 event_type 的 metadata 结构在本文件第三节定义。
5. **不记录笔记内容、密码、Token 明文、TOTP secret**。metadata 中只记 id、名字、状态变化等元信息。

## 三、事件类型清单

本期记录以下事件。**新增事件类型必须同步更新本节和 CHECK 约束**。

| event_type | target_type | 触发时机 | metadata 结构 |
|---|---|---|---|
| `login_success` | `null` | 登录成功（含授信设备跳过 TOTP） | `{"via":"password+totp"}` 或 `{"via":"password+trusted_device"}` |
| `login_failure` | `null` | 密码错误、TOTP 错误、用户名不存在 | `{"reason":"bad_password"\|"bad_totp"\|"no_such_user"}` |
| `logout` | `null` | 主动登出 | `{}` |
| `totp_bound` | `user` | 首次绑定 TOTP 成功 | `{}` |
| `totp_disabled` | `user` | 关闭 TOTP | `{}` |
| `password_changed` | `user` | 修改密码成功 | `{}` |
| `session_revoked` | `session` | 手动撤销会话 | `{"session_created_at":"..."}` |
| `trusted_device_added` | `trusted_device` | 授信设备添加 | `{"device_name":"..."}` |
| `trusted_device_revoked` | `trusted_device` | 授信设备撤销 | `{"device_name":"..."}` |
| `token_created` | `token` | API Token 创建 | `{"name":"...","scope":"read"\|"read_write","token_prefix":"..."}` |
| `token_revoked` | `token` | API Token 撤销 | `{"name":"...","token_prefix":"..."}` |
| `note_published` | `note` | 笔记 private → public | `{"title":"..."}` |
| `note_unpublished` | `note` | 笔记 public → private | `{"title":"..."}` |

**说明**：

- `target_type` 取值为 `null`（字符串字面量，非 SQL NULL）或 `user` / `session` / `trusted_device` / `token` / `note`。CHECK 约束里用 `'null'` 字符串表示“无对象”，避免和 SQL NULL 混淆。
- `login_failure` 的 `actor_user_id` 通常为 NULL（尤其 `no_such_user`），但密码错误时如果能确定用户，可以为该用户 id。这一条在实现时决定，本文件不强制。
- **笔记 CRUD（创建、编辑、删除）不在清单内**。`note_published` / `note_unpublished` 只记录“公开状态变化”这一状态事件，不记录内容变化。

## 四、写入时机

审计写入发生在**业务操作成功之后、响应返回之前**。顺序：

1. 执行业务操作（如登录校验、Token 创建）；
2. 业务操作成功；
3. 写审计事件；
4. 返回响应。

**审计写入不在业务事务内**（除非业务操作本身就是数据库事务且审计失败必须回滚，见第五节）。理由：审计表挂了不应该让登录之类的操作失败。

## 五、写入失败的处理

### 5.1 业务成功、审计写入失败

**本期决策：业务操作不回滚，审计失败只打错误日志。**

理由：审计是辅助记录，不是业务前置条件。审计表挂了（磁盘满、表被误删）不应该让用户登录不进去。错误日志中记录完整的审计事件内容，便于事后人工补录。

代价：极端情况下（审计表挂了 + 同时发生安全事件），会丢失审计记录。自用场景接受此代价。

### 5.2 业务失败、需要记录失败事件（如登录失败）

**本期决策：同样只打错误日志，不影响登录接口的响应。**

登录失败本身就是业务结果，审计表挂了不该让“登录失败”变成“服务错误”。响应照常返回“密码错误”，审计写入失败只打日志。

**例外**：如果将来要做“连续登录失败 N 次锁定账号”，锁定逻辑依赖审计表或独立的失败计数器，那时审计写入失败会影响锁定判断。本期不做锁定，所以无此问题。**如后期加锁定，需重新评估本节。**

## 六、查询与展示

本期**不提供审计日志的 Web 查询界面**。理由：自用、单人，需要排查时直接 `psql` 查表即可，做界面收益低。

`audit_events` 表结构本身就是查询入口，索引已覆盖常见查询（按时间倒序、按事件类型、按用户）。

如果后期需要界面，另开文档，不在本期范围。
