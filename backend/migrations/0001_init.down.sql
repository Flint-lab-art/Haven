-- 0001_init down
--
-- 与 0001_init.up.sql 对称：按建表的逆序删除。
-- 保留 pg_trgm 扩展（可能被同库其他对象使用），不在此删除。

DROP TABLE IF EXISTS portfolio_repos;
DROP TABLE IF EXISTS note_tags;
DROP TABLE IF EXISTS portfolio_items;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS notes;
DROP TABLE IF EXISTS audit_events;
DROP TABLE IF EXISTS tokens;
DROP TABLE IF EXISTS trusted_devices;
DROP TABLE IF EXISTS pending_logins;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;
