-- V20__ledger_rebuild_entries.sql
--
-- 破坏式重建记账流水表。
--
-- 背景：V17 重建过一次 ledger_entries，但当时直接丢掉了旧数据。
-- 这次是要把备份的流水导回来，所以需要：
--   1. 把三张旧表彻底删掉（别名 / 批次 / 流水）；
--   2. 按当前结构重建 ledger_entries；
--   3. 让导入脚本能直接往里插。
--
-- **不含账户、分类、预算**：这三张表 V17 已经建好，重建会把用户设的
-- 账户期初余额与预算一起清掉。除非确实要一起重来，否则不要动它们。
--
-- 依赖顺序：先删引用别人的（entries → batches），再删被引用的。
-- ledger_aliases 不引用任何表，先删无妨。

drop table if exists ledger.ledger_entries;
drop table if exists ledger.ledger_batches;
drop table if exists ledger.ledger_aliases;

-- ─────────────────────────────────────────────
-- 重建流水表（结构与 V17 一致）
-- ─────────────────────────────────────────────
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
