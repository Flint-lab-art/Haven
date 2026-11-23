-- V21__ledger_account_icon.sql
--
-- 账户加图标：存图标 key（如 `icbc` / `alipay`），不存文件路径。
-- 路径会随部署变化，key 是稳定的领域标识；前端按 key 找对应的 SVG。

alter table ledger.ledger_accounts
    add column if not exists icon text not null default '';
