-- V6__ledger_income_categories.sql
-- 收入分类与默认别名
--
-- 原 V4 的 category 约束只允许支出大类；收入条目无法获得有意义的分类。
-- 这里保持「单层 category」不变，仅把收入大类补进白名单：
--   工资 / 奖金 / 报销 / 退款 / 红包 / 其他收入
-- 方向仍由 type（expense / income）表达。

-- ─────────────────────────────────────────────
-- 1. 放宽条目分类约束
-- ─────────────────────────────────────────────
alter table ledger_entries
    drop constraint if exists ledger_entries_category_check;

alter table ledger_entries
    add constraint ledger_entries_category_check
    check (category in (
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '未分类',
        '工资', '奖金', '报销', '退款', '红包', '其他收入'
    ));

-- ─────────────────────────────────────────────
-- 2. 放宽别名分类约束
-- ─────────────────────────────────────────────
alter table ledger_aliases
    drop constraint if exists ledger_aliases_category_check;

alter table ledger_aliases
    add constraint ledger_aliases_category_check
    check (category in (
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '未分类',
        '工资', '奖金', '报销', '退款', '红包', '其他收入'
    ));

-- ─────────────────────────────────────────────
-- 3. 收入默认别名
-- ─────────────────────────────────────────────
insert into ledger_aliases(user_id, alias, category)
select u.id, v.alias, v.category
from users u
cross join (values
    -- 工资
    ('工资',    '工资'), ('薪水',    '工资'), ('薪资',    '工资'),
    ('月薪',    '工资'), ('发工资',  '工资'),

    -- 奖金
    ('奖金',    '奖金'), ('年终奖',  '奖金'), ('提成',    '奖金'),
    ('绩效',    '奖金'),

    -- 报销
    ('报销',    '报销'), ('报账',    '报销'),

    -- 退款
    ('退款',    '退款'), ('退钱',    '退款'), ('退费',    '退款'),
    ('退回',    '退款'),

    -- 红包
    ('红包',    '红包'), ('压岁钱',  '红包'), ('礼金',    '红包'),
    ('收礼',    '红包'),

    -- 其他收入
    ('利息',    '其他收入'), ('分红',  '其他收入'), ('理财收益','其他收入'),
    ('兼职',    '其他收入'), ('外快',  '其他收入'), ('卖二手',  '其他收入')
) as v(alias, category)
where u.username = 'kairo'
on conflict (user_id, alias) do update set category = excluded.category;