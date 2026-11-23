-- V19__ledger_category_icons.sql
--
-- 分类图标：两级都配 emoji，跟版本走（dev / prod 自动一致）。
--
-- 选型：iOS 与 Chrome 都能渲染的常用 emoji（Unicode 13 以内）。
-- 完整清单与设计说明见 docs/ledger-category-icons.md。

alter table ledger.ledger_categories
    add column if not exists icon text not null default '';

-- ── 一级 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🍜' where id = 1; -- 餐饮
update ledger.ledger_categories set icon = '🛍️' where id = 2; -- 购物
update ledger.ledger_categories set icon = '🚇' where id = 3; -- 交通
update ledger.ledger_categories set icon = '🏠' where id = 4; -- 居家
update ledger.ledger_categories set icon = '🎬' where id = 5; -- 娱乐
update ledger.ledger_categories set icon = '🏥' where id = 6; -- 医疗
update ledger.ledger_categories set icon = '🗂️' where id = 7; -- 其他
update ledger.ledger_categories set icon = '💰' where id = 8; -- 收入

-- ── 餐饮 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🥐' where id = 101; -- 早餐
update ledger.ledger_categories set icon = '🍚' where id = 102; -- 午餐
update ledger.ledger_categories set icon = '🍲' where id = 103; -- 晚餐
update ledger.ledger_categories set icon = '🧁' where id = 104; -- 零食饮料
update ledger.ledger_categories set icon = '🛵' where id = 105; -- 外卖
update ledger.ledger_categories set icon = '🍽️' where id = 106; -- 其他餐饮

-- ── 购物 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🧻' where id = 201; -- 日用品
update ledger.ledger_categories set icon = '👕' where id = 202; -- 服饰鞋包
update ledger.ledger_categories set icon = '💻' where id = 203; -- 数码家电
update ledger.ledger_categories set icon = '📚' where id = 204; -- 图书文具
update ledger.ledger_categories set icon = '🎁' where id = 205; -- 其他购物

-- ── 交通 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🚌' where id = 301; -- 公交地铁
update ledger.ledger_categories set icon = '🚕' where id = 302; -- 打车
update ledger.ledger_categories set icon = '⛽' where id = 303; -- 加油充电
update ledger.ledger_categories set icon = '🅿️' where id = 304; -- 停车过路
update ledger.ledger_categories set icon = '✈️' where id = 305; -- 火车飞机
update ledger.ledger_categories set icon = '🧭' where id = 306; -- 其他交通

-- ── 居家 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🔑' where id = 401; -- 房租
update ledger.ledger_categories set icon = '💡' where id = 402; -- 水电燃气
update ledger.ledger_categories set icon = '🏢' where id = 403; -- 物业
update ledger.ledger_categories set icon = '🔧' where id = 404; -- 家政维修
update ledger.ledger_categories set icon = '🛋️' where id = 405; -- 家具家装
update ledger.ledger_categories set icon = '🧺' where id = 406; -- 其他居家

-- ── 娱乐 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🔄' where id = 501; -- 订阅
update ledger.ledger_categories set icon = '🎮' where id = 502; -- 游戏
update ledger.ledger_categories set icon = '🎟️' where id = 503; -- 影音门票
update ledger.ledger_categories set icon = '🧳' where id = 504; -- 旅行
update ledger.ledger_categories set icon = '🤖' where id = 505; -- Token
update ledger.ledger_categories set icon = '🎉' where id = 506; -- 其他娱乐

-- ── 医疗 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🩺' where id = 601; -- 门诊
update ledger.ledger_categories set icon = '💊' where id = 602; -- 药品
update ledger.ledger_categories set icon = '🧪' where id = 603; -- 体检
update ledger.ledger_categories set icon = '🦷' where id = 604; -- 牙科
update ledger.ledger_categories set icon = '🌿' where id = 605; -- 保健
update ledger.ledger_categories set icon = '🩹' where id = 606; -- 其他医疗

-- ── 其他 ───────────────────────────────────────
update ledger.ledger_categories set icon = '🤝' where id = 701; -- 人情往来
update ledger.ledger_categories set icon = '💳' where id = 702; -- 还款
update ledger.ledger_categories set icon = '🚨' where id = 703; -- 罚款缴纳
update ledger.ledger_categories set icon = '❤️' where id = 704; -- 捐赠
update ledger.ledger_categories set icon = '📦' where id = 705; -- 其他支出

-- ── 收入 ───────────────────────────────────────
update ledger.ledger_categories set icon = '💵' where id = 801; -- 工资
update ledger.ledger_categories set icon = '🏆' where id = 802; -- 奖金
update ledger.ledger_categories set icon = '🧾' where id = 803; -- 报销
update ledger.ledger_categories set icon = '↩️' where id = 804; -- 退款
update ledger.ledger_categories set icon = '🧧' where id = 805; -- 红包
update ledger.ledger_categories set icon = '🪙' where id = 806; -- 其他收入
