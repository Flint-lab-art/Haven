# 记账模块

## 1. 设计目标

记一笔钱要回答三个问题：**钱从哪出、花在哪、还剩多少**。

因此模型有三根支柱：

| 支柱 | 解决的问题 | 落点 |
| --- | --- | --- |
| 账户 | 不知道钱从哪出，算不出「这张卡还剩多少」 | `ledger_accounts` |
| 两级分类 | 只有粗分类，「钱花在哪」答不精确 | `ledger_categories` |
| 转账类型 | 转账被记成支出，虚增收支 | `ledger_entries.type = 'transfer'` |

月度预算（`ledger_budgets`）建在账户与分类之上，回答「这个月还能花多少」。

**非目标**（当前版本不做）：快捷指令 / 文本解析 / 别名、复式记账、多币种、多用户、周期账单自动生成、转账手续费。

## 2. 表结构

```text
ledger.ledger_accounts   账户：name / type / initial_balance_cents / archived
ledger.ledger_categories 分类：id(smallint) / parent_id / name / kind / enabled
ledger.ledger_entries    流水：type / amount_cents / category_id / account_id / to_account_id
ledger.ledger_budgets    预算：month / category_id / amount_cents
```

### 账户类型

| type | 含义 | 余额语义 |
| --- | --- | --- |
| `cash` | 现金 | 手上还剩多少 |
| `bank` | 储蓄卡 / 借记卡 | 卡里还有多少 |
| `credit` | 信用卡 / 花呗 / 白条 | 负数表示欠款 |
| `ewallet` | 微信 / 支付宝 | 钱包余额 |

**余额不落库**，一律由「期初余额 + 流水累计」实时算出，避免余额字段与流水打架。

### 流水三种形态

数据库用 `ledger_entries_shape_check` 兜底，绕过 Service 也写不进脏数据：

| type | category_id | account_id | to_account_id | 计入收支 |
| --- | --- | --- | --- | --- |
| `expense` | 必填 | 必填 | 必须为空 | ✅ |
| `income` | 必填 | 必填 | 必须为空 | ✅ |
| `transfer` | 必须为空 | 必填（转出） | 必填（转入，且不等于转出） | ❌ |

**转账不计入任何收支统计**，只影响账户余额。这是整个模型最关键的一条。

## 3. 分类体系

一级 7 个支出 + 1 个收入；二级共 44 条。完整清单见 [ledger-categories-draft.md](ledger-categories-draft.md)。

| 一级 | 二级数量 |
| --- | --- |
| 餐饮 | 6 |
| 购物 | 5 |
| 交通 | 6 |
| 居家 | 6 |
| 娱乐 | 6（含订阅、Token） |
| 医疗 | 6 |
| 其他 | 5（含人情往来、还款） |
| 收入 | 6 |

### 统计时归到一级

流水可以记在一级或二级上，统计一律用：

```sql
COALESCE(parent_id, id)
```

这样「记在一级」与「记在二级」的支出会落到同一个一级分类下，预算不会漏算。

### 分类不物理删除

历史流水还引用着分类，物理删会断外键。停用分类用 `enabled = false`，菜单里不再出现，历史流水照常显示。

## 4. 预算

- **只绑一级支出分类**。二级预算会让「直接记一级」的流水无处归属，总预算对不上。
- 同一个月同一分类只有一条（`unique (user_id, category_id, month)`）。
- **总预算 = 各预算项之和**；`spentCents` 按上面的 `COALESCE` 口径算。

### 周视图的预算折算

预算按月设，但移动端统计有「周」粒度，展示时按天数折算：

```
本周预算 = Σ(月预算 × 本周落在该月的天数 ÷ 该月总天数)
```

跨月的那一周（比如 11/25 ~ 12/1）按各月占的天数加权，所以各周加起来不会超过月预算。
界面上标注「按月折算」，避免用户看到数字变小时困惑。

季度与年**不展示预算**：预算是按月设的，季/年的折算规则（是否要年度预算）尚未定义。

### 区间统计接口

`GET /api/ledger/stats?from=&to=` 接受任意区间，**后端不认「周 / 月 / 季 / 年」这些语义**。
四种粒度由前端算好 `from` / `to` 后调用：

- 加新粒度（自定义区间）不用改后端；
- 不会出现「本月」按 A 定义、「最近 30 天」按 B 定义这种边界打架。

返回按天补零的 `buckets`；月/季/年需要的「按月」由前端合并，后端只维护一套分桶。

⚠️ 区间是**左闭右开**，且后端用 `to.isEqual(...)` 而不是 `equals`
比较边界——`OffsetDateTime.equals` 还比较偏移量，前端传 UTC、后端构造 +08:00
时同一瞬间也不相等，会导致多出一格（一周变 8 天、一季度变 4 个月）。

## 5. 端点

### 账户

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/ledger/accounts` | 列表，含实时余额 |
| POST | `/api/ledger/accounts` | 新建 |
| PUT | `/api/ledger/accounts/{id}` | 修改 / 归档 |
| DELETE | `/api/ledger/accounts/{id}` | 删除；**有流水时返回 409**，只能归档 |

### 分类

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/ledger/categories` | 两级分类树（只含 enabled） |

### 流水

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/ledger/entries` | 新建 |
| GET | `/api/ledger/entries` | 列表（`type` / `category_id` / `account_id` / `from` / `to` / 分页） |
| GET | `/api/ledger/entries/{id}` | 详情 |
| PATCH | `/api/ledger/entries/{id}` | 修改 |
| DELETE | `/api/ledger/entries/{id}` | 删除 |

按 `account_id` 过滤时**转账两侧都算**（转出或转入任一匹配）。

### 统计与预算

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/ledger/summary?month=YYYY-MM` | 月度收支 + 按一级分类拆分 + 转账笔数 |
| GET | `/api/ledger/trend?days=7` | 最近 N 天走势（≤90） |
| GET | `/api/ledger/budgets?month=YYYY-MM` | 当月预算 + 已花 |
| PUT | `/api/ledger/budgets` | 设置某项预算 |
| DELETE | `/api/ledger/budgets/{categoryId}?month=YYYY-MM` | 删除某项预算 |

响应字段：

```json
{
  "month": "2026-11",
  "total_expense_cents": 125000,
  "total_income_cents": 800000,
  "total_count": 12,
  "transfer_count": 3,
  "expense_by_category": [{ "category_id": 1, "category_name": "餐饮", "spent_cents": 45000 }],
  "income_by_category": []
}
```

## 6. 前端约定

- **金额一律整数分**（`amount_cents`），格式化在前端完成（`formatYuan`）。
- 分类下拉用两级：先选一级，再选二级；二级可以留空（表示只知道大类）。
- 录入对话框按 `type` 切换字段可见性：转账时隐藏分类，显示「转出 / 转入」两个账户。
- 修改流水从支出改成转账时，必须显式清空 `category_id`（后端已用 `LambdaUpdateWrapper.set(..., null)` 处理）。

## 7. 历史沿革

- V4~V13：单表流水 + 字符串分类 + 批次幂等 + 别名表（服务快捷指令）。
- **V17**：引入账户、两级分类、预算；重建 `ledger_entries`；删除 `ledger_batches` / `ledger_aliases`（快捷记账延后）。
- **V18**：分类种子数据。

旧数据在 V17 直接丢弃：旧模型没有账户维度，迁过来等于编造数据。
