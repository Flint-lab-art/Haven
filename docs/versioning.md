# 版本号规则

## 1. 基本格式

`MAJOR.MINOR.PATCH`，但**升级门槛与标准 SemVer 不同**。

| 位 | +1 的条件 | 例子 |
| --- | --- | --- |
| **MAJOR** | 新增一个**全新的功能领域**（判据见下方三要素） | v1 → v2：加入记账 |
| **MINOR** | 不加大领域，但有大动作，或新增若干小功能点，或修复较大的问题 | 代码风格重构、API 契约从 Map 改成 DTO、认证模型改造 |
| **PATCH** | 修小 bug、改文案、补小优化 | 修某个页面报错、修正错别字 |

**关键区别**：标准 SemVer 里"加功能"就该升 MINOR，本项目要求**只有多出一整个业务领域才算 MAJOR**。

## 2. MAJOR 的判据：三要素齐备

> 新东西需要 **独立的顶级导航入口** + **自己的数据表** + **自己的 CRUD 流程**，三者齐备才算 MAJOR。

| 要素 | 含义 | 反例 |
| --- | --- | --- |
| 独立顶级导航入口 | 侧栏/顶栏多出一项，路由表里有独立的顶级路径段 | 「笔记里的导出按钮」不是入口 |
| 自己的数据表 | 迁移脚本里新增专属表（不是给已有表加字段） | 「给 notes 加 pinned 字段」不算 |
| 自己的 CRUD 流程 | 有独立的列表 / 详情 / 新增 / 修改 / 删除端点 | 「只读统计接口」不算 |

三者**缺一不可**。举几个边界判断：

| 改动 | 导航 | 数据表 | CRUD | 判定 |
| --- | :-: | :-: | :-: | --- |
| 加入记账（v1→v2） | ✅ | ✅ | ✅ | **MAJOR** |
| 加入作品集 | ✅ | ✅ | ✅ | **MAJOR** |
| 加入 Issue | ✅ | ✅ | ✅ | **MAJOR** |
| 笔记加「置顶」 | ❌ | ❌ | ❌ | PATCH / MINOR |
| 笔记加「导出为 PDF」 | ❌ | ❌ | ❌ | MINOR |
| 新增「模板库」页面（有表、有增删改查） | ✅ | ✅ | ✅ | **MAJOR** |
| 新增仪表盘统计接口 | ❌ | ❌ | ⚠️ 只读 | 不算（缺导航与 CRUD） |
| 给记账加「预算」功能（新表 + 新页面） | ✅ | ✅ | ✅ | **MAJOR** |

### 现有模块的三要素核对

| 模块 | 导航 | 数据表 | CRUD | 级别 |
| --- | :-: | :-: | :-: | --- |
| 笔记 | `/notes` | `notes` / `note_versions` / `folders` / `tags` | 16 + 4 + 4 个端点 | MAJOR 级 |
| 记账 | `/ledger` | `ledger_*` | 15 个端点 | MAJOR 级 |
| 作品集 | `/portfolio` | `portfolio_*` | 9 个端点 | MAJOR 级 |
| Issue | `/issues` | `issues` / `issue_status_events` | 5 个端点 | MAJOR 级 |

这四项都属于"领域级"，理论上都可以各自撑起一个 MAJOR。

## 3. 和标准 SemVer 的差异

| 场景 | 标准 SemVer | 本项目 |
| --- | --- | --- |
| 新增一个 API 端点 | MINOR | **PATCH**（除非带来整套新能力） |
| 新增一个业务领域 | MINOR | **MAJOR** |
| 大范围重构但不改行为 | 不升版本 | **MINOR** |
| 修 bug | PATCH | PATCH（一致） |
| 破坏性 API 变更 | MAJOR | 视情况，通常是 **MINOR** |

最后一行要特别说明：本项目是**单用户自托管应用**，前后端一起发布、一起部署，没有外部消费者，
所以 API 破坏性变更不需要为"兼容性承诺"升 MAJOR。升不升位看的是**改动规模与性质**，不是兼容性。

## 4. 历史版本

| 版本 | 实际改动 | 为什么是这个位 |
| --- | --- | --- |
| 1.0.x | 笔记 + 作品集 + Issue + 搜索的基础能力 | 起点 |
| 1.1.x | 受信设备 API、Issue 修复、CI 调整 | 没有新领域 → MINOR |
| **2.0.0** | **加入记账模块** | 三要素齐备 → MAJOR |
| **2.1.0**（当前） | DTO 化、Clock 注入、审计接入、测试库隔离、记账服务拆分、脚本体系、文档 | 大规模内部整改，无新领域 → MINOR |

## 5. 当前状态

| 位置 | 版本 |
| --- | --- |
| `backend/pom.xml` | `2.1.0` |
| `frontend/package.json` | `2.1.0` |
| 产物名 | `haven-2.1.0.jar` |

## 6. 补充规则（避免滥用）

三条容易出问题的场景，规则如下：

| 场景 | 处理 | 理由 |
| --- | --- | --- |
| 同一次发布既有新功能又有重构 | 按**最高位**规则（有 MINOR 级的就升 MINOR） | 版本号描述整次发布，不描述单个 commit |
| 只有依赖升级、无行为变化 | PATCH，或干脆不升 | 用 git 记录即可 |
| 回滚已发布的版本 | **不要复用版本号**，回滚后发新的 PATCH | 否则日志与用户无法区分跑的是哪份代码 |

### PATCH 的滥用边界

"新增一个 API 端点算 PATCH"这个口子要收紧：

> 一次发布里如果包含**多个新功能点**，合并为 MINOR；PATCH 只用于「纯修复、无新增能力」。

否则 `2.1.1` → `2.1.47` 之间能塞几十个功能，版本号就失去信噪比了。

## 7. 版本号只有一个来源

### 唯一来源：根目录 `VERSION`

```text
VERSION            ← 唯一真相，改版本只改这里（或下面的一行命令）
   │
   │  scripts/version.sh sync
   ├──────────────▶ backend/pom.xml   <properties><revision>2.1.0</revision>
   └──────────────▶ frontend/package.json   "version": "2.1.0"
```

### 为什么还有两个地方写着版本号

这是构建工具的限制，不是设计选择：

| 工具 | 限制 |
| --- | --- |
| Maven | `${revision}` 必须在 pom 里有一个默认值，没法从外部文件读 |
| npm / pnpm | `package.json` 的 `version` 不支持引用外部文件 |

所以两处仍保留字面量，但**唯一的人工写入入口是 `scripts/version.sh`**。

### 怎么用

```bash
./scripts/version.sh                 # 查看三处状态（VERSION / pom / package.json）
./scripts/version.sh set 2.2.0       # 改版本：写 VERSION 并同步到两处
./scripts/version.sh sync            # 把 VERSION 重新同步到两处（修正漂移）
./scripts/version.sh check           # 只校验，不一致则非 0 退出
```

### 自动兜底

`build.sh` 与 `test.sh` 在开始处都会执行 `version.sh check`：

```bash
$ ./scripts/build.sh backend
[version] VERSION（唯一来源）      2.1.0
[version] backend/pom.xml <revision>     2.1.0  ✓
[version] frontend/package.json          9.9.9  ✗ 需同步
[build] 版本号不一致，先执行 ./scripts/version.sh sync
```

有人手改了 `pom.xml` 或 `package.json` 忘记同步时，**构建和测试会直接失败**，不会打出错误版本的包。

### pom.xml 的写法

```xml
<properties>
    <revision>2.1.0</revision>
</properties>
...
<artifactId>backend</artifactId>
<version>${revision}</version>
```

`finalName` 是 `haven-${project.version}`，所以产物名、`app.version`（`@project.version@` 注入）、
`/api/health` 返回的版本号**全部自动跟随 `VERSION`**。

### 发布流程

```bash
./scripts/version.sh set 2.2.0     # 改版本（一处）
./scripts/test.sh all              # 验证
./scripts/build.sh all             # 产物 haven-2.2.0.jar
curl -s http://127.0.0.1:8080/api/health   # {"status":"ok","version":"2.2.0"}
```

### 前端版本号的实际用途

只用于 `vite.config.ts` 的 `__APP_VERSION__` 注入，在设置页显示。它**不参与构建产物命名**，
但两个数字不一致会让"我们发布的是哪个版本"变得含糊，因此必须与后端保持同一版本号。
