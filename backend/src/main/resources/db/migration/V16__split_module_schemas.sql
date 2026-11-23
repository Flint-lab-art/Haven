-- 按模块拆分 schema：业务表不再全部平铺在 public。
--
--   public  跨模块公共表（用户与认证）        users / tokens / sa_token / pending_totp /
--                                            trusted_devices / audit_events / login_logs
--   note    笔记模块                          notes / folders / tags / note_tags / note_versions
--   issue   Issue 模块                        issues / issue_status_events
--   ledger  记账模块                          ledger_entries / ledger_batches / ledger_aliases
--
-- 外键跨 schema 由 PostgreSQL 原生支持，note/issue/ledger 各表到 users 的外键无需重建。
-- 索引与约束随表移动（表的从属对象属于表，不独立指定 schema），sa_token 的序列留在 public。
--
-- 注意：不改写 V1~V15，空库依然先建在 public 再由本迁移搬家，保证已部署实例校验和不变。

CREATE SCHEMA IF NOT EXISTS note;
CREATE SCHEMA IF NOT EXISTS issue;
CREATE SCHEMA IF NOT EXISTS ledger;

ALTER TABLE notes SET SCHEMA note;
ALTER TABLE folders SET SCHEMA note;
ALTER TABLE tags SET SCHEMA note;
ALTER TABLE note_tags SET SCHEMA note;
ALTER TABLE note_versions SET SCHEMA note;

ALTER TABLE issues SET SCHEMA issue;
ALTER TABLE issue_status_events SET SCHEMA issue;

ALTER TABLE ledger_entries SET SCHEMA ledger;
ALTER TABLE ledger_batches SET SCHEMA ledger;
ALTER TABLE ledger_aliases SET SCHEMA ledger;
