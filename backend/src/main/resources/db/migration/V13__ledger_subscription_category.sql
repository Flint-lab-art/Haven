-- V13__ledger_subscription_category.sql
-- 支出新增「订阅」分类
--
-- 场景：iCloud、Apple Music、视频/音乐会员这类**自动续费**的固定支出。
-- 它们现在散落在「娱乐」里，和一次性消费（电影票、游戏、旅游）混在一起，
-- 导致「每月固定花掉多少」这个最该被看见的数字反而看不出来。
--
-- 与「Token」的分工：
-- - Token：按用量计费的 AI 服务账单
-- - 订阅：按月/年自动续费的服务（含 Apple 系与国内会员）
--
-- 只放宽约束，不迁移历史数据：旧的订阅记录仍保留原分类。

-- ─────────────────────────────────────────────
-- 1. 放宽条目分类约束
-- ─────────────────────────────────────────────
alter table ledger_entries
    drop constraint if exists ledger_entries_category_check;

alter table ledger_entries
    add constraint ledger_entries_category_check
    check (category in (
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '还款', '订阅', 'Token', '未分类',
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
        '餐饮', '购物', '交通', '居家', '娱乐', '医疗', '还款', '订阅', 'Token', '未分类',
        '工资', '奖金', '报销', '退款', '红包', '其他收入'
    ));

-- ─────────────────────────────────────────────
-- 3. 修正 V12 遗留的别名指向
-- ─────────────────────────────────────────────
-- 「ai订阅」在 V12 时指向 Token，现在有了更准确的分类，改指「订阅」。
-- 用 update 而非 delete+insert：已存在的数据不该因为别名改指向而受影响。
update ledger_aliases
set category = '订阅'
where alias in ('ai订阅', 'ai会员')
  and category = 'Token';

-- ─────────────────────────────────────────────
-- 4. 订阅默认别名
-- ─────────────────────────────────────────────
-- 与 V5/V10/V12 一致：只为开发账号补齐，幂等（on conflict do nothing）。
--
-- 注意不要占用 V5 已用的「会员」（那里归「娱乐」，指单次会员充值）；
-- 这里用更明确的「年费」「订阅」这类词。
--
-- ⚠ 别名只匹配**第一个空格前的词**（见 LedgerClassifier.classify），
-- 所以别名不能含空格：'apple music' 永远不会被命中，必须写成 'applemusic'。
-- 用户输入 `apple music 11` 时，第一个词是 apple，需要单独为 apple 建别名，
-- 但 apple 也可能指硬件，故不默认提供。
insert into ledger_aliases(user_id, alias, category)
select u.id, v.alias, v.category
from users u
cross join (values
    -- Apple 系
    ('icloud',       '订阅'),
    ('iCloud',       '订阅'),
    ('云空间',       '订阅'),
    ('applemusic',   '订阅'),
    ('music',        '订阅'),
    ('appletv',      '订阅'),
    ('arcade',       '订阅'),
    ('fitness',      '订阅'),
    ('appleone',     '订阅'),
    ('applecare',    '订阅'),
    ('苹果订阅',     '订阅'),

    -- 流媒体
    ('netflix',      '订阅'),
    ('奈飞',         '订阅'),
    ('youtube',      '订阅'),
    ('spotify',      '订阅'),
    ('disney',       '订阅'),
    ('hbo',          '订阅'),
    ('prime',        '订阅'),

    -- 国内会员
    ('爱奇艺',       '订阅'),
    ('腾讯视频',     '订阅'),
    ('优酷',         '订阅'),
    ('芒果tv',       '订阅'),
    ('b站',          '订阅'),
    ('哔哩哔哩',     '订阅'),
    ('网易云',       '订阅'),
    ('qq音乐',       '订阅'),
    ('酷狗',         '订阅'),
    ('喜马拉雅',     '订阅'),
    ('keep',         '订阅'),

    -- 通用
    ('续费',         '订阅'),
    ('年费',         '订阅'),
    ('月费',         '订阅'),
    ('自动续费',     '订阅')
) as v(alias, category)
where u.username = 'kairo'
on conflict (user_id, alias) do nothing;
