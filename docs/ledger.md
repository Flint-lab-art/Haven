# 记账模块

## 1. 设计目标

记账的主力入口是 **iOS 快捷指令**：说一句「午饭 12」，一次请求直接落库。
因此核心要求是 **一行文本 = 一笔记录**，不需要选分类、选日期、算金额单位。

## 2. 类结构

```text
LedgerController
   ↓
LedgerServiceImpl          编排：事务、权限、参数收敛
   ├── LedgerTextParser    语法：金额、日期       （只依赖 Clock）
   ├── LedgerClassifier    语义：分类、方向、备注 （无依赖）
   ├── LedgerStatsCalculator 计算：总额、排行、走势（无依赖）
   └── Mapper              ledgers / entries / aliases
```

拆分原因：解析与计算是**纯函数**，可以脱离 Spring 与数据库做单元测试。
`LedgerServiceImpl` 从 848 行降到 483 行。

## 3. 输入格式

```
[日期] 分类 [备注…] 金额
```

示例：

```text
午饭 12
午饭 12.5
午饭 32元
午饭 ¥32
午饭 二十五块
2026-11-16 午饭 20
11月16 午饭 12
16号 打车 25
昨天 打车 25
午饭 食堂 12
```

### 金额

| 写法 | 结果（分） |
| --- | ---: |
| `12` | 1200 |
| `12.5` | 1250 |
| `32元` / `32块` / `32圆` | 3200 |
| `¥32` / `￥32` | 3200 |
| `二十五块` | 2500 |
| `十二点五元` | 1250 |
| `一万` | 1000000 |

规则：金额必须出现在**行末**；正则只接受最多两位小数，`12.345` 不会被识别为金额。

### 日期

| 写法 | 解释 |
| --- | --- |
| `2026-11-16` / `2026年11月16日` | 完整日期 |
| `11月16` / `11-16` / `11/16` | 当年 |
| `16号` / `16日` | 当月 |
| `今天` / `昨天` / `前天` | 相对当前 |
| 不写 | 服务端当前时间 |

非法日期（如 `2026-02-30`）不会被当作日期，留在原文里。

## 4. 分类体系

单层分类，方向由 `type` 表达：

### 支出

```
餐饮 / 购物 / 交通 / 居家 / 娱乐 / 医疗 / 还款 / 未分类
```

### 收入

```
工资 / 奖金 / 报销 / 退款 / 红包 / 其他收入
```

常量定义：`ledger/entity/LedgerCategories`（`EXPENSE` / `INCOME` / `ALL` / `ALL_SET` / `INCOME_SET`），
与数据库 CHECK 约束由测试保证一致。

### 分类判定顺序

```
1. 别名命中   → 用别名值作为分类，原词并入备注
2. 内置分类   → 直接用，剩余作为备注
3. 都没命中   → 归入「未分类」，原词并入备注
```

### 方向判定

```
分类属于收入类        → income
备注里出现收入关键词  → income（工资/奖金/报销/退款/红包/利息/分红…）
其他                  → expense
```

关键词表在 `LedgerTextParser.INCOME_KEYWORDS`。

### 别名学习

用户手工把一条「张三 借钱」改成分类型「餐饮」后，系统会自动把 `张三` 学成别名，
下次输入「张三 30」直接命中。学习条件：

- 备注不为空
- 分类不是「未分类」
- 备注首个词不是内置分类
- 词长 ≤ 64

## 5. 幂等

```http
POST /api/ledger/entries/batch
{ "batchId": "0f7c…", "rawText": "...", "items": [...] }
```

- `ledger_batches` 主键是 `(user_id, batch_id)`
- 用 `insertIfAbsent` 写入；返回 0 表示批次已存在 → 直接回放已有结果（`created=false`）
- 条目在同一事务里写入，批次与条目要么都成功要么都失败

所以网络抖动重试不会重复记账。iOS 快捷指令里用「UUID」动作生成 `batchId`。

## 6. 端点

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/ledger/quick` | 只解析不落库 |
| POST | `/api/ledger/entries/quick` | 解析并写入（快捷指令用） |
| POST | `/api/ledger/entries/batch` | 确认写入（`/batches` 为别名） |
| GET | `/api/ledger/batches/{batchId}` | 批次及条目 |
| GET | `/api/ledger/entries` | 列表（`from`/`to`/`category`/`type`/分页） |
| GET / PATCH / DELETE | `/api/ledger/entries/{id}` | 详情 / 修改 / 删除 |
| GET | `/api/ledger/recent` | 最近录入（默认 3） |
| GET | `/api/ledger/summary?month=YYYY-MM` | 月度汇总 |
| GET | `/api/ledger/trend?days=7` | 最近 N 天（≤90） |
| GET | `/api/ledger/categories` | 分类清单 |
| GET / POST / DELETE | `/api/ledger/aliases[/{alias}]` | 别名管理 |

### 响应示例

```json
{
  "created": true,
  "batchId": "0f7c…",
  "rawText": "午饭 12",
  "createdAt": "2026-11-17T10:30:00+08:00",
  "items": [
    { "id": "…", "type": "expense", "amountCents": 1200, "category": "餐饮", "note": "午饭", "occurredAt": "…", "batchId": "0f7c…", "createdAt": "…" }
  ],
  "total": 1
}
```

（前端收到的 JSON 是 `snake_case`，这里为可读性写成 camelCase —— 实际以 `snake_case` 为准。）

## 7. 统计

`LedgerStatsCalculator` 输入「一批条目 + 日期列表 + 时区」，输出：

```java
record WindowStats(
    long totalExpenseCents,
    long totalIncomeCents,
    long totalCount,
    List<LedgerCategoryRank> categoryRanking,      // 金额降序，同名按分类名升序
    List<LedgerCategoryRank> incomeCategoryRanking,
    List<LedgerDailyPoint> daily)                  // 按 dates 补零
```

边界处理：

| 情况 | 行为 |
| --- | --- |
| `occurredAt` 为 null | 计入总额，不进按天序列 |
| `amountCents` 为 null | 按 0 处理（不抛 NPE） |
| 条目发生在窗口外 | 计入总额，不进按天序列 |

## 8. 「还款」分类

V10 新增。属于**支出**，用于信用卡 / 花呗 / 房贷等还款。

默认别名（仅为开发账号写入）：

```
还款 / 还信用卡 / 信用卡还款 / 还花呗 / 花呗还款 / 还白条
还房贷 / 房贷 / 还车贷 / 车贷 / 还借呗 / 借呗还款 / 还贷
```

> **当前「还款」计入总支出**。如果希望它不计入日常消费统计，
> 需要在 `LedgerStatsCalculator` 里把该分类从 `totalExpenseCents` 里剔除或单列。

## 9. 前端约定

| 文件 | 职责 |
| --- | --- |
| `api/ledger.ts` | 类型与请求，`LedgerCategory` 联合类型必须与后端常量一致 |
| `utils/ledger.ts` | `EXPENSE_CATEGORIES` / `INCOME_CATEGORIES` / 色阶 / 金额格式化 |
| `views/private/LedgerView.vue` | 页面 |

新增分类时**三处都要改**，否则类型检查或显示会出错：

1. `LedgerCategories.EXPENSE` 或 `INCOME`
2. 数据库 CHECK 约束（新迁移）
3. 前端 `api/ledger.ts` 联合类型 + `utils/ledger.ts` 数组与色阶

最后一项有测试守着：`frontend/src/__tests__/ledger.test.ts` 断言了分类数组与长度。

## 10. 金额展示

存储是分，展示在**前端**完成：

```ts
formatYuan(1200)       // "¥12"    整数不显示小数
formatYuan(1234)       // "¥12.34"
formatYuan(128600)     // "¥1,286"
```

后端不负责格式化——它只保证数值精确。
