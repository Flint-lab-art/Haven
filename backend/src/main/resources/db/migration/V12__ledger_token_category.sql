-- V12__ledger_token_category.sql
-- 支出新增「Token」分类
--
-- 场景：AI 服务订阅（OpenAI / Claude / Cursor 等）按 token 用量计费，
-- 归到「购物」「娱乐」都不贴切，统计时也会被混进实物消费。
-- 典型用法：`openai 20` → openai 是别名 → 分类落在 Token。
--
-- 只放宽约束，不迁移历史数据：旧记录仍保留原分类。

-- ─────────────────────────────────────────────
-- 1. 放宽条目分类约束
-- ─────────────────────────────────────────────
alter table ledger_entries
    drop constraint if exists ledger_entries_category_check;

alter table ledger_entries
    add constraint ledger_entries_category_check
    check (category in (
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '还款', 'Token', '未分类',
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
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '还款', 'Token', '未分类',
        '工资', '奖金', '报销', '退款', '红包', '其他收入'
    ));

-- ─────────────────────────────────────────────
-- 3. Token 默认别名
-- ─────────────────────────────────────────────
-- 与 V5/V10 一致：只为开发账号补齐，幂等（on conflict do nothing）。
-- 别名是「第一个词」，所以 `claude 20` 这类写法能直接落到 Token 分类。
insert into ledger_aliases(user_id, alias, category)
select u.id, v.alias, v.category
from users u
cross join (values
    ('token',        'Token'),
    ('tokens',       'Token'),
    ('api',          'Token'),
    ('openai',       'Token'),
    ('chatgpt',      'Token'),
    ('gpt',          'Token'),
    ('claude',       'Token'),
    ('anthropic',    'Token'),
    ('gemini',       'Token'),
    ('cursor',       'Token'),
    ('copilot',      'Token'),
    ('deepseek',     'Token'),
    ('kimi',         'Token'),
    ('通义',         'Token'),
    ('文心',         'Token'),
    ('智谱',         'Token'),
    ('ai订阅',       'Token'),
    ('ai',           'Token'),
    ('大模型',       'Token'),
    ('算力',         'Token')
) as v(alias, category)
where u.username = 'kairo'
on conflict (user_id, alias) do nothing;
