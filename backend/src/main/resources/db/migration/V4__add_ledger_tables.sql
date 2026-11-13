-- V4__ledger_tables.sql
-- 记账模块：批次、条目、别名

-- ─────────────────────────────────────────────
-- 1. ledger_batches：批次表，支撑 batch_id 幂等
-- ─────────────────────────────────────────────
create table ledger_batches (
    user_id    uuid        not null,
    batch_id   varchar(64) not null,
    raw_text   text,
    created_at timestamptz not null default now(),
    primary key (user_id, batch_id)
);

-- ─────────────────────────────────────────────
-- 2. ledger_entries：记账条目
-- ─────────────────────────────────────────────
create table ledger_entries (
    id           uuid        primary key default gen_random_uuid(),
    user_id      uuid        not null,
    type         varchar(16) not null
                 check (type in ('expense', 'income')),
    amount_cents bigint      not null
                 check (amount_cents > 0),
    category     varchar(32) not null
                 check (category in ('餐饮','购物','交通','居家','娱乐','医疗','未分类')),
    note         text,
    occurred_at  timestamptz not null,
    batch_id     varchar(64) not null,
    created_at   timestamptz not null default now()
);

-- 月度/日度汇总：按 occurred_at 区间聚合
create index idx_ledger_entries_user_time
    on ledger_entries (user_id, occurred_at desc);

-- 按分类筛选：GET /entries?category=餐饮
create index idx_ledger_entries_user_cat
    on ledger_entries (user_id, category);

-- 幂等重放：按 batch_id 查已写入条目
create index idx_ledger_entries_user_batch
    on ledger_entries (user_id, batch_id);

-- "最近 3 笔"：按录入时间倒序，不受 occurred_at 影响
create index idx_ledger_entries_user_created
    on ledger_entries (user_id, created_at desc);

-- ─────────────────────────────────────────────
-- 3. ledger_aliases：别名翻译表
-- ─────────────────────────────────────────────
create table ledger_aliases (
    user_id  uuid        not null,
    alias    varchar(64) not null,
    category varchar(32) not null
             check (category in ('餐饮','购物','交通','居家','娱乐','医疗','未分类')),
    primary key (user_id, alias)
);