-- V11__ledger_user_foreign_keys.sql
--
-- 记账三表补上指向 users 的外键。
--
-- V4 建表时只写了 `user_id uuid not null`，没有 REFERENCES。
-- 后果：删除用户（或建错账号再删）时这三张表的数据不会被级联清理，
-- 留下永久的孤儿记录；而这些表承载的是全部记账历史，数据量会持续增长。
--
-- 其余业务表（notes / folders / tags / portfolio / issues 等）都已是
-- ON DELETE CASCADE，这里把记账模块补齐，保持一致的约束语义。

-- 先清理历史孤儿，否则 ADD CONSTRAINT 会失败。
-- 只删除父记录已不存在的行；有主人的数据一行不动。
delete from ledger_aliases a
where not exists (select 1 from users u where u.id = a.user_id);

delete from ledger_entries e
where not exists (select 1 from users u where u.id = e.user_id);

delete from ledger_batches b
where not exists (select 1 from users u where u.id = b.user_id);

-- 1. 批次归属用户：删用户时级联清理
alter table ledger_batches
    add constraint ledger_batches_user_id_fkey
        foreign key (user_id) references users (id) on delete cascade;

-- 2. 明细归属用户：删用户时级联清理（先于批次外键添加，保证引用目标已存在）
alter table ledger_entries
    add constraint ledger_entries_user_id_fkey
        foreign key (user_id) references users (id) on delete cascade;

-- 3. 明细必须属于一个真实存在的批次，保证 batch 追溯不会指向空。
--    目前业务只增不删批次，这条约束不改变现有行为；
--    将来若实现「删除整批」，CASCADE 会自动带走明细，语义也正确。
alter table ledger_entries
    add constraint ledger_entries_batch_fkey
        foreign key (user_id, batch_id) references ledger_batches (user_id, batch_id) on delete cascade;

-- 4. 记账别名归属用户
alter table ledger_aliases
    add constraint ledger_aliases_user_id_fkey
        foreign key (user_id) references users (id) on delete cascade;
