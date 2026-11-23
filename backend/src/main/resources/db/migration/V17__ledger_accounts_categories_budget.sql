-- V17__ledger_accounts_categories_budget.sql
--
-- 记账重构：账户 / 两级分类 / 月度预算。
--
-- 三个结构性问题：
--   1. 没有账户维度，算不出「这张卡还剩多少」；
--   2. 转账被记成支出，工资卡→微信会虚增支出；
--   3. 只有单层分类，「钱花在哪」答不精确。
--
-- 旧数据直接丢弃：只有零星测试流水，且旧模型没有账户维度，迁过来也是脏数据。
-- 便捷记账（批次 / 别名 / 文本解析）整体延后，相关的 batch 表与别名表一并删除。

-- ─────────────────────────────────────────────
-- 1. 账户
-- ─────────────────────────────────────────────
create table ledger.ledger_accounts
(
    id                    uuid        primary key default gen_random_uuid(),
    user_id               uuid        not null references users (id) on delete cascade,
    name                  text        not null,
    -- cash 现金 / bank 储蓄卡 / credit 信用卡与花呗 / ewallet 微信支付宝
    type                  varchar(16) not null
        check (type in ('cash', 'bank', 'credit', 'ewallet')),
    -- 期初余额（分）。credit 类表示期初欠款，余额为负数
    initial_balance_cents bigint      not null default 0,
    -- 排序与归档：归档账户不再出现在录入下拉里，但历史流水仍引用
    sort_order            integer     not null default 0,
    archived              boolean     not null default false,
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now()
);

create unique index idx_ledger_accounts_user_name
    on ledger.ledger_accounts (user_id, lower(name));

-- ─────────────────────────────────────────────
-- 2. 两级分类
-- ─────────────────────────────────────────────
create table ledger.ledger_categories
(
    -- smallint 便于手工控制 id 段：一级 1~99，二级从 101 起
    id        smallint primary key,
    -- 一级分类为 null，二级指向所属一级
    parent_id smallint references ledger.ledger_categories (id) on delete restrict,
    name      text     not null,
    -- expense / income / transfer
    kind      varchar(16) not null
        check (kind in ('expense', 'income', 'transfer')),
    -- 排序；同一父下唯一不强制，前端按它稳定排序
    sort_order smallint not null default 0,
    -- 软删除：历史流水还引用着，物理删会断
    enabled   boolean  not null default true,
    -- 约束：一级不能有 parent，二级不能是 transfer
    constraint ledger_categories_parent_check check (
        (parent_id is null) or (kind <> 'transfer')
    )
);

create index idx_ledger_categories_parent
    on ledger.ledger_categories (parent_id, sort_order);

-- ─────────────────────────────────────────────
-- 3. 重建流水表
-- ─────────────────────────────────────────────
-- 旧表没有账户维度、分类是字符串，迁移过来等于重新编造数据，直接丢。
drop table if exists ledger.ledger_entries;

create table ledger.ledger_entries
(
    id              uuid        primary key default gen_random_uuid(),
    user_id         uuid        not null references users (id) on delete cascade,
    type            varchar(16) not null
        check (type in ('expense', 'income', 'transfer')),
    amount_cents    bigint      not null
        check (amount_cents > 0),
    -- expense / income 必填；transfer 必须为空
    category_id     smallint    references ledger.ledger_categories (id) on delete restrict,
    -- expense / income 的资金账户；transfer 时为转出账户
    account_id      uuid        references ledger.ledger_accounts (id) on delete restrict,
    -- 仅 transfer 使用：转入账户
    to_account_id   uuid        references ledger.ledger_accounts (id) on delete restrict,
    note            text,
    occurred_at     timestamptz not null,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    -- 三种类型的字段组合必须自洽：
    --   支出/收入：有 category_id 与 account_id，没有 to_account_id
    --   转账：有 account_id 与 to_account_id 且两者不同，没有 category_id
    constraint ledger_entries_shape_check check (
        (type in ('expense', 'income')
            and category_id is not null
            and account_id is not null
            and to_account_id is null)
        or
        (type = 'transfer'
            and category_id is null
            and account_id is not null
            and to_account_id is not null
            and to_account_id <> account_id)
    )
);

create index idx_ledger_entries_user_time
    on ledger.ledger_entries (user_id, occurred_at desc);

create index idx_ledger_entries_user_cat
    on ledger.ledger_entries (user_id, category_id);

create index idx_ledger_entries_user_account
    on ledger.ledger_entries (user_id, account_id);

create index idx_ledger_entries_user_transfer_to
    on ledger.ledger_entries (user_id, to_account_id)
    where to_account_id is not null;

create index idx_ledger_entries_user_created
    on ledger.ledger_entries (user_id, created_at desc);

-- ─────────────────────────────────────────────
-- 4. 月度预算
-- ─────────────────────────────────────────────
-- 预算只绑一级分类：二级流水在统计时 join + coalesce(parent_id, id) 归到一级，
-- 这样一级流水与二级流水都能落进同一个预算，总预算 = 各预算项之和才不会漏算。
create table ledger.ledger_budgets
(
    id            uuid     primary key default gen_random_uuid(),
    user_id       uuid     not null references users (id) on delete cascade,
    category_id   smallint not null references ledger.ledger_categories (id) on delete restrict,
    -- YYYY-MM；同一个月同一一级分类只有一条
    month         char(7)  not null check (month ~ '^\d{4}-\d{2}$'),
    amount_cents  bigint   not null check (amount_cents > 0),
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now(),

    unique (user_id, category_id, month)
);

create index idx_ledger_budgets_user_month
    on ledger.ledger_budgets (user_id, month);

-- ─────────────────────────────────────────────
-- 5. 删除延后的便捷记账表
-- ─────────────────────────────────────────────
-- 批次表与别名表只服务「一行文本 = 一笔记录」的快捷记账，当前改为纯 UI 录入，用不上了。
drop table if exists ledger.ledger_aliases;
drop table if exists ledger.ledger_batches;
