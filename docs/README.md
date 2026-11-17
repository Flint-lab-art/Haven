# Haven 文档

本目录是 Haven 的**权威设计文档**。`README.md` 与各子项目的 `README.md` 偏「怎么跑起来」，这里讲「为什么这么设计、边界在哪、改的时候要注意什么」。

## 阅读顺序

| 文档 | 适合谁 | 内容 |
| --- | --- | --- |
| [architecture.md](architecture.md) | 所有人 | 模块划分、分层约定、请求生命周期、关键决策 |
| [api-conventions.md](api-conventions.md) | 前后端 | 请求/响应契约、命名、分页、错误码、权限声明 |
| [auth.md](auth.md) | 后端、运维 | 双通道认证、TOTP、授权级别、审计、安全清单 |
| [data-model.md](data-model.md) | 后端、DBA | 表结构、约束、索引、迁移规则、金额与时间约定 |
| [ledger.md](ledger.md) | 记账相关开发 | 快捷输入解析规则、分类体系、金额精度、幂等 |
| [testing.md](testing.md) | 所有人 | 测试策略、隔离方式、写测试的套路、常见坑 |
| [conventions.md](conventions.md) | 所有人 | 代码风格、提交前检查、禁止事项 |
| [versioning.md](versioning.md) | 所有人 | 版本号规则（与标准 SemVer 不同，务必先读） |
| [backend/implementation.md](backend/implementation.md) | 后端 | 基础设施组件、上传、查询、幂等、配置分层 |
| [frontend/implementation.md](frontend/implementation.md) | 前端 | 启动时序、路由、API 层、编辑器、常见坑 |

## 日常命令

```bash
./scripts/run.sh                 # 本地启动（只需跑后端，前端产物已复制进 static/）
./scripts/build.sh all           # 清空 static → 构建前端并复制 → 打包 jar
./scripts/build.sh frontend      # 只构建前端并复制到 static/
./scripts/build.sh backend       # 只打包 jar（保留现有 static）
./scripts/test.sh all            # 前后端都测
./scripts/test.sh backend        # spotless + checkstyle + 测试
./scripts/test.sh frontend       # vue-tsc + vitest

./scripts/version.sh              # 查看版本号三处状态（来源：根目录 VERSION）
./scripts/version.sh set 2.2.0    # 改版本并同步到 pom.xml / package.json
```

**本地开发只需要跑后端**：前端 `dist/` 会被复制到 `backend/src/main/resources/static/`，
后端同源托管，不需要单独起 Vite。

## 项目定位

Haven 是一个**单用户、自托管**的个人知识中台：笔记 + 记账 + 作品集 + Issue。

这个定位决定了很多设计取舍，后文会反复引用：

- **不需要多租户**：所有数据按 `user_id` 隔离，但没有租户级配置、计费、配额。
- **不需要多币种**：记账只有人民币，金额统一以「分」为单位存整数。
- **强依赖单实例**：Sa-Token 会话在内存里，登录失败计数也在内存里。多实例部署前必须先把这两处换成共享存储。
- **前后端同源部署**：后端从 `classpath:/static/` 托管前端，非 API 路径回退 `index.html`。

## 最近一轮整理做了什么

这个仓库经历过一次系统性的规范整改，文档里多处会提到"改造后"的结论。主要变化：

| 主题 | 改造前 | 改造后 | 详见 |
| --- | --- | --- | --- |
| API 契约 | 269 处 `Map<String,Object>` | 0（仅剩 2 处注释说明），全部具名 record | [api-conventions.md](api-conventions.md) |
| 时间来源 | 43 处裸 `OffsetDateTime.now()` | 0（仅注释提及），16 个类注入 `Clock` | [conventions.md](conventions.md) |
| 金额 | `bigint` 存分（本来就对） | 补了 8 个约束测试 | [data-model.md](data-model.md) |
| 记账服务 | 848 行单类 | 拆分解析 / 分类 / 统计 / 编排 | [ledger.md](ledger.md) |
| 测试库 | 直连开发库 `dev_db` | 隔离 schema 或 Testcontainers | [testing.md](testing.md) |
| 审计 | 表存在但从未写入 | 12 个事件类型、13 个接入点 | [auth.md](auth.md) |
| 授权 | 按 HTTP 方法判断只读 Token | 端点声明 `@RequireAccess` | [auth.md](auth.md) |

> 如果你发现文档与代码不一致，**以代码为准并修正文档**——文档漂移比没有文档更糟。
