-- V10__ledger_repayment_category.sql
-- 支出新增「还款」分类
--
-- 场景：信用卡 / 花呗 / 房贷等还款属于支出，但归到「居家」「购物」都不合适，
-- 统计时也被混进日常消费。这里把它作为独立的支出大类加入白名单。
--
-- 只放宽约束，不迁移历史数据：旧的还款记录仍保留原分类。

-- ─────────────────────────────────────────────
-- 1. 放宽条目分类约束
-- ─────────────────────────────────────────────
alter table ledger_entries
    drop constraint if exists ledger_entries_category_check;

alter table ledger_entries
    add constraint ledger_entries_category_check
    check (category in (
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '还款', '未分类',
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
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '还款', '未分类',
        '工资', '奖金', '报销', '退款', '红包', '其他收入'
    ));

-- ─────────────────────────────────────────────
-- 3. 还款默认别名
-- ─────────────────────────────────────────────
-- 与 V5 的写法一致：只为已有用户补齐，幂等（on conflict do nothing）。
insert into ledger_aliases(user_id, alias, category)
select u.id, v.alias, v.category
from users u
-- 与 V5 一致：默认别名只补给开发账号，避免在别人的库里凭空多出别名
cross join (values
    ('还款',     '还款'),
    ('还信用卡', '还款'),
    ('信用卡还款', '还款'),
    ('还花呗',   '还款'),
    ('花呗还款', '还款'),
    ('还白条',   '还款'),
    ('还房贷',   '还款'),
    ('房贷',     '还款'),
    ('还车贷',   '还款'),
    ('车贷',     '还款'),
    ('还借呗',   '还款'),
    ('借呗还款', '还款'),
    ('还贷',     '还款')
) as v(alias, category)
where u.username = 'kairo'
on conflict (user_id, alias) do nothing;
